module pwm(   input wire clk,
              input wire rst,
              input wire [7:0] dc_in,
              output logic sig_out);
 
    logic [31:0] count;
    logic [7:0] current_dc_in;

    counter mc (.clk(clk),
                .rst(rst),
                .period(255),
                .count(count));

    always_ff @(posedge clk) begin
        if (count == 0) begin
            current_dc_in <= dc_in;
        end
    end
    
    assign sig_out = count<current_dc_in; //very simple threshold check
endmodule

module counter(     input wire clk,
                    input wire rst,
                    input wire [31:0] period,
                    output logic [31:0] count
              );

  always_ff @(posedge clk) begin
    if (rst == 1 || count >= period - 1) begin
      count <= 0;
    end else begin
      count <= count + 1;
    end
  end
endmodule
