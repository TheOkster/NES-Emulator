module spi_con
     #(parameter DATA_WIDTH = 8,
       parameter DATA_CLK_PERIOD = 100
      )
    (   input wire   clk, //system clock (100 MHz)
        input wire   rst, //reset in signal
        input wire   [DATA_WIDTH-1:0] data_in, //data to send
        input wire   trigger, //start a transaction
        output logic [DATA_WIDTH-1:0] data_out, //data received!
        output logic data_valid, //high when output data is present.
 
        output logic copi, //(Controller-Out-Peripheral-In)
        input wire   cipo, //(Controller-In-Peripheral-Out)
        output logic dclk, //(Data Clock)
        output logic cs // (Chip Select)
 
      );
  
  logic [$clog2(DATA_WIDTH-1):0] bit_counter;
  logic [$clog2((DATA_CLK_PERIOD/2)*2-1):0] bit_dur_counter;

  logic [DATA_WIDTH-1:0] data_buffer_from_chip;
  logic [DATA_WIDTH-1:0] data_buffer_to_chip;

  always_ff @(posedge clk) begin
    if (rst) begin
        cs <= 1;
        dclk <= 0;
        bit_counter <= 0;
        bit_dur_counter <= 0;
        data_valid <= 0;
        data_out <= 0;
        copi <= 0;
    end else if (trigger) begin
        data_buffer_to_chip <= data_in;
        data_buffer_from_chip <= 0;
        cs <= 0;
        dclk <= 0;
        bit_counter <= 0;
        bit_dur_counter <= 0;
        data_valid <= 0;
        copi <= data_in[DATA_WIDTH - 1];
    end else if (!cs) begin
        if (bit_dur_counter == (DATA_CLK_PERIOD/2)*2 - 1) begin
            bit_dur_counter <= 0;

            if (bit_counter == DATA_WIDTH - 1) begin
                data_out <= data_buffer_from_chip;
                data_valid <= 1;
                cs <= 1;
            end else begin
                bit_counter <= bit_counter + 1;
            end
        end else begin
            bit_dur_counter <= bit_dur_counter + 1;
        end

        if (bit_dur_counter == DATA_CLK_PERIOD/2 - 1) begin
            dclk <= 1;
            data_buffer_from_chip <= (data_buffer_from_chip << 1) | cipo;
        end else if (bit_dur_counter == (DATA_CLK_PERIOD/2)*2 - 1) begin
            dclk <= 0;
        end else if (bit_dur_counter == 0) begin
            copi <= (data_buffer_to_chip << bit_counter) >> (DATA_WIDTH - 1) & 1;
        end

        // end
    end else begin
        dclk <= 0;
        data_valid <= 0;
    end
  end

endmodule