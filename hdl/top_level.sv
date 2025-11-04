`timescale 1ns / 1ps
`default_nettype none 
 
module top_level(
        input wire [15:0] sw, 
        input wire [3:0] btn,
        input wire clk_100mhz,
        output logic [15:0] led, 
        output logic [2:0] rgb0, 
        output logic [2:0] rgb1, 
        output logic [3:0] ss0_an,
        output logic [3:0] ss1_an,
        output logic [6:0] ss0_c,
        output logic [6:0] ss1_c,
        output logic [2:0] pmoda
    );
 
    
 
endmodule // top_level
`default_nettype wire