
module tm_choice (
  input wire [7:0] d,
  output logic [8:0] q_m
  );
  logic[3:0] ones;
  int i = 0;
  always_comb begin
    ones = 0;
    for (i = 0; i < 8; i = i + 1) begin
      if (d[i] == 1'b1) begin
        ones = ones + 1;
      end
    end
    if(ones > 4 | (ones == 4 & !(d & 1'b1))) begin
      q_m[0] = d & 1'b1;
      for (i = 1; i < 8; i = i + 1) begin
        q_m[i] = ~(((q_m >> (i-1)) & 1'b1) ^ ((d >> i) & 1'b1));
      end
      q_m[i] = 0;
    end else begin
      q_m[0] = d & 1'b1;
      for (i = 1; i < 8; i = i + 1) begin
        q_m[i] = (((q_m >> (i-1)) & 1'b1) ^ ((d >> i) & 1'b1));
      end
      q_m[i] = 1;
    end
  end
    

  //your code here, friend



endmodule //end tm_choice
