    
    
`timescale 1ns / 1ps
`default_nettype none
`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../data/X`"
`endif  /* ! SYNTHESIS */

module name_table ( 
   input wire clk,
   input wire we,
   input wire [11:0] read_addr,
   input wire [11:0] write_addr,
   input wire [7:0] data_in,
   input wire is_mirroring_horiz,
   input wire rst,
   output logic [7:0] data_out
);
   logic [10:0] actual_rd_addr;
   logic [10:0] actual_wr_addr;
    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(8), //each entry in this memory is 16 bits
        .RAM_DEPTH(2048)) // 2 name tables
    name_table (
        .addra(actual_wr_addr), //pixels are stored using this math
        .clka(clk),
        .wea(we),
        .dina(data_in),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(rst),
        .douta(), //never read from this side
        .addrb(actual_rd_addr),//transformed lookup pixel
        .dinb(8'b0),
        .clkb(clk),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst),
        .regceb(1'b1),
        .doutb(data_out)
    );
    always_comb begin
      if (is_mirroring_horiz) begin
         if (16'h000 <= read_addr && read_addr < 16'h400) begin
            actual_rd_addr = read_addr;
         end else if (16'h400 <= read_addr && read_addr < 16'h800) begin
            actual_rd_addr = read_addr;
         end else if (16'h800 <= read_addr && read_addr < 16'hC00) begin
            actual_rd_addr = 1024 + read_addr;
         end else begin
            actual_rd_addr = 1024 + read_addr;
         end


         if (16'h000 <= read_addr && read_addr < 16'h400) begin
            actual_wr_addr = write_addr;
         end else if (16'h400 <= read_addr && read_addr < 16'h800) begin
            actual_wr_addr = write_addr;
         end else if (16'h800 <= read_addr && read_addr < 16'hC00) begin
            actual_wr_addr = 1024 + write_addr;
         end else begin
            actual_wr_addr = 1024 + write_addr;
         end
      end else begin
      if (16'h000 <= read_addr && read_addr < 16'h400) begin
         actual_rd_addr = read_addr;
      end else if (16'h400 <= read_addr && read_addr < 16'h800) begin
         actual_rd_addr = 1024 + read_addr;
      end else if (16'h800 <= read_addr && read_addr < 16'hC00) begin
         actual_rd_addr = read_addr;
      end else begin
         actual_rd_addr = 1024 + read_addr;
      end

      if (16'h000 <= read_addr && read_addr < 16'h400) begin
         actual_wr_addr = write_addr;
      end else if (16'h400 <= read_addr && read_addr < 16'h800) begin
         actual_wr_addr = 1024 + write_addr;
      end else if (16'h800 <= read_addr && read_addr < 16'hC00) begin
         actual_wr_addr = write_addr;
      end else begin
         actual_wr_addr = 1024 + write_addr;
      end
      end
   end

endmodule