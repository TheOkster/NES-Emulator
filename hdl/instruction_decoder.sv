`default_nettype none

// define shared enums for addressing mode and opcode
package cpu_instructions; 
    typedef enum {
        DX, 
        DY, 
        AX,
        AY, 
        INDEXED_INDIRECT, 
        INDIRECT_INDEXED, 
        A, 
        IMMEDIATE, 
        D, 
        UNSUPPORTED
    } addressing_mode; 
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
        UNSUPPORTED
    } opcode; 

endpackage


module instruction_decoder (
        input wire clk,
        input wire rst,
        
        input wire [8:0] instruction,

        output logic [5:0] addressing_mode, 
        output logic [5:0] opcode;

        output logic [7:0] dout,
    );
    logic [2:0] aaa;
    logic [2:0] bbb;
    logic [1:0] cc;


endmodule

`default_nettype wire


