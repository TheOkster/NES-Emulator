// `default_nettype none

// // define shared enums for addressing mode and opcode
// package cpu_instructions; 
//     typedef enum {
//         ZERO_PAGE_X, 
//         ZERO_PAGE_Y, 
//         ABSOLUTE_X,
//         ABSOLUTE_Y, 
//         INDEXED_INDIRECT, 
//         INDIRECT_INDEXED, 
//         ACCUMULATOR, 
//         IMMEDIATE, 
//         ZERO_PAGE, 
//         ABSOLUTE,
//         TODO,
//         UNSUPPORTED
//     } addressing_mode; 
//     // D = Zero page
//     // see https://www.nesdev.org/wiki/CPU_addressing_modes
//     // for formulas
//     typedef enum {
//         ADC, 
//         AND, 
//         ASL, 
//         BCC, 
//         BCS, 
//         BEQ, 
//         BIT, 
//         BMI, 
//         BNE, 
//         BPL, 
//         BRK, 
//         BVC, 
//         BVS, 
//         CLC, 
//         CLD, 
//         CLI, 
//         CLV, 
//         CMP,
//         CPX,
//         CPY, 
//         DEC, 
//         DEX, 
//         DEY, 
//         EOR, 
//         INC, 
//         INX, 
//         INY, 
//         JMP, 
//         JSR, 
//         LDA, 
//         LDX, 
//         LDY, 
//         LSR, 
//         NOP, 
//         ORA, 
//         PHA, 
//         PHP, 
//         PLA, 
//         PLP, 
//         ROL, 
//         ROR, 
//         RTI, 
//         RTS, 
//         SBC, 
//         SEC, 
//         SED, 
//         SEI, 
//         STA, 
//         STX, 
//         STY, 
//         TAX, 
//         TAY, 
//         TSX, 
//         TXA, 
//         TXS, 
//         TYA, 
//         UNSUPPORTED
//     } opcode; 

// endpackage

// // decoding reference: https://llx.com/Neil/a2/opcodes.html
// module instruction_decoder (
//         input wire clk,
//         input wire rst,
        
//         input wire [7:0] instruction,

//         output logic [6:0] addressing_mode, 
//         output logic [6:0] opcode;

//         output logic [7:0] dout,
//     );
//     logic [2:0] aaa;
//     logic [2:0] bbb;
//     logic [1:0] cc;

//     assign aaa = instruction[7:5];
//     assign bbb = instruction[4:2];
//     assign cc = instruction[1:0];

//     always_comb begin
//         case(cc)
//             2'b00: begin

//             end
//             2'b01: begin
//                 // decode opcode
//                 case(aaa) 
//                     3'b000: opcode <= ORA; 
//                     3'b001: opcode <= AND;
//                     3'b010: opcode <= EOR;
//                     3'b011: opcode <= ADC; 
//                     3'b100: opcode <= STA;
//                     3'b101: opcode <= LDA;
//                     3'b110: opcode <= CMP;
//                     3'b111: opcode <= SBC;
//                     default: opcode <= UNSUPPORTED;
//                 endcase

//                 // decode addressing mode
//                 case(bbb) 
//                     3'b000: addressing_mode <= INDEXED_INDIRECT; 
//                     3'b001: addressing_mode <= ZERO_PAGE;
//                     3'b010: begin
//                         if (aaa == 3'b100) addressing_mode <= UNSUPPORTED;
//                         else addressing_mode <= IMMEDIATE;
//                     end 
//                     3'b011: addressing_mode <= ABSOLUTE; 
//                     3'b100: addressing_mode <= INDIRECT_INDEXED;
//                     3'b101: addressing_mode <= ZERO_PAGE_X;
//                     3'b110: addressing_mode <= ABSOLUTE_Y;
//                     3'b111: addressing_mode <= ABSOLUTE_X;
//                     default: addressing_mode <= UNSUPPORTED;
//                 endcase
//             end
//             2'b10: begin
//                 // decode opcode
//                 case(aaa) 
//                     3'b000: opcode <= ASL; 
//                     3'b001: opcode <= ROL;
//                     3'b010: opcode <= LSR;
//                     3'b011: opcode <= ROR; 
//                     3'b100: opcode <= STX;
//                     3'b101: opcode <= LDX;
//                     3'b110: opcode <= DEC;
//                     3'b111: opcode <= INC;
//                     default: opcode <= UNSUPPORTED;
//                 endcase

//                 // decode addressing mode
//                 case(bbb) 
//                     3'b000: begin
//                         if (aaa == 3'b101) addressing_mode <= IMMEDIATE; 
//                         else addressing_mode <= UNSUPPORTED;
//                     end
//                     3'b001: addressing_mode <= ZERO_PAGE;
//                     3'b010: begin
//                         if (aaa[2] == 0'b0) addressing_mode <= ACCUMULATOR;
//                         else addressing_mode <= UNSUPPORTED;
//                     end
//                     3'b011: addressing_mode <= ABSOLUTE; 
//                     3'b101: begin
//                         if ((aaa == 3'b100) || (aaa == 3'b101)) addressing_mode <= ZERO_PAGE_Y;
//                         else addressing_mode <= ZERO_PAGE_X;
//                     end
//                     3'b111: 
//                         if (aaa == 3'b100) addressing_mode <= UNSUPPORTED;
//                         else if (aaa == 3'b101) addressing_mode <= ABSOLUTE_Y;
//                         else addressing_mode <= ABSOLUTE_X;
//                     default: addressing_mode <= UNSUPPORTED;
//                 endcase
//             end
//             2'b11: begin
//                 opcode <= UNSUPPORTED; 
//                 addressing_mode <= UNSUPPORTED;
//             end
//         endcase

//     end


    


// endmodule

// `default_nettype wire


