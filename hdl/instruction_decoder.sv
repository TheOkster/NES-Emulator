// `default_nettype none

// // define shared enums for addressing mode and opcode
// // package cpu_instructions; 
// //     typedef enum {
// //         ZERO_PAGE_X, 
// //         ZERO_PAGE_Y, 
// //         ABSOLUTE_X,
// //         ABSOLUTE_Y, 
// //         INDEXED_INDIRECT, 
// //         INDIRECT_INDEXED, 
// //         ACCUMULATOR, 
// //         IMMEDIATE, 
// //         ZERO_PAGE, 
// //         ABSOLUTE,
// //         TODO,
// //         UNSUPPORTED_AM
// //     } addressing_mode_types; 
// //     // D = Zero page
// //     // see https://www.nesdev.org/wiki/CPU_addressing_modes
// //     // for formulas
// //     typedef enum {
// //         ADC, 
// //         AND, 
// //         ASL, 
// //         BCC, 
// //         BCS, 
// //         BEQ, 
// //         BIT, 
// //         BMI, 
// //         BNE, 
// //         BPL, 
// //         BRK, 
// //         BVC, 
// //         BVS, 
// //         CLC, 
// //         CLD, 
// //         CLI, 
// //         CLV, 
// //         CMP,
// //         CPX,
// //         CPY, 
// //         DEC, 
// //         DEX, 
// //         DEY, 
// //         EOR, 
// //         INC, 
// //         INX, 
// //         INY, 
// //         JMP, 
// //         JSR, 
// //         LDA, 
// //         LDX, 
// //         LDY, 
// //         LSR, 
// //         NOP, 
// //         ORA, 
// //         PHA, 
// //         PHP, 
// //         PLA, 
// //         PLP, 
// //         ROL, 
// //         ROR, 
// //         RTI, 
// //         RTS, 
// //         SBC, 
// //         SEC, 
// //         SED, 
// //         SEI, 
// //         STA, 
// //         STX, 
// //         STY, 
// //         TAX, 
// //         TAY, 
// //         TSX, 
// //         TXA, 
// //         TXS, 
// //         TYA, 
// //         UNSUPPORTED_OP
// //     } opcode_types; 

// // endpackage

// // decoding reference: https://llx.com/Neil/a2/opcodes.html
// module instruction_decoder (
//         input wire clk,
//         input wire rst,
        
//         input wire [7:0] instruction,

//         output logic [6:0] addressing_mode, 
//         output logic [6:0] opcode,

//         output logic [7:0] dout
//     );
//     // import cpu_instructions::addressing_mode_types;
//     // import cpu_instructions::opcode_types;
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
//         UNSUPPORTED_AM
//     } addressing_mode_types; 
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
//         UNSUPPORTED_OP,
//         // TODO: combine with regular?
//         JMP_ABS, 
//         JSR_ABS
//     } opcode_types;

//     logic [2:0] aaa;
//     logic [2:0] bbb;
//     logic [1:0] cc;

//     assign aaa = instruction[7:5];
//     assign bbb = instruction[4:2];
//     assign cc = instruction[1:0];

//     always_comb begin
//         case(cc)
//             2'b00: begin
//                 case(aaa) 
//                     3'b001: opcode = BIT;
//                     3'b010: opcode = JMP;
//                     3'b011: opcode = JMP_ABS; 
//                     3'b100: opcode = STY;
//                     3'b101: opcode = LDY;
//                     3'b110: opcode = CPY;
//                     3'b111: opcode = CPX;
//                     default: opcode = UNSUPPORTED_OP;
//                 endcase

//                 // decode addressing mode
//                 case(bbb) 
//                     3'b000: begin
//                         case(aaa)
//                             3'b000: begin
//                                 opcode = BRK;
//                                 addressing_mode = TODO;
//                             end
//                             3'b001: begin
//                                 opcode = JSR_ABS;
//                                 addressing_mode = ABSOLUTE;
//                             end
//                             3'b010: begin
//                                 opcode = RTI;
//                                 addressing_mode = TODO;
//                             end
//                             3'b011: begin
//                                 opcode = RTS;
//                                 addressing_mode = TODO;
//                             end
//                             default: addressing_mode = IMMEDIATE;
//                         endcase
//                     end
//                     3'b010: begin
//                         case (aaa) 
//                             3'b000: begin
//                                 opcode = PHP;
//                                 addressing_mode = TODO;
//                             end
//                             3'b001: begin
//                                 opcode = PLP;
//                                 addressing_mode = TODO;
//                             end
//                             3'b010: begin
//                                 opcode = PHA;
//                                 addressing_mode = TODO;
//                             end
//                             3'b011: begin
//                                 opcode = PLA;
//                                 addressing_mode = TODO;
//                             end
//                             3'b100: begin
//                                 opcode = DEY;
//                                 addressing_mode = TODO;
//                             end
//                             3'b101: begin
//                                 opcode = TAY;
//                                 addressing_mode = TODO;
//                             end
//                             3'b110: begin
//                                 opcode = INY;
//                                 addressing_mode = TODO;
//                             end
//                             3'b111: begin
//                                 opcode = INX;
//                                 addressing_mode = TODO;
//                             end
//                         endcase
//                     end
//                     3'b001: begin
//                         if ((aaa == 3'b010) || (aaa == 3'b011)) begin
//                             opcode = UNSUPPORTED_OP;
//                             addressing_mode = UNSUPPORTED_AM;
//                         end
//                         else addressing_mode = ZERO_PAGE;
//                     end
//                     3'b101: begin
//                          if ((aaa == 3'b100) || (aaa == 3'b101)) addressing_mode = ZERO_PAGE_X; 
//                         else begin
//                             opcode = UNSUPPORTED_OP;
//                             addressing_mode = UNSUPPORTED_AM;
//                         end
//                     end
//                     3'b100: begin
//                         // conditional branch, override opcode
//                         addressing_mode = TODO;
//                         case (aaa) 
//                             3'b000: opcode = BPL; 
//                             3'b001: opcode = BMI;
//                             3'b010: opcode = BVC;
//                             3'b011: opcode = BVS; 
//                             3'b100: opcode = BCC;
//                             3'b101: opcode = BCS;
//                             3'b110: opcode = BNE;
//                             3'b111: opcode = BEQ;
//                             default: opcode = UNSUPPORTED_OP;

//                         endcase

//                     end
//                     3'b110: begin
//                         case (aaa) 
//                             3'b000: begin
//                                 opcode = CLC;
//                                 addressing_mode = TODO;
//                             end
//                             3'b001: begin
//                                 opcode = SEC;
//                                 addressing_mode = TODO;
//                             end
//                             3'b010: begin
//                                 opcode = CLI;
//                                 addressing_mode = TODO;
//                             end
//                             3'b011: begin
//                                 opcode = SEI;
//                                 addressing_mode = TODO;
//                             end
//                             3'b100: begin
//                                 opcode = TYA;
//                                 addressing_mode = TODO;
//                             end
//                             3'b101: begin
//                                 opcode = CLV;
//                                 addressing_mode = TODO;
//                             end
//                             3'b110: begin
//                                 opcode = CLD;
//                                 addressing_mode = TODO;
//                             end
//                             3'b111: begin
//                                 opcode = SED;
//                                 addressing_mode = TODO;
//                             end
//                         endcase
//                     end
//                     3'b111: begin
//                         if (aaa == 3'b101) addressing_mode = ABSOLUTE_X;
//                         else begin
//                             opcode = UNSUPPORTED_OP;
//                             addressing_mode = UNSUPPORTED_AM;
//                         end
//                     end
//                     default: begin
//                         opcode = UNSUPPORTED_OP;
//                         addressing_mode = UNSUPPORTED_AM;
//                     end
//                 endcase

//             end
//             2'b01: begin
//                 // decode opcode
//                 case(aaa) 
//                     3'b000: opcode = ORA; 
//                     3'b001: opcode = AND;
//                     3'b010: opcode = EOR;
//                     3'b011: opcode = ADC; 
//                     3'b100: opcode = STA;
//                     3'b101: opcode = LDA;
//                     3'b110: opcode = CMP;
//                     3'b111: opcode = SBC;
//                     default: opcode = UNSUPPORTED_OP;
//                 endcase

//                 // decode addressing mode
//                 case(bbb) 
//                     3'b000: addressing_mode = INDEXED_INDIRECT; 
//                     3'b001: addressing_mode = ZERO_PAGE;
//                     3'b010: begin
//                         if (aaa == 3'b100) begin
//                             opcode = UNSUPPORTED_OP;
//                             addressing_mode = UNSUPPORTED_AM;
//                         end
//                         else addressing_mode = IMMEDIATE;
//                     end 
//                     3'b011: addressing_mode = ABSOLUTE; 
//                     3'b100: addressing_mode = INDIRECT_INDEXED;
//                     3'b101: addressing_mode = ZERO_PAGE_X;
//                     3'b110: addressing_mode = ABSOLUTE_Y;
//                     3'b111: addressing_mode = ABSOLUTE_X;
//                     default: begin
//                         opcode = UNSUPPORTED_OP;
//                         addressing_mode = UNSUPPORTED_AM;
//                     end
//                 endcase
//             end
//             2'b10: begin
//                 // decode opcode
//                 case(aaa) 
//                     3'b000: opcode = ASL; 
//                     3'b001: opcode = ROL;
//                     3'b010: opcode = LSR;
//                     3'b011: opcode = ROR; 
//                     3'b100: opcode = STX;
//                     3'b101: opcode = LDX;
//                     3'b110: opcode = DEC;
//                     3'b111: opcode = INC;
//                     default: opcode = UNSUPPORTED_OP;
//                 endcase

//                 // decode addressing mode
//                 case(bbb) 
//                     3'b000: begin
//                         if (aaa == 3'b101) addressing_mode = IMMEDIATE; 
//                         else begin
//                             opcode = UNSUPPORTED_OP;
//                             addressing_mode = UNSUPPORTED_AM;
//                         end
//                     end
//                     3'b001: addressing_mode = ZERO_PAGE;
//                     3'b010: begin
//                         case(aaa)
//                             3'b000: begin
//                                 opcode = TXA;
//                                 addressing_mode = TODO;
//                             end
//                             3'b001: begin
//                                 opcode = TAX;
//                                 addressing_mode = TODO;
//                             end
//                             3'b010: begin
//                                 opcode = DEX;
//                                 addressing_mode = TODO;
//                             end
//                             3'b011: begin
//                                 opcode = NOP;
//                                 addressing_mode = TODO;
//                             end
//                             default: addressing_mode = ACCUMULATOR;
//                         endcase
//                     end
//                     3'b011: addressing_mode = ABSOLUTE; 
//                     3'b101: begin
//                         if ((aaa == 3'b100) || (aaa == 3'b101)) addressing_mode = ZERO_PAGE_Y;
//                         else addressing_mode = ZERO_PAGE_X;
//                     end
//                     3'b110: begin
//                         case(aaa)
//                             3'b100: begin
//                                     opcode = TXS;
//                                     addressing_mode = TODO;
//                                 end
//                             3'b101:begin
//                                     opcode = TSX;
//                                     addressing_mode = TODO;
//                                 end
//                             default: begin
//                                     opcode = UNSUPPORTED_OP;
//                                     addressing_mode = UNSUPPORTED_AM;
//                                 end
//                         endcase
//                     end
//                     3'b111: 
//                         if (aaa == 3'b100) begin
//                             opcode = UNSUPPORTED_OP;
//                             addressing_mode = UNSUPPORTED_AM;
//                         end
//                         else if (aaa == 3'b101) addressing_mode = ABSOLUTE_Y;
//                         else addressing_mode = ABSOLUTE_X;
//                     default: begin
//                         opcode = UNSUPPORTED_OP;
//                         addressing_mode = UNSUPPORTED_AM;
//                     end
//                 endcase
//             end
//             2'b11: begin
//                 opcode = UNSUPPORTED_OP; 
//                 addressing_mode = UNSUPPORTED_AM;
//             end
//         endcase

//     end


    


// endmodule

// `default_nettype wire

