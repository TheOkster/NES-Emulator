`default_nettype none
module ppu (
        input wire clk,
        input wire rst,
        input logic [7:0] cpu_dout,
        input logic [15:0] cpu_addr, // from what i'm seeing, in the hardware it's only 3 bits?
        output logic [7:0] cpu_din,
        output logic [23:0] pixel, // 8 : 8 : 8 for now, might change to be 5 : 6 : 5?
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
    logic w; // not working yet
    logic[4:0] cycle;
    logic ppu_clk_trig;
    logic first_time;
    logic [23:0] sys_palette [0:63]; // since this is small, i'm just using registers
    logic[8:0] dot;
    logic[8:0] scanline_p1; // This is the scanline plus 1 to avoid signed numbers issues, will change name / function
    localparam PPU_CYCLES_PER_CLOCK_CYCLE = 19; // This is not correct but closest integer multiplier
    // in the future, may want to use some input signal that runs at exactly PPU clock speed


    // Gets System Palette


    initial begin
        $readmemh("../data/2C07.mem", sys_palette);
        $dumpfile("ppu.fst");
        for (int i = 0; i < 64; i = i + 1)
            $dumpvars(0, palette_ram[i]);
    end
   
    assign ppu_clk_trig = (cycle == 0);
    always_ff @(posedge clk) begin
        if(rst) begin
            oam_data <= 0;
            ppu_ctrl <= 0;
            ppu_mask <= 0;
            ppu_status <= 0;
            oam_addr <= 0;
            ppu_scroll <= 0; 
            ppu_addr <= 0;
            ppu_data <= 0;
            oam_dma <= 0;
            cycle <= 0;
            first_time <= 1;
            dot <= 0;
            scanline_p1 <= 1;
        end else begin
            first_time <= 0;
            cycle <= (cycle == PPU_CYCLES_PER_CLOCK_CYCLE - 1) ? 0 : (cycle + 1);

            // TODO Add Test Cases for timing
            // verify there are no off by one errors
            if(ppu_clk_trig & !first_time) begin
                if(dot >= 341) begin
                    dot <= 0;
                    scanline_p1 <= (scanline_p1 == 261) ? 0 : scanline_p1 + 1;
                    // need trigger to show that frame is complete
                end else begin
                    dot <= dot + 1;
                end
            end
            // TODO: This may only be permitted during blank periods, need to double check
            // and if necessary, only do it during these times
            if(16'h2000 <= cpu_addr && cpu_addr <= 16'h3FFF) begin
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



