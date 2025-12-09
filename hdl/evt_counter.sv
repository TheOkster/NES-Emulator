`default_nettype none
module evt_counter
    #(
        parameter MAX_COUNT = 1'b1111_1111_1111_1111
    )
    (   input wire          clk,
        input wire          rst,
        input wire          evt,
        output logic[15:0]  count
    );
    
    always_ff @(posedge clk) begin
        if (rst) begin
            count <= 16'b0;
        end else begin
            if (evt) begin
                count <= count == MAX_COUNT ? 0 : count + 1;
            end
        end
    end
endmodule
`default_nettype wire