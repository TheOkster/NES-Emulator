`default_nettype none
module cpu (
        input wire clk_slow,
        input wire clk_fast,
        input wire rst,

        output logic [7:0] dout,
        output logic [15:0] addr,
        input wire [7:0] din,
        input wire din_valid,
        output logic rw,

        input wire irq,
        input wire nmi,

        output logic [1:0] audio_out // putting in here for future expansion
    );

    //  registers and flags
        logic [7:0] a; 
        logic [7:0] x;
        logic [7:0] y; 
        logic [15:0] pc; 
        logic [7:0] s;
        logic c;
        logic z; 
        logic i; 
        logic d; 
        logic v; 
        logic n; 
        logic b; 
        logic instruction_done;
        logic error;
        logic [8:0] result; // intermediate computation result 
        // - extra bit for signed arithmetic/carry bit

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

    typedef enum {
       REQUESTED_INSTRUCTION, 
       INSTRUCTION_RECEIVED, 
       REQUESTED_MEM,
       MEM_VAL_RECEIVED, 
       SIMULATE_INSTRUCTION, 
       MEM_WRITTEN,
       REST, 
       ERROR
    } state_enum; 


   
    // changes based on addressing mode

    logic [5:0] count;
    logic [5:0] estimated_cycles;


    logic instruction_received; 
    logic [2:0] instruction_request_count; 
    logic [7:0] instruction; // opcode/addressing mode
    logic [7:0] instruction_arg; // arg 
    logic [7:0] instruction_arg2;

    logic mem_received; 
    logic [7:0] memory;

    logic [7:0] intermediate_mem1;
    logic [7:0] intermediate_mem2;

    logic [5:0] state;





    logic [7:0] opcode;
    logic [7:0] addressing_mode;
    logic [7:0] opcode_stored;
    logic [7:0] addressing_mode_stored; 

    logic [2:0] aaa;
    logic [2:0] bbb;
    logic [1:0] cc;

    assign aaa = instruction[7:5];
    assign bbb = instruction[4:2];
    assign cc = instruction[1:0];

    logic [7:0] temp1;


    always_comb begin
        case(cc)
            2'b00: begin
                case(aaa) 
                    3'b001: opcode = BIT;
                    3'b010: opcode = JMP;
                    3'b011: opcode = JMP_ABS; 
                    3'b100: opcode = STY;
                    3'b101: opcode = LDY;
                    3'b110: opcode = CPY;
                    3'b111: opcode = CPX;
                    default: opcode = UNSUPPORTED_OP;
                endcase

                // decode addressing mode
                case(bbb) 
                    3'b000: begin
                        case(aaa)
                            3'b000: begin
                                opcode = BRK;
                                addressing_mode = TODO;
                            end
                            3'b001: begin
                                opcode = JSR_ABS;
                                addressing_mode = ABSOLUTE;
                            end
                            3'b010: begin
                                opcode = RTI;
                                addressing_mode = TODO;
                            end
                            3'b011: begin
                                opcode = RTS;
                                addressing_mode = TODO;
                            end
                            default: addressing_mode = IMMEDIATE;
                        endcase
                    end
                    3'b010: begin
                        case (aaa) 
                            3'b000: begin
                                opcode = PHP;
                                addressing_mode = TODO;
                            end
                            3'b001: begin
                                opcode = PLP;
                                addressing_mode = TODO;
                            end
                            3'b010: begin
                                opcode = PHA;
                                addressing_mode = TODO;
                            end
                            3'b011: begin
                                opcode = PLA;
                                addressing_mode = TODO;
                            end
                            3'b100: begin
                                opcode = DEY;
                                addressing_mode = TODO;
                            end
                            3'b101: begin
                                opcode = TAY;
                                addressing_mode = TODO;
                            end
                            3'b110: begin
                                opcode = INY;
                                addressing_mode = TODO;
                            end
                            3'b111: begin
                                opcode = INX;
                                addressing_mode = TODO;
                            end
                        endcase
                    end
                    3'b001: begin
                        if ((aaa == 3'b010) || (aaa == 3'b011)) begin
                            opcode = UNSUPPORTED_OP;
                            addressing_mode = UNSUPPORTED_AM;
                        end
                        else addressing_mode = ZERO_PAGE;
                    end
                    3'b101: begin
                         if ((aaa == 3'b100) || (aaa == 3'b101)) addressing_mode = ZERO_PAGE_X; 
                        else begin
                            opcode = UNSUPPORTED_OP;
                            addressing_mode = UNSUPPORTED_AM;
                        end
                    end
                    3'b100: begin
                        // conditional branch, override opcode
                        addressing_mode = TODO;
                        case (aaa) 
                            3'b000: opcode = BPL; 
                            3'b001: opcode = BMI;
                            3'b010: opcode = BVC;
                            3'b011: opcode = BVS; 
                            3'b100: opcode = BCC;
                            3'b101: opcode = BCS;
                            3'b110: opcode = BNE;
                            3'b111: opcode = BEQ;
                            default: opcode = UNSUPPORTED_OP;

                        endcase

                    end
                    3'b110: begin
                        case (aaa) 
                            3'b000: begin
                                opcode = CLC;
                                addressing_mode = TODO;
                            end
                            3'b001: begin
                                opcode = SEC;
                                addressing_mode = TODO;
                            end
                            3'b010: begin
                                opcode = CLI;
                                addressing_mode = TODO;
                            end
                            3'b011: begin
                                opcode = SEI;
                                addressing_mode = TODO;
                            end
                            3'b100: begin
                                opcode = TYA;
                                addressing_mode = TODO;
                            end
                            3'b101: begin
                                opcode = CLV;
                                addressing_mode = TODO;
                            end
                            3'b110: begin
                                opcode = CLD;
                                addressing_mode = TODO;
                            end
                            3'b111: begin
                                opcode = SED;
                                addressing_mode = TODO;
                            end
                        endcase
                    end
                    3'b111: begin
                        if (aaa == 3'b101) addressing_mode = ABSOLUTE_X;
                        else begin
                            opcode = UNSUPPORTED_OP;
                            addressing_mode = UNSUPPORTED_AM;
                        end
                    end
                    default: begin
                        opcode = UNSUPPORTED_OP;
                        addressing_mode = UNSUPPORTED_AM;
                    end
                endcase

            end
            2'b01: begin
                // decode opcode
                case(aaa) 
                    3'b000: opcode = ORA; 
                    3'b001: opcode = AND;
                    3'b010: opcode = EOR;
                    3'b011: opcode = ADC; 
                    3'b100: opcode = STA;
                    3'b101: opcode = LDA;
                    3'b110: opcode = CMP;
                    3'b111: opcode = SBC;
                    default: opcode = UNSUPPORTED_OP;
                endcase

                // decode addressing mode
                case(bbb) 
                    3'b000: addressing_mode = INDEXED_INDIRECT; 
                    3'b001: addressing_mode = ZERO_PAGE;
                    3'b010: begin
                        if (aaa == 3'b100) begin
                            opcode = UNSUPPORTED_OP;
                            addressing_mode = UNSUPPORTED_AM;
                        end
                        else addressing_mode = IMMEDIATE;
                    end 
                    3'b011: addressing_mode = ABSOLUTE; 
                    3'b100: addressing_mode = INDIRECT_INDEXED;
                    3'b101: addressing_mode = ZERO_PAGE_X;
                    3'b110: addressing_mode = ABSOLUTE_Y;
                    3'b111: addressing_mode = ABSOLUTE_X;
                    default: begin
                        opcode = UNSUPPORTED_OP;
                        addressing_mode = UNSUPPORTED_AM;
                    end
                endcase
            end
            2'b10: begin
                // decode opcode
                case(aaa) 
                    3'b000: opcode = ASL; 
                    3'b001: opcode = ROL;
                    3'b010: opcode = LSR;
                    3'b011: opcode = ROR; 
                    3'b100: opcode = STX;
                    3'b101: opcode = LDX;
                    3'b110: opcode = DEC;
                    3'b111: opcode = INC;
                    default: opcode = UNSUPPORTED_OP;
                endcase

                // decode addressing mode
                case(bbb) 
                    3'b000: begin
                        if (aaa == 3'b101) addressing_mode = IMMEDIATE; 
                        else begin
                            opcode = UNSUPPORTED_OP;
                            addressing_mode = UNSUPPORTED_AM;
                        end
                    end
                    3'b001: addressing_mode = ZERO_PAGE;
                    3'b010: begin
                        case(aaa)
                            3'b000: begin
                                opcode = TXA;
                                addressing_mode = TODO;
                            end
                            3'b001: begin
                                opcode = TAX;
                                addressing_mode = TODO;
                            end
                            3'b010: begin
                                opcode = DEX;
                                addressing_mode = TODO;
                            end
                            3'b011: begin
                                opcode = NOP;
                                addressing_mode = TODO;
                            end
                            default: addressing_mode = ACCUMULATOR;
                        endcase
                    end
                    3'b011: addressing_mode = ABSOLUTE; 
                    3'b101: begin
                        if ((aaa == 3'b100) || (aaa == 3'b101)) addressing_mode = ZERO_PAGE_Y;
                        else addressing_mode = ZERO_PAGE_X;
                    end
                    3'b110: begin
                        case(aaa)
                            3'b100: begin
                                    opcode = TXS;
                                    addressing_mode = TODO;
                                end
                            3'b101:begin
                                    opcode = TSX;
                                    addressing_mode = TODO;
                                end
                            default: begin
                                    opcode = UNSUPPORTED_OP;
                                    addressing_mode = UNSUPPORTED_AM;
                                end
                        endcase
                    end
                    3'b111: 
                        if (aaa == 3'b100) begin
                            opcode = UNSUPPORTED_OP;
                            addressing_mode = UNSUPPORTED_AM;
                        end
                        else if (aaa == 3'b101) addressing_mode = ABSOLUTE_Y;
                        else addressing_mode = ABSOLUTE_X;
                    default: begin
                        opcode = UNSUPPORTED_OP;
                        addressing_mode = UNSUPPORTED_AM;
                    end
                endcase
            end
            2'b11: begin
                opcode = UNSUPPORTED_OP; 
                addressing_mode = UNSUPPORTED_AM;
            end
        endcase
    end

    // get address based on addressing mode 
    // and register values - should only be read 
    // when instruction variable contains
    // instruction for which we want to find the memory address
    // and before we simulate this instruction

    logic [1:0] instruction_requests_needed;
    logic [2:0] mem_requests_needed;
    always_comb begin
        case (addressing_mode) 
            ZERO_PAGE_X: begin
                instruction_requests_needed = 2;
                mem_requests_needed = 1;
            end
            ZERO_PAGE_Y: begin
                instruction_requests_needed = 2;
                mem_requests_needed = 1;
            end
            ABSOLUTE_X: begin
                instruction_requests_needed = 3; 
                mem_requests_needed = 1;
            end
            ABSOLUTE_Y: begin
                instruction_requests_needed = 3;
                mem_requests_needed = 1;
            end
            INDEXED_INDIRECT: begin
                instruction_requests_needed = 2;
                mem_requests_needed = 3;
            end
            INDIRECT_INDEXED: begin
                instruction_requests_needed = 2;
                mem_requests_needed = 3;
            end
            ACCUMULATOR: begin
                instruction_requests_needed = 1;
                mem_requests_needed = 0;
            end
            IMMEDIATE: begin
                instruction_requests_needed = 2;
                mem_requests_needed = 0; 
            end
            ZERO_PAGE: begin
                instruction_requests_needed = 2;
                mem_requests_needed = 1;
            end
            ABSOLUTE: begin
                instruction_requests_needed = 3;
                mem_requests_needed = 1;
            end
            default: error <= 1;
        endcase
    end

    logic [15:0] addr_comb; 
    logic [7:0] addr_one_byte;
    logic [7:0] addr_one_byte2;

    
    logic [2:0] mem_requests_done;

    always_comb begin
        case (addressing_mode) 
            ZERO_PAGE_X: begin
                addr_comb[7:0] = instruction_arg + x;
                addr_comb[15:8] = 8'b0;
            end 
            ZERO_PAGE_Y:  begin
                addr_comb[7:0] = instruction_arg + y;
                addr_comb[15:8] = 8'b0;
            end 
            ABSOLUTE_X: addr_comb = {instruction_arg, instruction_arg2} + x;
            ABSOLUTE_Y: addr_comb = {instruction_arg, instruction_arg2} + y;
            INDEXED_INDIRECT: begin
                if (mem_requests_done == 0) begin
                    addr_comb[7:0] = instruction_arg + x;
                    addr_comb[15:8] = 8'b0;
                end else if (mem_requests_done == 1) begin
                    addr_comb[7:0] = instruction_arg + x + 1; 
                    addr_comb[15:8] = 8'b0;
                end else begin
                    addr_comb = {intermediate_mem2[7:0], intermediate_mem1[7:0]};
                end
            end
            INDIRECT_INDEXED: begin
                if (mem_requests_done == 0) begin
                    addr_comb[7:0] = instruction_arg;
                    addr_comb[15:8] = 8'b0;
                end else if (mem_requests_done == 1) begin
                    addr_comb[7:0] = instruction_arg + 1;
                    addr_comb[15:8] = 8'b0;
                end else begin
                    addr_comb = intermediate_mem1 + {intermediate_mem2[7:0], y};
                end
            end
            ACCUMULATOR: addr_comb <= 0;
            // no mem
            IMMEDIATE: addr_comb <= 0;
            // no mem
            ZERO_PAGE: addr_comb = {8'b0, instruction_arg};
            ABSOLUTE: addr_comb = {instruction_arg, instruction_arg2}; 
            default: error = 1;
        endcase 
    end



    always_ff @(posedge clk_fast) begin
        
        if ((state == REQUESTED_INSTRUCTION) && (!instruction_received) && din_valid) begin
            if (instruction_request_count == 0) begin
                instruction <= din;
                instruction_request_count <= 1;
                // request next bit for accumulator addressing mode but
                // shouldn't be an issue
                dout <= 0;
                addr <= pc + 1;
                rw <= 0;
            end else if (instruction_request_count == 1) begin
                instruction_arg <= din;
                instruction_request_count <= 2;
                if (instruction_requests_needed <= 2) begin
                    instruction_received <= 1;
                    state <= INSTRUCTION_RECEIVED;
                end else begin
                    dout <= 0;
                    addr <= pc + 2;
                    rw <= 0;
                end
            end else begin
                instruction_arg2 <= din;
                instruction_request_count <= instruction_request_count + 1;
                instruction_received <= 1;
                state <= INSTRUCTION_RECEIVED;
            end
        end

        if ((state == REQUESTED_MEM) && (!mem_received) && din_valid) begin
            if (mem_requests_needed == 1) begin
                memory <= din; 
                mem_received <= 1;
                state <= MEM_VAL_RECEIVED; 
            end else begin
                if (mem_requests_done == 1) begin
                    intermediate_mem1 <= din;
                    dout <= 0; 
                    addr <= addr_comb; 
                    rw <= 0; 
                end else if (mem_requests_done == 2) begin
                    intermediate_mem2 <= din;
                    dout <= 0; 
                    addr <= addr_comb; 
                    rw <= 0; 
                end else begin
                    memory <= din; 
                    mem_received <= 1;
                    state <= MEM_VAL_RECEIVED; 
                end
            end
        end

        // for now don't do an acknowledgment that mem written
    end

    always_ff @(posedge clk_slow) begin
        if (rst) begin
            // set initial register values
            count <= 0; 
            estimated_cycles <= 2;
            error <= 0;

        end else begin
            

            if (count >= estimated_cycles) begin // done with current instruction
                if (!(instruction_done && state == REST)) begin
                    state <= ERROR;
                end else begin
                    // move on to the next instruction
                    dout <= 0;
                    addr <= pc;
                    rw <= 0; // read
                    state <= REQUESTED_INSTRUCTION;
                    instruction_done <= 0;
                    mem_requests_done <= 0;
                end
            end else if (!(state == ERROR)) begin
                count <= count + 1;
            end

            if (error == 1 || state == ERROR) begin
                state <= ERROR;
            end else begin

                if (state == INSTRUCTION_RECEIVED) begin
                    instruction_received <= 0;
                    //  decode instruction
                    opcode_stored <= opcode; 
                    addressing_mode_stored <= addressing_mode;

                    // start memory requests
                    if (mem_requests_needed == 0) begin // accumulator or immediate
                        if (addressing_mode == ACCUMULATOR) begin
                            memory <= a;
                        end else if (addressing_mode == IMMEDIATE) begin
                            memory <= instruction_arg;
                        end else begin
                            state <= ERROR;
                        end

                        state <= MEM_VAL_RECEIVED;
                    end else begin
                        dout <= 0; 
                        addr <= addr_comb; 
                        rw <= 0; 
                        state <= REQUESTED_MEM;

                    end

                end

                if (state == MEM_VAL_RECEIVED) begin
                    pc <= pc + instruction_requests_needed; // will be overwritten by branch instructions
                    // simulate instruction
                    state <= REST;
                    instruction_done <= 1; // ????
                    // maybe update correct number of cycles based on opcode/addressing mode

                    // below we store current reguster values, 
                    // possibly override them based on computation (do after memory is ready)
                    case (opcode) 
                        ADC: begin
                            result = {1'b0, a} + {1'b0, memory} + c; 
                            a <= result[7:0];
                            c <= result[8];
                            z <= result == 0;
                            temp1 = ((result ^ a) & (result ^ memory));
                            v <= temp1[7];
                            n <= result[7];
                            
                        end
                        AND: begin
                            result = a & memory;
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
                            if (c == 1'b0) begin
                                pc <= $signed({1'b0, pc}) + $signed(3'b010) + $signed(memory);
                            end
                        end
                        BCS: begin
                            if (c == 1'b1) begin
                                pc <= $signed({1'b0, pc}) + $signed(3'b010) + $signed(memory);
                            end
                        end
                        BEQ: begin
                            if (z == 1'b1) begin
                                pc <= $signed({1'b0, pc}) + $signed(3'b010) + $signed(memory);
                            end
                        end
                        BIT: begin
                            result = a & memory;
                            z <= result == 0;
                            v <= result[6];
                            n <= result[7];
                        end
                        BMI: begin
                            if (n == 1'b1) begin
                                pc <= $signed({1'b0, pc}) + $signed(3'b010) + $signed(memory);
                            end
                        end
                        BNE: begin
                            if (z == 1'b0) begin
                                pc <= $signed({1'b0, pc}) + $signed(3'b010) + $signed(memory);
                            end
                        end
                        BPL: begin
                            if (n == 1'b0) begin
                                pc <= $signed({1'b0, pc}) + $signed(3'b010) + $signed(memory);
                            end
                        end
                        BRK: state <= ERROR;
                        // interrupt
                        BVC: begin
                            if (v == 1'b0) begin
                                pc <= $signed({1'b0, pc}) + $signed(3'b010) + $signed(memory);
                            end
                        end
                        BVS: begin
                            if (v == 1'b1) begin
                                pc <= $signed({1'b0, pc}) + $signed(3'b010) + $signed(memory);
                            end
                        end
                        CLC: c <= 1'b0;
                        CLD: d <= 1'b0;
                        CLI: i <= 1'b0;
                        CLV: v <= 1'b0;
                        CMP: begin
                            result = a - memory; 
                            c <= a >= memory; 
                            z <= a == memory;
                            n <= result[7];
                        end
                        CPX: begin
                            result = x - memory; 
                            c <= x >= memory; 
                            z <= x == memory;
                            n <= result[7];
                        end
                        CPY: begin
                            result = y - memory; 
                            c <= y >= memory; 
                            z <= y == memory;
                            n <= result[7];
                        end
                        DEC: begin
                            result = memory - 1;
                            // signed or unsigned???
                            dout <= result;
                            addr <= addr_comb;
                            rw <= 1; // write
                            state <= REST; 
                            z <= result == 0;
                            n <= result[7];
                        end
                        DEX: begin
                            result = x - 1;
                            x <= result[7:0];
                            z <= result == 0;
                            n <= result[7];
                        end
                        DEY: begin
                            result = y - 1;
                            y <= result[7:0];
                            z <= result == 0;
                            n <= result[7];
                        end
                        EOR: begin
                            result = a ^ memory; 
                            a <= result[7:0];
                            z <= result == 0;
                            n <= result[7];
                        end 
                        INC: begin
                            result = memory + 1;
                            dout <= result;
                            addr <= addr_comb;
                            rw <= 1; // write
                            state <= REST; 
                            z <= result == 0;
                            n <= result[7];
                        end
                        INX: begin
                            result = x + 1;
                            x <= result;
                            z <= result == 0;
                            n <= result[7];
                        end
                        INY:  begin
                            result = y + 1;
                            y <= result;
                            z <= result == 0;
                            n <= result[7];
                        end
                        JMP: begin
                            // need to read two bytes
                            // ?????????
                            pc <= memory;
                        end
                        JSR: state <= ERROR;
                        // interrupt
                        LDA: begin
                            result = memory;
                            a <= result;
                            z <= result == 0;
                            n <= result[7];
                        end
                        LDX:  begin
                            result = memory;
                            x <= result;
                            z <= result == 0;
                            n <= result[7];
                        end
                        LDY:  begin
                            result = memory;
                            y <= result;
                            z <= result == 0;
                            n <= result[7];
                        end
                        LSR: begin
                            result = memory >> 1;
                            dout <= result;
                            addr <= addr_comb;
                            rw <= 1; // write
                            state <= REST; 
                            c <= memory[0];
                            z <= result == 0;
                            n <= 1'b0;
                        end
                        // accumulator case separately
                        NOP: pc <= pc + 1;
                        ORA: begin
                            result = a | memory; 
                            a <= result; 
                            z <= result == 0;
                            n <= result[7];
                        end
                        PHA: state <= ERROR;
                        // STACK
                        PHP: state <= ERROR;
                        // STACK
                        PLA: state <= ERROR;
                        // STACK
                        PLP: state <= ERROR;
                        // STACK
                        ROL: state <= ERROR;
                        ROR: state <= ERROR;
                        RTI: state <= ERROR;
                        // INTERRUPT
                        RTS: state <= ERROR;
                        // STACK
                        SBC: begin
                            result = a - memory - ~c; 
                            a <= result;
                            // c <= ; 
                            // confused
                            z <= result == 0;
                            v <= (result[7:0] ^ a) & (result ^ (~memory)) & 8'b10000000;
                            n <= result[7]; 
                        end
                        SEC: c <= 1'b1;
                        SED: d <= 1'b1;
                        SEI: i <= 1'b1;
                        STA: begin
                            dout <= a;
                            addr <= addr_comb;
                            rw <= 1; // write
                            state <= REST; 
                        end
                        STX: begin
                            dout <= x;
                            addr <= addr_comb;
                            rw <= 1; // write
                            state <= REST; 
                        end
                        STY: begin
                            dout <= y;
                            addr <= addr_comb;
                            rw <= 1; // write
                            state <= REST; 
                        end
                        TAX: begin
                            result = a;
                            x <= result;
                            z <= result == 0;
                            n <= result[7];
                        end
                        TAY: begin
                            result = a;
                            y <= result;
                            z <= result == 0;
                            n <= result[7];
                        end
                        TSX: begin
                            result = s;
                            x <= result;
                            z <= result == 0;
                            n <= result[7];
                        end 
                        TXA: begin
                            result = x;
                            a <= result;
                            z <= result == 0;
                            n <= result[7];
                        end 
                        TXS: begin
                            result = x;
                            s <= result;
                            z <= result == 0;
                            n <= result[7];
                        end
                        TYA: begin
                            result = y;
                            a <= result;
                            z <= result == 0;
                            n <= result[7];
                        end
                        UNSUPPORTED_OP: state <= ERROR;
                        // TODO: combine with regular?
                        // JMP_ABS: 
                        // JSR_ABS:
                        default: begin
                            instruction_done <= 1; 
                            error <= 1;
                        end

                    endcase

                end
            end
        end

    end



endmodule

`default_nettype wire



