`timescale 1ns / 1ps
`default_nettype none

module uart_transmit
  #(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
    )
   (
    input wire 	     clk,
    input wire 	     rst,
    input wire [7:0] din,
    input wire 	     trigger,
    output logic     busy,
    output logic     dout
    );

    localparam BAUD_BIT_PERIOD = INPUT_CLOCK_FREQ / BAUD_RATE;

    typedef enum { IDLE, STARTING, TRANSMITTING, STOPPING } uart_state;
    uart_state state;

    logic [$clog2(BAUD_BIT_PERIOD-1):0] baud_counter;
    logic [8:0] data_buffer;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            baud_counter <= 0;
            data_buffer <= 0;
            busy <= 0;
            dout <= 1;
        end
        else begin
            case (state)
                IDLE: begin
                    if (trigger) begin
                        state <= STARTING;
                        data_buffer <= {1'b1, din};
                    end else data_buffer <= 0;
                    baud_counter <= 0;
                    busy <= 0;
                    dout <= 1;
                end
                STARTING: begin
                    if (baud_counter + 1 == BAUD_BIT_PERIOD) begin
                        state <= TRANSMITTING;
                        data_buffer <= data_buffer >> 1;
                        dout <= data_buffer;
                        baud_counter <= 0;
                    end else begin
                        baud_counter <= baud_counter + 1;
                        dout <= 0;
                    end
                    busy <= 1;
                end
                TRANSMITTING: begin
                    if (baud_counter + 1 == BAUD_BIT_PERIOD) begin
                        if (data_buffer == 1) state <= STOPPING;
                        data_buffer <= data_buffer >> 1;
                        dout <= data_buffer;
                        baud_counter <= 0;
                    end else baud_counter <= baud_counter + 1;
                    busy <= 1;
                end
                STOPPING: begin
                    if (baud_counter + 1 == BAUD_BIT_PERIOD) begin
                        state <= IDLE;
                        baud_counter <= 0;
                    end else baud_counter <= baud_counter + 1;
                    busy <= 1;
                    dout <= 1;
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule // uart_transmit

`default_nettype wire