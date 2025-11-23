module palette_ram
(
    input  logic        clk,
    input  logic        we,
    input  logic [4:0]  inp_addr,
    input  logic [7:0]  din,
    output logic [7:0]  dout
);
    logic [23:0] sys_palette [0:63]; // since this is small, i'm just using registers
    logic [7:0] palette_ram [0:31]; // also small
    logic [4:0] actual_addr;
    initial begin
         $readmemh(`FPATH(2C07.mem), sys_palette); // May need to change
         // $dumpfile("ppu.fst");
         // for (int i = 0; i < 64; i = i + 1)
         //     $dumpvars(0, sys_palette[i]);
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
        if (we) palette_ram[actual_addr] <= data_in;
    end

    assign data_out = palette_ram[actual_addr];

endmodule
