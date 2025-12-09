`timescale 1ns / 1ps
`default_nettype none
 
module uart_receive
  #(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
    )
   (
    input wire 	       clk,
    input wire 	       rst,
    input wire 	       din,
    output logic       dout_valid,
    output logic [7:0] dout
    );
 
    localparam BAUD_BIT_PERIOD = INPUT_CLOCK_FREQ / BAUD_RATE;
    
    typedef enum {
        IDLE = 0,
        START = 1,
        DATA = 2,
        STOP = 3,
        TRANSMIT = 4
    } uart_state;
    
    // note: for the online checker, don't rename this variable
    uart_state state;

    logic [$clog2(BAUD_BIT_PERIOD-1):0] baud_counter;
    logic [7:0] data_buffer;
    
    // TODO: module to read UART rx wire
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            baud_counter <= 0;
            data_buffer <= 0;
            dout_valid <= 0;
            dout <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (din == 0) begin
                        state <= START;
                    end
                    baud_counter <= 0;
                    data_buffer <= 0;
                    dout_valid <= 0;
                end
                START: begin
                    if (baud_counter + 1 == BAUD_BIT_PERIOD/2) begin
                        state <= din == 0 ? DATA : IDLE;
                        data_buffer <= 8'b1000_0000;
                    end 
                    baud_counter <= baud_counter + 1;
                end
                DATA: begin
                    if (baud_counter + 1 == BAUD_BIT_PERIOD/2) begin
                        data_buffer <= (data_buffer >> 1) | (din << 7);
                        if (data_buffer[0] == 1) state <= STOP;
                    end
                    if (baud_counter + 1 == BAUD_BIT_PERIOD) begin
                        baud_counter <= 0;
                    end else baud_counter <= baud_counter + 1;
                end
                STOP: begin
                    if (baud_counter + 1 == BAUD_BIT_PERIOD/2) begin
                        state <= din == 1 ? TRANSMIT : IDLE;
                    end
                    if (baud_counter + 1 == BAUD_BIT_PERIOD) begin
                        baud_counter <= 0;
                    end else baud_counter <= baud_counter + 1;
                end
                TRANSMIT: begin
                    dout_valid <= 1;
                    dout <= data_buffer;
                    state <= IDLE;
                end
            endcase
        end
    end
   
 
endmodule // uart_receive
 
`default_nettype wire