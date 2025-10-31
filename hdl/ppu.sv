`default_nettype none
module ppu (
        input wire clk,
        input wire rst,
        input logic [7:0] cpu_dout,
        input logic [15:0] cpu_addr, // from what i'm seeing, in the hardware it's only 3 bits?
        output logic [7:0] cpu_din,
        input cpu_rw
    );
    typedef enum {CPU_WRITE, CPU_READ} cpu_op_type; // Write is 0, read is 1 contrary to what you might think
    logic [7:0] oam_data;
    logic [7:0] ppu_ctrl;
    logic [7:0] ppu_mask;
    logic [7:0] ppu_status;
    logic [7:0] oam_addr;
    logic [15:0] ppu_scroll; // [15:8] X, [7:0] Y
    logic [15:0] ppu_addr;
    logic [7:0] ppu_data;
    logic [7:0] oam_dma; 
    logic w; 
    always_ff @(posedge clk) begin
        if(rst) begin
            // Set all regs to zero?
            oam_data <= 0;
            ppu_ctrl <= 0;
            ppu_mask <= 0;
            ppu_status <= 0;
            oam_addr <= 0;
            ppu_scroll <= 0; 
            ppu_addr <= 0;
            ppu_data <= 0;
            oam_dma <= 0;
        end else begin
            // I think? this is right - ignoring timing ofc
            // TODO: This may only be permitted during blank periods, need to double check
            // and if necessary, only do it during these times
            if(8'h2000 <= addr && addr <= 8'h3FFF) begin
                if(cpu_rw == CPU_WRITE) begin
                    // 16'h4014: oam_dma <= cpu_dout; -> needs to be in separate if statements
                    case (cpu_addr[2:0]) // Changed to be 3 bits but keeping 16 bit input for mirroring
                        3'h0: ppu_ctrl <= cpu_dout;
                        3'h1: ppu_mask <= cpu_dout;
                        3'h3: oam_addr <= cpu_dout;
                        3'h4: oam_data <= cpu_dout;
                        3'h5: begin 
                            if(w) begin
                                ppu_scroll[15:8] <= cpu_dout;
                            end else begin
                                ppu_scroll[7:0] <= cpu_dout;
                            end
                        end // handle later
                        3'h6: begin 
                            if(w) begin
                                ppu_addr[15:8] <= cpu_dout;
                            end else begin
                                ppu_addr[7:0] <= cpu_dout;
                            end
                        end // handle later
                        3'h7: ppu_data <= cpu_dout;
                    endcase
                end
                else begin
                    case (cpu_addr)
                        16'h2002: cpu_din <= ppu_status; // Only [7:5] actually matter, could optimize?
                        16'h2004: cpu_din <= oam_data;
                        16'h2007: cpu_din <= ppu_data;
                    endcase
                end
            end
        end
    end
endmodule

`default_nettype wire



