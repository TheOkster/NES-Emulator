`default_nettype none
module ppu_reg_interface (
        input wire clk,
        input logic ppu_clk_trig,
        input wire rst,
        input logic cpu_rw,
        input logic [7:0] cpu_dout,
        output logic [7:0] cpu_din,
        output logic [15:0] cpu_addr, 
        output logic [15:0] ppu_addr,
        output logic [7:0] ppu_data,
        output logic [7:0] ppu_ctrl,
        output logic [15:0] ppu_scroll,
        output logic [7:0] ppu_mask,
        output logic [7:0] ppu_status,
        output logic [7:0] oam_addr,
        output logic [7:0] oam_data
    );
        logic [7:0] ppu_data_buffer;
    logic[4:0] actual_read_addr;
   typedef enum {CPU_WRITE, CPU_READ} cpu_op_type; // Write is 0, read is 1 contrary to what you might think
         logic w;
         logic [23:0] sys_palette [0:63]; // since this is small, i'm just using registers
         logic [7:0] palette_ram [0:31]; // same thing also small
         logic vblank_flag;
         logic sprite_overflow_flag;
         logic sprite_0_hit_flag;
         assign ppu_status[7:5] = {vblank_flag, sprite_overflow_flag, sprite_0_hit_flag};
      initial begin
         $readmemh("../data/2C07.mem", sys_palette);
         $dumpfile("ppu.fst");
         // for (int i = 0; i < 64; i = i + 1)
         //     $dumpvars(0, palette_ram[i]);
      end

   always_ff @(posedge clk) begin
      if(rst) begin
         oam_data <= 0;
         ppu_ctrl <= 0;
         ppu_mask <= 0;
         ppu_status[4:0] <= 0;
         vblank_flag <= 0;
         sprite_overflow_flag <= 0;
         sprite_0_hit_flag <= 0;
         oam_addr <= 0;
         ppu_scroll <= 0; 
         ppu_addr <= 0;
         ppu_data <= 0;
      end else begin
            if(16'h2000 <= cpu_addr && cpu_addr <= 16'h3FFF) begin
                  if(cpu_rw == CPU_WRITE) begin
                     case (cpu_addr[2:0]) // Changed to be 3 bits but keeping 16 bit input for mirroring
                           3'h0: ppu_ctrl <= cpu_dout;
                           3'h1: ppu_mask <= cpu_dout;
                           3'h3: oam_addr <= cpu_dout;
                           3'h4: oam_data <= cpu_dout;
                           3'h5: begin 
                              if(w) begin
                                 ppu_scroll[15:8] <= cpu_dout;
                                 w <= 0;
                              end else begin
                                 ppu_scroll[7:0] <= cpu_dout;
                                 w <=1;
                              end
                           end // handle later
                           3'h6: begin 
                              if(w) begin
                                 ppu_addr[7:0] <= cpu_dout;
                                 w <= 0;
                              end else begin
                                 ppu_addr[15:8] <= cpu_dout;
                                 w <= 1;
                              end
                           end // handle later
                           3'h7: begin
                              if(ppu_addr < 16'h3F00) begin
                                 // Regular Case
                                 // TODO: Implement
                              end else begin
                                 case(ppu_addr[4:0])
                                       5'h10: actual_read_addr = 5'h0;
                                       5'h14: actual_read_addr = 5'h4;
                                       5'h18: actual_read_addr = 5'h8;
                                       5'h1C: actual_read_addr = 5'hC;
                                       default: actual_read_addr = ppu_addr[4:0];
                                 endcase
                                 palette_ram[actual_read_addr] <= cpu_din;
                              end
                              ppu_addr <= ppu_addr + 1;
                           end
                     endcase
                  end
                  else begin
                     case (cpu_addr)
                           16'h2002: begin 
                              cpu_din <= {ppu_status[7:5], ppu_data_buffer[4:0]};
                              w <= 0;
                              vblank_flag <= 0;
                           end
                           16'h2004: cpu_din <= oam_data;
                           16'h2007: begin 
                              if(ppu_addr < 16'h3F00) begin
                                 // Regular Case
                                 // TODO: Implement
                                 ppu_data <= ppu_data_buffer;
                              end else begin
                                 case(ppu_addr[4:0])
                                       5'h10: actual_read_addr = 5'h0;
                                       5'h14: actual_read_addr = 5'h4;
                                       5'h18: actual_read_addr = 5'h8;
                                       5'h1C: actual_read_addr = 5'hC;
                                       default: actual_read_addr = ppu_addr[4:0];
                                 endcase
                                 ppu_data <= palette_ram[actual_read_addr];
                                 ppu_data_buffer <=   palette_ram[actual_read_addr];
                              end
                              ppu_addr <= ppu_addr + 1;
                           end
                     endcase

                  end    
               end
      end
   end
endmodule