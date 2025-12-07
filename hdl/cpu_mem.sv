`timescale 1ns / 1ps
`default_nettype none
`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../data/X`"
`endif  /* ! SYNTHESIS */
module cpu_mem (
        input wire clk,
        input wire rst,
        input wire [7:0] cpu_dout,
        input wire [15:0] cpu_addr,
        output logic [7:0] cpu_din,
        output logic cpu_din_valid,
        input wire cpu_rw
    );

    logic [10:0] mapped_addr;

    always_comb begin
        if (cpu_addr > 16'h1FFF) begin
            mapped_addr = 0;
            cpu_din_valid = 0; // i'm just going to do this for now but should this not be pipelined?
        end else begin
            mapped_addr = cpu_addr[10:0];
            cpu_din_valid = 1;
        end
    end

   logic cpu_ram_we;
   assign cpu_ram_we = cpu_rw & cpu_addr <= 16'h1FFF;
   xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(8), //each entry in this memory is a byte
        .RAM_DEPTH(16'h800)) 
    cpu_ram (
        .addra(mapped_addr), 
        .clka(clk),
        .wea(cpu_ram_we),
        .dina(),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(rst),
        .douta(), //never read from this side
        .addrb(mapped_addr),
        .dinb(8'b0),
        .clkb(clk),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst),
        .regceb(1'b1),
        .doutb(cpu_din)
    ); // probably doesn't need to be dual port tbhs

endmodule


`default_nettype wire



