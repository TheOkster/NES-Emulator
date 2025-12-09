`timescale 1ns / 1ps
`default_nettype none
`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../data/X`"
`endif  /* ! SYNTHESIS */

module ppu (
        input wire clk,
        input wire rst,
        input wire [7:0] cpu_dout,
        input wire [15:0] cpu_addr, // from what i'm seeing, in the hardware it's only 3 bits?
        output logic [7:0] cpu_din,
        output logic cpu_din_valid,
        output logic [23:0] pixel, // 8 : 8 : 8 for now, might change to be 5 : 6 : 5?
        input wire cpu_rw,
        input wire is_cart_vertical,
        input wire ppu_clk_trig,
        output logic [7:0] pixel_x, // 0 to 255
        output logic [7:0] pixel_y,  // 0 to 239
        output logic pixel_valid,
        output logic [7:0] patt_table_x,
        output logic [7:0] patt_table_y,
        output logic [23:0] patt_table_pix,
        output logic patt_table_out_valid,
        output logic nmi,
        output logic dma
    );
    logic patt_table_ind;
    logic [7:0] oam_data;
    logic [7:0] ppu_ctrl;
    logic [1:0] nametable_sel;
    logic [7:0] ppu_mask;
    logic [7:0] ppu_status; // [4:0] unimportant, sprite overflow, sprite zero hit, vblank
    logic nmi_enable;
    assign nmi_enable = ppu_ctrl[7];
    logic slave_sel;
    assign slave_sel = ppu_ctrl[6];
    logic back_pat_addr_switch; // bad name
    logic sprite_pat_addr_switch; // bad name
    assign back_pat_addr_switch = ppu_ctrl[4];
    logic vram_inc;
    assign vram_inc = ppu_ctrl[2];
    assign sprite_pat_addr_switch = ppu_ctrl[3];
    logic sprite_size;
    assign sprite_size = ppu_ctrl[5];
    logic [1:0] nametable_addr_switch; // bad name
    assign nametable_addr_switch = ppu_ctrl[1:0];
    localparam CPU_WRITE = 1;
    logic vblank_flag;
    logic sprite_overflow_flag;
    logic sprite_0_hit_flag;
    assign ppu_status[7:5] = {vblank_flag, sprite_overflow_flag, sprite_0_hit_flag};
    // logic [1:0] force_vblank;
    logic [7:0] oam_addr;
    logic [7:0] oam_addr_dma; // can use fewer bits
    logic [15:0] ppu_scroll; // [15:8] X, [7:0] Y
    logic [15:0] ppu_addr;
    logic [7:0] ppu_data;
    logic [7:0] oam_dma; 
    logic w; // not working yet
    logic[4:0] cycle;
    logic [4:0] cycles_after;
    logic is_clock_even = 0;
    logic first_time;
    logic[8:0] dot;
    logic[8:0] scanline = 260; // This is the scanline plus 1 to avoid signed numbers issues, will change name / function
    localparam PPU_CYCLES_PER_CLOCK_CYCLE = 19; // This is not correct but closest integer multiplier
    // in the future, may want to use some input signal that runs at exactly PPU clock 
    

    // temporary vram addr
    logic [2:0] fine_x;


    logic [4:0] temp_vram_coarse_x = 0;
    logic [4:0] temp_vram_coarse_y = 0;
    logic [1:0] temp_vram_name_table_sel = 0;
    logic [2:0] temp_vram_fine_y = 0;
    logic [15:0] temp_vram_addr;
    assign temp_vram_addr[14:0] = {temp_vram_fine_y, temp_vram_name_table_sel, temp_vram_coarse_y, temp_vram_coarse_x};

    // reg vram

    typedef struct packed {
        logic [2:0] fine_y;
        logic [1:0] name_table_sel;
        logic [4:0] coarse_y;
        logic [4:0] coarse_x;
    } scroll_reg;
    scroll_reg vram_addr;
    logic [7:0] secondary_oam [31:0];
    // assign vram_addr[14:0] = {vram_fine_y, vram_name_table_sel, vram_coarse_y, vram_coarse_x};

    logic dma_even_passed;
    logic [7:0] dma_addr_high;
    logic [7:0] dma_addr_low;
    logic [7:0] dma_to_write;
    assign oam_addr_dma = dma_addr_low >> 2;

    typedef struct packed {
        logic [7:0] y;
        logic [7:0] tile;
        logic [7:0] att;
        logic [7:0] x;
    } oam_elt; // i can't believe i forgot structs were a thing :(

    oam_elt oam[64];  
    oam_elt current_sprite_line[8];
    initial begin
        //  $readmemh(`FPATH(2C07.mem), sys_palette); // May need to change
        //  $dumpfile("ppu.fst");
        //  for (int i = 0; i < 64; i = i + 1)
        //      $dumpvars(0, sys_palette[i]);
    end
    typedef enum logic [1:0] {
        FORCE_VSYNC_OFF = 2'd00,
        FORCE_VSYNC_ON  = 2'b01,
        VSYNC_MODIFIABLE = 2'b11
    } vsync_status;

    // Gets System Palette


    logic palette_ram_we;
    logic [7:0] palette_ram_data_in;
    logic [4:0] palette_ram_inp_addr;
    logic [4:0] palette_ram_inp_addr_ac;
    logic [4:0] palette_ram_inp_addr_deb;
    assign palette_ram_inp_addr_ac = (cycles_after >= 5) ? palette_ram_inp_addr_deb : palette_ram_inp_addr;
    logic [4:0] palette_ram_wri_addr;

    logic [23:0] palette_ram_output;

    palette_ram palette_ram_ins (.clk(clk), .we(palette_ram_we), .wri_addr(palette_ram_wri_addr), .inp_addr(palette_ram_inp_addr_ac),
    .din(palette_ram_data_in), .dout(palette_ram_output));
    // logic[15:0] read_addr;
    logic [7:0] ppu_data_buffer;
    logic[4:0] actual_read_addr;
    // if(16'h3F00 <= read_addr && read_addr <= 16'h3FFF ) begin
    //     // Mirroring 
    //     case(read_addr[4:0])
    //        5'h10: actual_read_addr = 5'h0;
    //        5'h14: actual_read_addr = 5'h4;
    //        5'h18: actual_read_addr = 5'h8;
    //        5'h1C: actual_read_addr = 5'hC;
    //     endcase
    // end



    // Actual Code
    logic [11:0] name_table_wr_addr;
    logic name_table_we;
    logic [7:0] name_table_in;
    logic [7:0] name_table_out;
    logic [11:0] name_table_re_addr;
    name_table my_nt(.clk(clk), .we(name_table_we),
    .read_addr(name_table_re_addr), .write_addr(name_table_wr_addr),
    .data_in(name_table_in), .is_mirroring_horiz(1'b0),
    .rst(rst), .data_out(name_table_out));


    logic [12:0] patt_table_wr_addr;
    logic patt_table_we_en;
    logic [7:0] patt_table_inp;
    logic [7:0] patt_table_out;
    logic [12:0] patt_table_re_addr;
    logic [12:0] patt_table_re_addr_ac;
    logic [12:0] patt_table_re_addr_deb;
    assign patt_table_re_addr_ac = (cycles_after >= 4) ? patt_table_re_addr_deb : patt_table_re_addr;
    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(8), //each entry in this memory is a byte
        .RAM_DEPTH(4096*2),
        .INIT_FILE(`FPATH(chr_rom.mem))) //there are two sides of table, both with 4096 entries each
    patt_table (
        .addra(patt_table_wr_addr), //pixels are stored using this math
        .clka(clk),
        .wea(patt_table_we_en),
        .dina(patt_table_inp),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(rst),
        .douta(), //never read from this side
        .addrb(patt_table_re_addr_ac),//transformed lookup pixel
        .dinb(8'b0),
        .clkb(clk),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst),
        .regceb(1'b1),
        .doutb(patt_table_out)
    );

    // assign ppu_clk_trig = (cycle == 0);
 // For writing to ppu addr

            //     ppu_reg_interface interf (
            //     .clk(clk),
            //     .ppu_clk_trig(ppu_clk_trig),
            //     .rst(rst),
            //     .cpu_rw(cpu_rw),
            //     .cpu_din(cpu_din),
            //     .cpu_dout(cpu_dout),
            //     .cpu_addr(cpu_addr),
            //     .ppu_addr(ppu_addr),
            //     .ppu_data(ppu_data),
            //     .ppu_ctrl(ppu_ctrl),
            //     .ppu_scroll(ppu_scroll),
            //     .ppu_mask(ppu_mask),
            //     .ppu_status(ppu_status),
            //     .oam_addr(oam_addr),
            //     .oam_data(oam_data)
            // );

    // Pattern table output

    // can only do this if it doesn't conflict!
    logic [4:0] tile_row;
    logic [3:0] rel_row;
    logic [3:0] rel_col;
    logic [4:0] tile_col;
    logic get_tile_msb;
    logic [7:0] patt_table_lsb;
    logic [7:0] patt_table_msb;
    logic loading_stage;
    logic [2:0] loading_stage_cycle;

logic patt_table_avail;
    assign patt_table_avail = ~loading_stage & cycles_after > 5 & !ppu_clk_trig;
    assign patt_table_out_valid = patt_table_avail & !first_time;
    assign patt_table_x =  patt_table_ind*128 + tile_col*8 + rel_col;
    assign patt_table_y = tile_row*8 + rel_row;
    assign patt_table_pix = palette_ram_output;
    assign patt_table_re_addr_deb = 16'h1000*patt_table_ind + 256 * tile_row + 16 * tile_col + rel_row + 8*get_tile_msb;
    assign palette_ram_inp_addr_deb = {patt_table_msb[7-rel_col], patt_table_lsb[7-rel_col]};

    always_ff @(posedge clk) begin
        if(rst) begin   
            get_tile_msb <= 0;
            tile_row <= 0;
            tile_col <= 0;
            rel_row <= 0;
            rel_col <= 0;
            loading_stage <= 1;
            loading_stage_cycle <= 0;
            patt_table_ind <= 0;
            fine_x <= 0;
            vram_addr <= 0;
            nametable_sel <= 0;
            // patt_table_pix <= 0;
        end else begin
            if(patt_table_avail & !first_time) begin
                // patt_table_out_valid <= 1;
                rel_col <= (rel_col == 7) ? 0 :rel_col + 1;
                if(rel_col == 7) begin
                    rel_row <= (rel_row == 7) ? 0 :rel_row + 1;
                    loading_stage <= 1; // cycle shoudl be 0
                    if(rel_row == 7) begin
                        tile_col <= (tile_col == 15) ? 0 : tile_col + 1;
                        if(tile_col == 15) begin
                            tile_row <= (tile_row == 15) ? 0 : tile_row + 1;
                            patt_table_ind <= (tile_row == 15) ? ~patt_table_ind : patt_table_ind;
                        end
                    end 
                end
            end else begin
                // patt_table_out_valid <= 0;
                if(loading_stage & !first_time & (loading_stage_cycle != 0 | cycles_after == 5)) begin
                    loading_stage_cycle <= (loading_stage_cycle == 4) ? 0 : loading_stage_cycle + 1;
                    if(loading_stage_cycle == 0) begin
                        get_tile_msb <= 0;
                    end if(loading_stage_cycle == 1) begin
                    end else if (loading_stage_cycle == 2) begin
                        get_tile_msb <= 1;
                        patt_table_lsb <= patt_table_out;
                    end else if (loading_stage_cycle == 3) begin
                        // patt_table_msb <= patt_table_out;
                    end else if (loading_stage_cycle == 4) begin
                        patt_table_msb <= patt_table_out;
                        loading_stage <= 0;
                    end
                end
            end
        end
    end
    logic [1:0] quadrant;
    assign quadrant = {vram_addr.coarse_y[1], vram_addr.coarse_x[1]};  
    logic [7:0] next_tile_nt;
    logic [7:0] next_tile_at;
    logic [7:0] bg_nt_lsb;
    logic [7:0] bg_nt_msb;
    
    
    logic [15:0] bg_shift_pat_msb;
    logic [15:0] bg_shift_pat_lsb;
    logic [1:0] bg_shift_at_lsb;
    logic [1:0] bg_shift_at_msb;


    logic [7:0] pix_mux;
    logic pix_msbit;
    logic pix_lsbit;
    logic pix_pal_msbit;
    logic pix_pal_lsbit;
    logic [7:0] pix_bit;
    assign pix_bit = 8'b1000_0000 >> fine_x;
    assign pix_msbit = (pix_bit & bg_shift_pat_msb[15:8]) != 0;
    assign pix_lsbit = (pix_bit & bg_shift_pat_lsb[15:8]) != 0;

    assign pix_pal_msbit = (pix_bit && bg_shift_at_msb[1]) != 0;
    assign pix_pal_lsbit = (pix_bit && bg_shift_at_lsb[1]) != 0;
    always_ff @(posedge clk) begin
        if(rst) begin
            // May need to rid
            oam_data <= 0;
            ppu_ctrl <= 0;
            ppu_mask <= 0;
            oam_addr <= 0;
            ppu_scroll <= 0; 
            ppu_addr <= 0;
            ppu_data <= 0;
            oam_dma <= 0;
            // may need to rid (end)
            cycle <= 0;
            first_time <= 1;
            dot <= 340;
            scanline <= 260;
            palette_ram_we <= 0;
            cycles_after <= 0;
            w <= 1;
            is_clock_even <= 0;

            temp_vram_coarse_x <= 0;
            temp_vram_coarse_y <= 0;
            temp_vram_fine_y <= 0;
            temp_vram_name_table_sel <= 0;
        end else begin
            // palette_ram_we <= (cpu_rw == CPU_WRITE && cpu_addr[2:0] == 3'h7 && ppu_addr >= 16'h3F00);
            first_time <= 0;
            cycles_after <= (ppu_clk_trig) ? 1 : (cycles_after + 1);
             // rename
            // TODO Add Test Cases for timing
            // verify there are no off by one errors
            // BACKGROUND rendering
            if(ppu_clk_trig) begin
                is_clock_even <= ~is_clock_even;
                if(dot >= 340) begin
                    dot <= 0;
                    scanline <= (scanline == 261) ? 0 : scanline + 1;
                end
                else begin
                    dot <= dot + 1;
                end
            end else begin

            // Yes, I know I'm essentially wasting a cycle
                
                if(dot == 1 && scanline == 241) begin
                    vblank_flag <= 1;
                    if (nmi_enable) nmi <= 1;
                end else if (dot == 1 && scanline == 261) begin
                    vblank_flag <= 0;
                    nmi <= 0;
                end else begin
                    nmi <= 0;
                end

                if(((2 <= dot && dot <= 257) || (321 <= dot && dot <= 338) ) && ((0 <= scanline && scanline < 240) || (scanline == 261))) begin
                    case (dot[2:0])
                        0: begin
                            if(cycles_after == 1) begin
                            if(ppu_mask[4] || ppu_mask[3]) begin
                                if(vram_addr.coarse_x == 31) begin
                                    vram_addr.name_table_sel[0] <= ~vram_addr.name_table_sel[0];
                                    vram_addr.coarse_x <= 0;
                                end else begin
                                vram_addr.coarse_x <= vram_addr.coarse_x + 1;
                                end
                            end
                            end
                        end
                        1: begin
                            if (cycles_after == 1) name_table_re_addr <= vram_addr[11:0];
                            // 2 cycles later
                            if (cycles_after == 4) next_tile_nt <= name_table_out;
                        end
                        3: begin
                            if (cycles_after == 1) name_table_re_addr <= 16'h23C0 | (vram_addr & 16'h0C00) | ((vram_addr >> 4) & 8'h38) | ((vram_addr >> 2) & 8'h07);
                            if (cycles_after == 4) begin
                                case(quadrant)
                                    2'b00: next_tile_at <= name_table_out[1:0];
                                    2'b01: next_tile_at <= name_table_out[3:2];
                                    2'b10: next_tile_at <= name_table_out[5:4];
                                    2'b11: next_tile_at <= name_table_out[7:6];
                                endcase
                            end
                        end
                        5: begin
                            if (cycles_after == 1 & !ppu_clk_trig) patt_table_re_addr <= (back_pat_addr_switch << 12) + (next_tile_nt << 4) + (vram_addr.fine_y + 0);
                            // 2 cycles later
                            if (cycles_after == 4) bg_nt_lsb <= patt_table_out;
                        end
                        7: begin
                            if (cycles_after == 1 & !ppu_clk_trig)  patt_table_re_addr <= (back_pat_addr_switch << 12) + (next_tile_nt << 4) + (vram_addr.fine_y + 8);
                            // 2 cycles later
                            if (cycles_after == 4) bg_nt_msb <= patt_table_out;
                        end
                        default: ;

                    endcase
                    if(cycles_after == 1) begin
                        if(dot[2:0] == 1) begin
                            bg_shift_pat_msb <= {bg_shift_pat_msb[14:8], bg_nt_msb, 1'b0};
                            bg_shift_pat_lsb <= {bg_shift_pat_lsb[14:8], bg_nt_lsb, 1'b0};

                            bg_shift_at_msb <= {bg_shift_at_msb[0], next_tile_at[1]};
                            bg_shift_at_lsb <= {bg_shift_at_lsb[0], next_tile_at[0]};
                        end else begin
                            bg_shift_pat_msb <= bg_shift_pat_msb << 1;
                            bg_shift_pat_lsb <= bg_shift_pat_lsb << 1;
                        end
                    end

                    if(dot == 256) begin
                        if(ppu_mask[4] || ppu_mask[3]) begin
                            if(cycles_after == 1) begin
                                if(vram_addr.fine_y < 7) begin
                                    vram_addr.fine_y <= vram_addr.fine_y + 1;
                                end else begin
                                    vram_addr.fine_y <= 0;
                                    if(vram_addr.coarse_y == 29 || vram_addr.coarse_y == 31 ) begin
                                        if(vram_addr.coarse_y == 29) vram_addr.name_table_sel[1] <= ~vram_addr.name_table_sel[1];
                                        vram_addr.coarse_y <= 0;
                                    end else begin
                                        vram_addr.coarse_y <= vram_addr.coarse_y + 1;
                                    end
                                end
                            end
                        end
                    end

                    if(dot == 257) begin
                        if(ppu_mask[4] || ppu_mask[3]) begin
                            vram_addr.name_table_sel[0] <= temp_vram_name_table_sel[0];
                            vram_addr.coarse_x <= temp_vram_coarse_x;
                        end
                    end
                end
                if(1 <= dot && dot <= 256 && 0 <= scanline && scanline < 240) begin
                    if(cycles_after == 1) palette_ram_inp_addr <= 4 * {pix_pal_msbit, pix_pal_lsbit} + {pix_msbit, pix_lsbit};
                    // 1 cycle later
                    if(cycles_after == 2) begin
                        pixel_x <= (dot - 1);
                        pixel_y <= scanline;
                        pixel_valid <= 1;
                        pixel <= palette_ram_output;
                    end else begin
                        pixel_valid <= 0;
                    end
                end
                if(scanline == 261 && 280 <= dot && dot < 305) begin
                    if(ppu_mask[4] || ppu_mask[3]) begin
                        vram_addr.name_table_sel[1] <= temp_vram_name_table_sel[1];
                        vram_addr.coarse_y <= temp_vram_coarse_y;    
                        vram_addr.fine_y <= temp_vram_fine_y; // TODO: double check
                    end            
                end
            end

            if(16'h2000 <= cpu_addr && cpu_addr <= 16'h3FFF) begin
                if(cpu_rw == CPU_WRITE) begin
                    // 16'h4014: oam_dma <= cpu_dout; -> needs to be in separate if statements
                    case (cpu_addr[2:0]) 
                        3'h0: begin 
                            ppu_ctrl <= cpu_dout;
                            temp_vram_name_table_sel <= nametable_sel;
                        end
                        3'h1: ppu_mask <= cpu_dout;
                        3'h3: oam_addr <= cpu_dout;
                        3'h4: oam[oam_addr] <= cpu_dout;
                        3'h5: begin 
                            // for now
                            if(ppu_clk_trig) begin
                                if(w) begin
                                    fine_x <= cpu_dout[2:0];
                                    temp_vram_coarse_x <= cpu_dout[7:3];
                                    // w <= (cycle == PPU_CYCLES_PER_CLOCK_CYCLE - 1) ? 0 : w; // need to change when have actual clocks
                                    // w <= 
                                end else begin
                                    // pgpu_scroll[7:0] <= cpu_dout;
                                    // w <= (cycle == PPU_CYCLES_PER_CLOCK_CYCLE - 1) ? 1 : w;
                                    temp_vram_fine_y <= cpu_dout[2:0];
                                    temp_vram_coarse_y <= cpu_dout[7:3];
                                end
                                w <= ~w;
                            end
                            w <= (ppu_clk_trig) ? ~w : w;
                        end // handle later
                        3'h6: begin 
                            if(ppu_clk_trig) begin
                                if(w) begin
                                    // temp_vram_addr[7:0] <= cpu_dout;
                                    temp_vram_coarse_x <= cpu_dout[4:0];
                                    temp_vram_coarse_y[2:0] <= cpu_dout[7:5];
                                    vram_addr <= {temp_vram_addr[15:8], cpu_dout};

                                    // w <= (cycle == PPU_CYCLES_PER_CLOCK_CYCLE - 1) ? 0 : w;
                                end else begin
                                    // temp_vram_addr[15:8] <= cpu_dout;
                                    temp_vram_fine_y <= cpu_dout[6:4];
                                    temp_vram_name_table_sel <= cpu_dout[3:2];
                                    temp_vram_coarse_y[4:3] <= cpu_dout[1:0];
                                    // w <= (cycle == PPU_CYCLES_PER_CLOCK_CYCLE - 1) ? 1 : w;
                                end
                                w <= ~w;
                            end
                        end // handle later
                        3'h7: begin
                                if(vram_addr <= 16'h1FFF) begin
                                // Regular Case
                                // TODO: Implement
                                patt_table_we_en <= ppu_clk_trig;
                                patt_table_wr_addr <= vram_addr;
                                patt_table_inp <= ppu_data;
                                end else if (vram_addr > 16'h1FFF && vram_addr < 16'h3F00) begin
                                    name_table_wr_addr <= vram_addr; 
                                    name_table_we <= ppu_clk_trig;
                                    name_table_in <= ppu_data;
                                end else if (vram_addr >= 16'h3F00 && vram_addr <= 16'h3FFF) begin
                                // we is on for one cycle
                                palette_ram_we <= ppu_clk_trig;

                                palette_ram_wri_addr <= vram_addr;
                                palette_ram_data_in <= ppu_data;

                                end
                                if(ppu_clk_trig) vram_addr <= vram_inc ? vram_addr + 32 : vram_addr + 1;
                            end
                    endcase
                end else begin
                    case (cpu_addr[2:0])
                        3'h2: begin 
                            cpu_din <= {ppu_status[7:5], ppu_data_buffer[4:0]};
                            w <= 0; 
                            vblank_flag <= 0;
                        end
                        3'h4: cpu_din <= oam[oam_addr];
                        3'h7: begin 
                            if(vram_addr <= 16'h1FFF) begin
                                if (ppu_clk_trig) patt_table_re_addr <= vram_addr;
                                if (cycles_after == 2) ppu_data_buffer <= patt_table_out;
                                if(ppu_clk_trig) cpu_din <= ppu_data_buffer;
                            end else if (vram_addr > 16'h1FFF && vram_addr < 16'h3F00) begin
                                name_table_re_addr <= vram_addr; 
                                if(cycles_after == 2) ppu_data <= name_table_out;
                            end else if(vram_addr >= 16'h3F00 && vram_addr <= 16'h3FFF) begin
                                if(ppu_clk_trig) palette_ram_inp_addr <= vram_addr[4:0];

                                // will only take effect one cycle after trigger but eh that's fine
                                if(cycles_after == 2) begin
                                    ppu_data <= palette_ram_output;
                                    ppu_data_buffer <=  palette_ram_output;
                                end
                            end
                            if(ppu_clk_trig) vram_addr <= vram_inc ? vram_addr + 32 : vram_addr + 1;
                        end
                    endcase
            end     

            cpu_din_valid <= ((cpu_addr[2:0] == 2 || cpu_addr[2:0] == 4 || ( cpu_addr[2:0] == 7 && vram_addr <= 16'h1FFF)) & cpu_rw != CPU_WRITE);
            // FOREGROUND rendering 
            // TODO: Properly integrate this

            // if(!ppu_clk_trig) begin
            //     if(dot == 1 && scanline != 261) begin
            //         for(int i = 0; i < 8; i++) begin
            //             current_sprite_line[i] <= 32'hFFFFFFFF;
            //         end
            //     end
            //     if(dot == 257) begin

            //     end
            // end
            end   
        end
            /* Verify later */
    end
    // logic [3:0] sprite_count;
    // always_comb begin
    //     sprite_count = 0;
    //     for (i = 0; i < 64; i++) begin
    //         if (sprite_count < 4'd9) begin
    //             if (scanline >= oam[i].y && 
    //                 scanline < oam[i].y + (sprite_size ? 10'sd16 : 10'sd8)) begin 
    //                 if (sprite_count < 4'd8) begin
    //                     spriteScanline[sprite_count] = oam[i];
    //                 end
    //                 sprite_count = sprite_count + 4'd1;
    //             end
    //         end
    //     end
    //     sprite_overflow_flag = (sprite_count > 4'd8);

    // end
    //  always_ff @(posedge ppu_clk_trig) begin
    //         if(cpu_addr == 16'h4014 && cpu_rw == CPU_WRITE && !dma) begin
    //             dma_addr_high <= cpu_din;
    //             dma_addr_low <= 0;
    //             dma <= 1;
    //         end
    //         if(dma) begin
    //             if(dma_even_passed) begin
    //                 if(is_clock_even) begin
    //                     // dma_to_write <= // read {dma_addr_high, dma_addr_low};
    //                 end else begin
    //                     dma_addr_low <= dma_addr_low + 1;
    //                     if(dma_addr_low == 255) begin
    //                         dma <= 0;
    //                         dma_even_passed <= 0;
    //                     end
    //                     case (dma_addr_low[1:0])
    //                         0: oam[oam_addr_dma].y <= dma_to_write;
    //                         1: oam[oam_addr_dma].tile <= dma_to_write;
    //                         2: oam[oam_addr_dma].att <= dma_to_write;
    //                         3: oam[oam_addr_dma].x <= dma_to_write;
    //                     endcase
    //                 end
    //             end else begin
    //                 if(is_clock_even) begin
    //                     dma_even_passed <= 1;
    //                 end
    //             end
    //         end
    //     end
endmodule
    
    
    `default_nettype wire



