`default_nettype none
module cpu (
        input wire clk,
        input wire rst,

        output logic [7:0] dout,
        output logic [15:0] addr,
        input wire [7:0] din,
        output logic rw,

        input wire irq,
        input wire nmi,

        output logic [1:0] audio_out // putting in here for future expansion
    );
endmodule

`default_nettype wire



