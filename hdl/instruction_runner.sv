`default_nettype none

module get_memory_address (
    input wire [7:0] addressing_mode, 
    input wire [7:0] prev_a, 
    input wire [7:0] prev_x,
    input wire [7:0] prev_y, 
    input wire [15:0] prev_pc, 
    input wire [7:0] prev_s, 
    output logic [7:0] mem_addr
);


endmodule

module get_memory_value (
    input wire [7:0] addressing_mode, 
    input wire [7:0] prev_a, 
    input wire [7:0] prev_x,
    input wire [7:0] prev_y, 
    input wire [15:0] prev_pc, 
    input wire [7:0] prev_s, 
    output logic [7:0] mem_val
);
endmodule

module set_memory_value (
    input wire [7:0] addressing_mode, 
    input wire [7:0] prev_a, 
    input wire [7:0] prev_x,
    input wire [7:0] prev_y, 
    input wire [15:0] prev_pc, 
    input wire [7:0] prev_s, 
    input wire [7:0] new_mem_val
);
endmodule

// instruction reference: https://www.nesdev.org/wiki/Instruction_reference
module instruction_runner (
        input wire clk,
        input wire rst,
        
        input wire [7:0] opcode,
        input wire [7:0] addressing_mode,

        input wire [7:0] prev_a, 
        input wire [7:0] prev_x,
        input wire [7:0] prev_y, 
        input wire [15:0] prev_pc, 
        input wire [7:0] prev_s, 
        input wire prev_c, 
        input wire prev_z, 
        input wire prev_i, 
        input wire prev_d, 
        input wire prev_v, 
        input wire prev_n, 
        input wire prev_b, 
        input wire start_instruction, 

        output logic [7:0] new_a, 
        output logic [7:0] new_x,
        output logic [7:0] new_y, 
        output logic [15:0] new_pc, 
        output logic [7:0] new_s, 
        output logic new_c, 
        output logic new_z, 
        output logic new_i, 
        output logic new_d, 
        output logic prev_v, 
        output logic prev_n, 
        output logic prev_b, 
        output logic instruction_done,
        output logic error,
    );
    // import cpu_instructions::addressing_mode_types;
    // import cpu_instructions::opcode_types;
    typedef enum {
        ZERO_PAGE_X, 
        ZERO_PAGE_Y, 
        ABSOLUTE_X,
        ABSOLUTE_Y, 
        INDEXED_INDIRECT, 
        INDIRECT_INDEXED, 
        ACCUMULATOR, 
        IMMEDIATE, 
        ZERO_PAGE, 
        ABSOLUTE,
        TODO,
        UNSUPPORTED_AM
    } addressing_mode_types; 
    // D = Zero page
    // see https://www.nesdev.org/wiki/CPU_addressing_modes
    // for formulas
    typedef enum {
        ADC, 
        AND, 
        ASL, 
        BCC, 
        BCS, 
        BEQ, 
        BIT, 
        BMI, 
        BNE, 
        BPL, 
        BRK, 
        BVC, 
        BVS, 
        CLC, 
        CLD, 
        CLI, 
        CLV, 
        CMP,
        CPX,
        CPY, 
        DEC, 
        DEX, 
        DEY, 
        EOR, 
        INC, 
        INX, 
        INY, 
        JMP, 
        JSR, 
        LDA, 
        LDX, 
        LDY, 
        LSR, 
        NOP, 
        ORA, 
        PHA, 
        PHP, 
        PLA, 
        PLP, 
        ROL, 
        ROR, 
        RTI, 
        RTS, 
        SBC, 
        SEC, 
        SED, 
        SEI, 
        STA, 
        STX, 
        STY, 
        TAX, 
        TAY, 
        TSX, 
        TXA, 
        TXS, 
        TYA, 
        UNSUPPORTED_OP,
        // TODO: combine with regular?
        JMP_ABS, 
        JSR_ABS
    } opcode_types;

    logic opcode_stored; 
    logic addressing_mode_stored;
    

    always_ff @(posedge clk) begin
        if (rst) begin

        end

        if (start_instruction) begin
            opcode_stored <= opcode;
            addressing_mode_stored <= addressing_mode;
            instruction_done <= 0;
            error <= 0;

            // read memory value and maybe set error if something goes wrong

            // set correct number of cycles based on opcode/addressing mode

            // below we store current reguster values, 
            // possibly override them based on computation (do after memory is ready)


            a <= prev_a; 
            x <= prev_x;
            y <= prev_y; 
            pc <= prev_pc; 
            s <= prev_s;
            c <= prev_c;
            z <= prev_z; 
            i <= prev_i; 
            d <= prev_d; 
            v <= prev_v; 
            n <= prev_n; 
            b <= prev_b;
            case (opcode) 
                ADC: begin
                    result = {1'b0, prev_a} + {1'b0, memory} + prev_c; 
                    a <= result[7:0];
                    c <= result[8];
                    z <= result == 0;
                    v <= ((result ^ prev_a) & (result ^ memory))[7];
                    n <= result[7];
                    
                end
                AND: begin
                    result = prev_a & memory;
                    a <= result[7:0];
                    z <= result == 0;
                    n <= result[7];
                end
                ASL: begin
                    result = memory << 1;
                    // write result[7:0] to memory
                    c <= memory[7];
                    z <= result == 0;
                    n <= result[7];
                end
                BCC: begin
                    if (prev_c == 1'b0) begin
                        pc <= $signed({0, pc}) + $signed(3'b010) + $signed(memory);
                    end
                end
                BCS: begin
                    if (prev_c == 1'b1) begin
                        pc <= $signed({0, pc}) + $signed(3'b010) + $signed(memory);
                    end
                end
                BEQ: begin
                    if (prev_z == 1'b1) begin
                        pc <= $signed({0, pc}) + $signed(3'b010) + $signed(memory);
                    end
                end
                BIT: 
                BMI: 
                BNE: 
                BPL: 
                BRK: 
                BVC: 
                BVS: 
                CLC: 
                CLD: 
                CLI: 
                CLV: 
                CMP:
                CPX:
                CPY: 
                DEC: 
                DEX: 
                DEY: 
                EOR: 
                INC: 
                INX: 
                INY: 
                JMP: 
                JSR: 
                LDA: 
                LDX: 
                LDY: 
                LSR: 
                NOP: 
                ORA: 
                PHA: 
                PHP: 
                PLA: 
                PLP: 
                ROL: 
                ROR: 
                RTI: 
                RTS: 
                SBC: 
                SEC: 
                SED: 
                SEI:
                STA: 
                STX: 
                STY:
                TAX: 
                TAY:
                TSX: 
                TXA: 
                TXS:
                TYA: 
                UNSUPPORTED_OP:
                // TODO: combine with regular?
                JMP_ABS: 
                JSR_ABS:
                default: begin
                    instruction_done <= 1; 
                    error <= 1;
                end

            endcase
        end

    end




endmodule

`default_nettype wire


