
`timescale 1ns / 1ps
`default_nettype none
`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../data/X`"
`endif  /* ! SYNTHESIS */

module palette_ram
(
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  wri_addr,
    input  wire [4:0]  inp_addr,
    input  wire [7:0]  din,
    output logic [23:0]  dout
);
    logic [23:0] sys_palette [0:63]; // since this is small, i'm just using registers
    logic [7:0] palette_ram [0:31]; // also small
    logic [4:0] actual_addr;
    initial begin
         $readmemh(`FPATH(2C07.mem), sys_palette); // May need to change

//          // temp
         palette_ram[0]  = 8'h0F;
palette_ram[1]  = 8'h11;
palette_ram[2]  = 8'h21;
palette_ram[3]  = 8'h31;

palette_ram[4]  = 8'h0F;
palette_ram[5]  = 8'h12;
palette_ram[6]  = 8'h22;
palette_ram[7]  = 8'h32;

palette_ram[8]  = 8'h0F;
palette_ram[9]  = 8'h13;
palette_ram[10] = 8'h23;
palette_ram[11] = 8'h33;

palette_ram[12] = 8'h0F;
palette_ram[13] = 8'h14;
palette_ram[14] = 8'h24;
palette_ram[15] = 8'h34;

palette_ram[16] = 8'h0F;
palette_ram[17] = 8'h15;
palette_ram[18] = 8'h25;
palette_ram[19] = 8'h35;

palette_ram[20] = 8'h0F;
palette_ram[21] = 8'h16;
palette_ram[22] = 8'h26;
palette_ram[23] = 8'h36;

palette_ram[24] = 8'h0F;
palette_ram[25] = 8'h17;
palette_ram[26] = 8'h27;
palette_ram[27] = 8'h37;

palette_ram[28] = 8'h0F;
palette_ram[29] = 8'h18;
palette_ram[30] = 8'h28;
palette_ram[31] = 8'h38;

        //  $dumpfile("palette_ram.fst");
        //  for (int i = 0; i < 64; i = i + 1)
        //      $dumpvars(0, sys_palette[i]);
        // for (int i = 0; i < 31; i = i + 1)
        //      $dumpvars(0, palette_ram[i]);
    end
    always_comb begin
        case (inp_addr)
            5'h10: actual_addr = 5'h00;
            5'h14: actual_addr = 5'h04;
            5'h18: actual_addr = 5'h08;
            5'h1C: actual_addr = 5'h0C;
            default: actual_addr = inp_addr;
        endcase
    end
    always_ff @(posedge clk) begin
        // if (we) palette_ram[actual_addr] <= data_in;
    end

    assign dout = sys_palette[palette_ram[actual_addr]];

endmodule
