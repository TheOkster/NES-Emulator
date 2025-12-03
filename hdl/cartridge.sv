`timescale 1ns / 1ps
`default_nettype none
`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../data/X`"
`endif  /* ! SYNTHESIS */
module cartridge (
        input wire clk,
        input wire rst,

        input logic [7:0] cpu_dout,
        input logic [15:0] cpu_addr,
        output wire [7:0] cpu_din,
        output logic cpu_din_valid;
        input logic cpu_rw,
    
        input logic [7:0] ppu_dout,
        input logic [13:0] ppu_addr,
        output wire [7:0] ppu_din,
        output logic ppu_din_valid;
        input logic ppu_rw,
    );

    mapper0 (
        .clk(clk),
        .rst(rst),
        .cpu_dout(cpu_dout),
        .cpu_addr(cpu_addr),
        .cpu_din(cpu_din),
        .cpu_din_valid(cpu_din_valid),
        .ppu_rw(ppu_rw),
        .ppu_dout(ppu_dout),
        .ppu_addr(ppu_addr),
        .ppu_din(ppu_din),
        .ppu_din_valid(ppu_din_valid),
        .ppu_rw(ppu_rw),
    );
endmodule

module mapper0 (
        input wire clk,
        input wire rst,

        input logic [7:0] cpu_dout,
        input logic [15:0] cpu_addr,
        input logic cpu_rw,
    
        input logic [7:0] ppu_dout,
        input logic [13:0] ppu_addr,
        input logic cpu_rw,

        output logic [7:0] cpu_din;
        output logic cpu_din_valid;

        output logic [7:0] ppu_din;
        output logic ppu_din_valid;
)
    logic [15:0] cpu_mapped_addr;
    logic [13:0] ppu_mapped_addr;

    always_comb begin
        if (cpu_addr < 16'h8000) {
            cpu_mapped_addr = 0;
            cpu_din_valid = 0;
        } else {
            cpu_mapped_addr = (cpu_addr - 16'h8000) & 16'h8000
            cpu_din_valid = 1;
        }
    end

    always_comb begin
        ppu_mapped_addr = ppu_addr
        ppu_din_valid = 1;
    end

    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(8), //each entry in this memory is a byte
        .RAM_DEPTH(16'h8000),
        .INIT_FILE(`FPATH(prg_rom.mem))) 
    patt_table (
        .addra(), //pixels are stored using this math
        .clka(clk),
        .wea(0),
        .dina(),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(rst),
        .douta(), //never read from this side
        .addrb(cpu_mapped_addr),//transformed lookup pixel
        .dinb(8'b0),
        .clkb(clk),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst),
        .regceb(1'b1),
        .doutb(cpu_din)
    );

    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(8), //each entry in this memory is a byte
        .RAM_DEPTH(8192),
        .INIT_FILE(`FPATH(chr_rom.mem))) //there are two sides of table, both with 4096 entries each
    patt_table (
        .addra(), //pixels are stored using this math
        .clka(clk),
        .wea(0),
        .dina(),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(rst),
        .douta(), //never read from this side
        .addrb(ppu_mapped_addr),//transformed lookup pixel
        .dinb(8'b0),
        .clkb(clk),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst),
        .regceb(1'b1),
        .doutb(ppu_din)
    );

endmodule

`default_nettype wire



