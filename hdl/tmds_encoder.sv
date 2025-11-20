`timescale 1ns / 1ps
`default_nettype none
 
module tmds_encoder(
        input wire clk,
        input wire rst,
        input wire [7:0] video_data,  // video data (red, green or blue)
        input wire [1:0] control,   //for blue set to {vs,hs}, else will be 0
        input wire video_enable,    //choose between control (0) or video (1)
        output logic [9:0] tmds
    );
   logic [8:0] q_m;
   logic [4:0] tally;
   logic [4:0] curNetOnes;
   int i = 0;
   tm_choice mtm(
      .d(video_data),
      .q_m(q_m)
   );
   always_comb begin
      curNetOnes = 0;
      for (i = 0; i < 8; i = i + 1) begin
         curNetOnes = (q_m[i]) ? curNetOnes + 1 : curNetOnes - 1;
      end
   end
   always_ff @(posedge clk) begin
         if(rst) begin
            tmds <= 0;
            tally <= 0;
         end else if (!video_enable) begin
            case(control)
               2'b00: tmds <= 10'b1101010100;
               2'b01: tmds <= 10'b0010101011;
               2'b10: tmds <= 10'b0101010100;
               2'b11: tmds <= 10'b1010101011;
            endcase
            tally <= 0;
         end else begin
            if(!tally | !curNetOnes) begin
               tmds[9] <= ~(q_m >> 8);
               tmds[8]<= q_m >> 8;
               tmds[7:0] <= (q_m >> 8) ? q_m[7:0] : ~q_m[7:0];
               tally <= (q_m >> 8) ? tally + curNetOnes : tally - curNetOnes;
            end else begin
               if((!tally[4] & !curNetOnes[4]) | (tally[4] & curNetOnes[4])) begin
                  tmds[9] <= 1;
                  tmds[8] <= q_m[8];
                  tmds[7:0] <= ~q_m[7:0];
                  tally <= tally + 2 * q_m[8] - curNetOnes;
               end else begin
                  tmds[9] <= 0;
                  tmds[8] <= q_m[8];
                  tmds[7:0] <= q_m[7:0];
                  tally <= tally - 2 * (~q_m[8] & 1'b1) + curNetOnes;
               end
            end
         end
  end
endmodule
`default_nettype wire