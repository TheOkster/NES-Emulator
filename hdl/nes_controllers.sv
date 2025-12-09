`timescale 1ns / 1ps
`default_nettype none

module nes_controllers (
        input wire sys_clk,
        input wire rst,

        input wire uart_rx,

        input wire [7:0] cpu_dout,
        input wire [15:0] cpu_addr,
        output logic [7:0] cpu_din,
        output logic cpu_din_valid,
        input wire cpu_rw
    );

    logic [7:0] controller_out [1:0];
    logic [7:0] controller_data_buf;
    logic controller_to_write;
    logic controller_data_valid;

    uart_receive #(
        .BAUD_RATE(115200)
    ) controller_data_receiver (
        .clk(sys_clk),
        .rst(rst),
        .din(uart_rx),
        .dout_valid(controller_data_valid),
        .dout(controller_data_buf)
    );

    always_ff (@posedge sys_clk) begin
        if (controller_data_valid) begin
            controller_to_write <= !controller_to_write;
            controller_out[controller_to_write] <= controller_data_buf;
        end
    end

    // CONTROLLER 1 = 0x4016
    // CONTROLLER 2 = 0x4017

    logic [7:0] controller_data;

    always_ff @ (posedge nes_clk) begin
        if (16'h4016 <= addr && addr <= 16'h4017) begin
            if (cpu_rw) begin
                controller_data <= controller_out >> 1;
                cpu_din <= {controller_out[0][0], 7'h00};
                cpu_din_valid <= 1;
            end else begin
                controller_data <= controller_data >> 1;
                cpu_din <= {controller_data[0], 7'h00};
                cpu_din_valid <= 1;
            end
        end	else cpu_din_valid <= 0;
    end

endmodule


`default_nettype wire



