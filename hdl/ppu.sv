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
        output logic [23:0] pixel, // 8 : 8 : 8 for now, might change to be 5 : 6 : 5?
        input wire cpu_rw,
        // output logic patt_table_ind, // 0 or 1
        output logic [7:0] patt_table_x,
        output logic [7:0] patt_table_y,
        output logic [23:0] patt_table_pix,
        output logic patt_table_out_valid

    );
    logic patt_table_ind;
    logic [7:0] oam_data;
    logic [7:0] ppu_ctrl;
    logic [7:0] ppu_mask;
    logic [7:0] ppu_status; // [4:0] unimportant, sprite overflow, sprite zero hit, vblank
    localparam CPU_WRITE = 0; // opposite of what you might think
    logic vblank_flag;
    logic sprite_overflow_flag;
    logic sprite_0_hit_flag;
    assign ppu_status[7:5] = {vblank_flag, sprite_overflow_flag, sprite_0_hit_flag};
    logic [1:0] force_vblank;
    logic [7:0] oam_addr;
    logic [15:0] ppu_scroll; // [15:8] X, [7:0] Y
    logic [15:0] ppu_addr;
    logic [7:0] ppu_data;
    logic [7:0] oam_dma; 
    logic w; // not working yet
    logic[4:0] cycle;
    logic ppu_clk_trig;
    logic first_time;
    logic[8:0] dot;
    logic[8:0] scanline; // This is the scanline plus 1 to avoid signed numbers issues, will change name / function
    localparam PPU_CYCLES_PER_CLOCK_CYCLE = 19; // This is not correct but closest integer multiplier
    // in the future, may want to use some input signal that runs at exactly PPU clock 
    
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

    // Want to create a module but am delaying bc idk where i'll put palette read for now
    // and bc of the issue of passing unpacked modules btw modules
    logic palette_ram_we;
    logic palette_ram_data_in;
    logic [4:0] palette_ram_inp_addr;
    logic [23:0] palette_ram_output;

    palette_ram palette_ram_ins (.clk(clk), .we(palette_ram_we), .inp_addr(palette_ram_inp_addr),
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
    logic [9:0] name_table_wr_addr;
    logic name_table_we_en;
    logic [7:0] name_table_in;
    logic [7:0] name_table_out;
    logic [9:0] name_table_re_addr;
    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(8), //each entry in this memory is 16 bits
        .RAM_DEPTH(1024)) //there are 320*180 or 57600 entries for full frame
    name_table (
        .addra(name_table_wr_addr), //pixels are stored using this math
        .clka(clk),
        .wea(name_table_we_en),
        .dina(name_table_in),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(rst),
        .douta(), //never read from this side
        .addrb(name_table_re_addr),//transformed lookup pixel
        .dinb(8'b0),
        .clkb(clk),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst),
        .regceb(1'b1),
        .doutb(name_table_out)
    );


    logic [12:0] patt_table_wr_addr;
    logic patt_table_we_en;
    logic [7:0] patt_table_inp;
    logic [7:0] patt_table_out;
    logic [12:0] patt_table_re_addr;
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
        .addrb(patt_table_re_addr),//transformed lookup pixel
        .dinb(8'b0),
        .clkb(clk),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst),
        .regceb(1'b1),
        .doutb(patt_table_out)
    );

    assign ppu_clk_trig = (cycle == 0);
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
    logic [4:0] tile_row;
    logic [3:0] rel_row;
    logic [3:0] rel_col;
    logic [4:0] tile_col;
    logic get_tile_msb;
    logic [7:0] patt_table_lsb;
    logic [7:0] patt_table_msb;
    logic loading_stage;
    logic [2:0] loading_stage_cycle;

    assign patt_table_re_addr = 16'h1000*patt_table_ind + 256 * tile_row + 16 * tile_col + rel_row + 8*get_tile_msb;// CHROM ONLY
    assign patt_table_out_valid = ~loading_stage;
    assign patt_table_x =  patt_table_ind*128 + tile_col*8 + rel_col;
    assign patt_table_y = tile_row*8 + rel_row;
    assign palette_ram_inp_addr = {patt_table_msb[7-rel_col], patt_table_lsb[7-rel_col]};
    assign patt_table_pix = palette_ram_output;
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
            // patt_table_pix <= 0;
        end else begin
            if(ppu_clk_trig & !first_time) begin
                if(patt_table_out_valid) begin
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
                end
            end else begin
                if(loading_stage & !first_time) begin
                    loading_stage_cycle <= (loading_stage_cycle == 4) ? 0 : loading_stage_cycle + 1;
                    if(loading_stage_cycle == 0) begin
                    end if(loading_stage_cycle == 1) begin
                        get_tile_msb <= 0;
                    end else if (loading_stage_cycle == 2) begin
                        patt_table_lsb <= patt_table_out;
                    end else if (loading_stage_cycle == 3) begin
                        get_tile_msb <= 1;
                        // patt_table_msb <= patt_table_out;
                    end else if (loading_stage_cycle == 4) begin
                        patt_table_msb <= patt_table_out;
                        loading_stage <= 0;
                    end
                end
            end
        end
    end
            
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
            dot <= 0;
            scanline <= 0;
        end else begin
            first_time <= 0;
            cycle <= (cycle == PPU_CYCLES_PER_CLOCK_CYCLE - 1) ? 0 : (cycle + 1);

            // TODO Add Test Cases for timing
            // verify there are no off by one errors
            if(ppu_clk_trig & !first_time) begin
                if(dot >= 340) begin
                    dot <= 0;
                    scanline <= (scanline == 261) ? 0 : scanline + 1;
                end
                else begin
                    dot <= dot + 1;
                end

                if(dot == 340 && scanline == 239) begin
                    force_vblank <= FORCE_VSYNC_ON;
                end else if (dot == 340 && scanline == 260) begin
                    force_vblank <= FORCE_VSYNC_OFF; // need to implement NMI too
                end else begin
                    force_vblank <= VSYNC_MODIFIABLE;
                end

                /* Verify later */
                if(16'h2000 <= cpu_addr && cpu_addr <= 16'h3FFF) begin
                    if(cpu_rw == CPU_WRITE) begin
                        // 16'h4014: oam_dma <= cpu_dout; -> needs to be in separate if statements
                        case (cpu_addr[2:0]) // Changed to be 3 bits but keeping 16 bit input for mirroring
                            3'h0: ppu_ctrl <= cpu_dout;
                            3'h1: ppu_mask <= cpu_dout;
                            3'h3: oam_addr <= cpu_dout;
                            3'h4: oam_data <= cpu_dout;
                            3'h5: begin 
                                if(w) begin
                                    ppu_scroll[15:8] <= cpu_dout;
                                    w <= (cycle == PPU_CYCLES_PER_CLOCK_CYCLE - 1) ? 0 : w;
                                end else begin
                                    ppu_scroll[7:0] <= cpu_dout;
                                    w <= (cycle == PPU_CYCLES_PER_CLOCK_CYCLE - 1) ? 1 : w;
                                end
                            end // handle later
                            3'h6: begin 
                                if(w) begin
                                    ppu_addr[7:0] <= cpu_dout;
                                    w <= (cycle == PPU_CYCLES_PER_CLOCK_CYCLE - 1) ? 0 : w;
                                end else begin
                                    ppu_addr[15:8] <= cpu_dout;
                                    w <= (cycle == PPU_CYCLES_PER_CLOCK_CYCLE - 1) ? 1 : w;
                                end
                            end // handle later
                            3'h7: begin
                                if(ppu_addr < 16'h3F00) begin
                                    // Regular Case
                                    // TODO: Implement
                                end else begin
                                    case(ppu_addr[4:0])
                                        5'h10: actual_read_addr = 5'h0;
                                        5'h14: actual_read_addr = 5'h4;
                                        5'h18: actual_read_addr = 5'h8;
                                        5'h1C: actual_read_addr = 5'hC;
                                        default: actual_read_addr = ppu_addr[4:0];
                                    endcase
                                    // TODO: BRING BACK
                                    // palette_ram[actual_read_addr] <= cpu_din;
                                 end
                                ppu_addr <= ppu_addr + 1;
                            end
                        endcase
                    end
                    else begin
                        case (cpu_addr)
                            16'h2002: begin 
                                cpu_din <= {ppu_status[7:5], ppu_data_buffer[4:0]};
                                w <= 0;
                                vblank_flag <= 0;
                            end
                            16'h2004: cpu_din <= oam_data;
                            16'h2007: begin 
                                if(ppu_addr < 16'h3F00) begin
                                    // Regular Case
                                    // TODO: Implement
                                    ppu_data <= ppu_data_buffer;
                                end else begin
                                    case(ppu_addr[4:0])
                                        5'h10: actual_read_addr = 5'h0;
                                        5'h14: actual_read_addr = 5'h4;
                                        5'h18: actual_read_addr = 5'h8;
                                        5'h1C: actual_read_addr = 5'hC;
                                        default: actual_read_addr = ppu_addr[4:0];
                                    endcase
                                    // TODO: BRING BACK
                                    // ppu_data <= palette_ram[actual_read_addr];
                                    // ppu_data_buffer <=   palette_ram[actual_read_addr];
                                end
                                ppu_addr <= ppu_addr + 1;
                            end
                        endcase

                    end    
                end 
            end   
            /* */
        end
    end
    
endmodule
    
    
    `default_nettype wire



