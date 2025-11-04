`default_nettype none
module ppu (
        input wire clk,
        input wire rst,
        input logic [7:0] cpu_dout,
        input logic [15:0] cpu_addr, // from what i'm seeing, in the hardware it's only 3 bits?
        output logic [7:0] cpu_din,
        output logic [23:0] pixel, // 8 : 8 : 8 for now, might change to be 5 : 6 : 5?
        input logic cpu_rw
    );
    logic [7:0] oam_data;
    logic [7:0] ppu_ctrl;
    logic [7:0] ppu_mask;
    logic [7:0] ppu_status; // [4:0] unimportant, sprite overflow, sprite zero hit, vblank

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
    logic[8:0] scanline_p1; // This is the scanline plus 1 to avoid signed numbers issues, will change name / function
    localparam PPU_CYCLES_PER_CLOCK_CYCLE = 19; // This is not correct but closest integer multiplier
    // in the future, may want to use some input signal that runs at exactly PPU clock speed


    // Gets System Palette

    // Want to create a module but am delaying bc idk where i'll put palette read for now
    // and bc of the issue of passing unpacked modules btw modules

    // logic[15:0] read_addr;
    // logic[4:0] actual_read_addr;
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
    logic [7:0] patt_table_in;
    logic [7:0] patt_table_out;
    logic [12:0] patt_table_re_addr;
    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(8), //each entry in this memory is a byte
        .RAM_DEPTH(4096*2)) //there are two sides of table, both with 4096 entries each
    patt_table (
        .addra(patt_table_wr_addr), //pixels are stored using this math
        .clka(clk),
        .wea(patt_table_we_en),
        .dina(patt_table_in),
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

    logic[5:0] actual_read_addr; // For writing to ppu addr

                ppu_reg_interface interf (
                .clk(clk),
                .ppu_clk_trig(ppu_clk_trig),
                .rst(rst),
                .cpu_rw(cpu_rw),
                .cpu_din(cpu_din),
                .cpu_dout(cpu_dout),
                .cpu_addr(cpu_addr),
                .ppu_addr(ppu_addr),
                .ppu_data(ppu_data),
                .ppu_ctrl(ppu_ctrl),
                .ppu_scroll(ppu_scroll),
                .ppu_mask(ppu_mask),
                .ppu_status(ppu_status),
                .oam_addr(oam_addr),
                .oam_data(oam_data)
            );

            
    always_ff @(posedge clk) begin
        if(rst) begin
            // oam_data <= 0;
            // ppu_ctrl <= 0;
            // ppu_mask <= 0;
            // ppu_status <= 0;
            // oam_addr <= 0;
            // ppu_scroll <= 0; 
            // ppu_addr <= 0;
            // ppu_data <= 0;
            // oam_dma <= 0;
            cycle <= 0;
            first_time <= 1;
            dot <= 0;
            scanline_p1 <= 1;
        end else begin
            first_time <= 0;
            cycle <= (cycle == PPU_CYCLES_PER_CLOCK_CYCLE - 1) ? 0 : (cycle + 1);

            // TODO Add Test Cases for timing
            // verify there are no off by one errors
            if(ppu_clk_trig & !first_time) begin
                if(dot >= 341) begin
                    dot <= 0;
                    scanline_p1 <= (scanline_p1 == 261) ? 0 : scanline_p1 + 1;
                    // need trigger to show that frame is complete
                end else begin
                    dot <= dot + 1;
                end
            end
            // TODO: This may only be permitted during blank periods, need to double check
            // and if necessary, only do it during these times     
        end
    end
endmodule
    
    
    `default_nettype wire



