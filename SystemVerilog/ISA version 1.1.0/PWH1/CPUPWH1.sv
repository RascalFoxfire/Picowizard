`timescale 1ns / 1ps

module CPUPW1(
    input logic Clk, CPUEn,
    input logic[7:0] DataIn,
    output logic LdMem, WrtMem,
    output logic[7:0] DataOut,
    output logic[15:0] AdrOut
    );
    
    //Microstates
    logic[1:0] MicroCounter;
    logic Write;
    
    //Enable
    logic CPUEnable;
    
    //Address stuff
    logic[15:0] CurrentAdr;
    logic[15:0] NextAdr;
    logic[15:0] IncAdr;
    logic CounterCarry;
    logic Zero;
    logic[15:0] JumpAdr;
    
    //Operation decoder signals
    logic CALL;
    logic StrOps;
    
    //Registers
    logic[7:0] RegA, RegB, RegC, Seg;
    logic Carry;
    logic[7:0] CurrentOp;
    logic[7:0] InRegB, InRegC;
    logic[7:0] OutRegA, OutRegB;
    logic StoreToA, StoreToB, StoreToC, StoreToSEG;
    
    //ALU
    logic[7:0] ALUOut;
    logic[7:0] RegIn;
    logic CarryOut;
    
    
    //States
    always_comb CPUEnable = CPUEn ^ CounterCarry;
    always_comb Write = MicroCounter[0] & MicroCounter[1] & CPUEnable; //Microstate Write
    always_comb {CounterCarry, IncAdr} = CurrentAdr + 1'b1; //Calculate next address
    
    //Operations
    always_comb CALL = Write & (CurrentOp[7] & ~CurrentOp[6] & CurrentOp[5] & Zero) | (CurrentOp[7] & ~CurrentOp[6] & CurrentOp[5] & !CurrentOp[2]);
    always_comb StrOps = ~CurrentOp[7] | CurrentOp[6] | (CurrentOp[7] & ~CurrentOp[6] & ~CurrentOp[5] & ~CurrentOp[2]);
    
    //Registers
    always_comb InRegB = CALL ? IncAdr[7:0] : RegIn;
    always_comb InRegC = CALL ? IncAdr[15:8] : RegIn;
    
    always_comb StoreToA = ~CurrentOp[4] & ~CurrentOp[3] & Write & StrOps;
    always_comb StoreToB = ~CurrentOp[4] & CurrentOp[3] & Write & StrOps;
    always_comb StoreToC = CurrentOp[4] & ~CurrentOp[3] & Write & StrOps;
    always_comb StoreToSEG = CurrentOp[4] & CurrentOp[3] & Write & StrOps;
    
    always_comb begin
        case ({CurrentOp[4], CurrentOp[3]})
            2'b00 : OutRegA = RegA;
            2'b01 : OutRegA = RegB;
            2'b10 : OutRegA = RegC;
            2'b11 : OutRegA = Seg;
        endcase
    end
    
    always_comb begin
        case ({CurrentOp[1], CurrentOp[0]})
            2'b00 : OutRegB = RegA;
            2'b01 : OutRegB = RegB;
            2'b10 : OutRegB = RegC;
            2'b11 : OutRegB = Seg;
        endcase
    end
    
    //Counter and branch
    always_comb Zero = ~(OutRegA[0] | OutRegA[1] | OutRegA[2] | OutRegA[3] | OutRegA[4] | OutRegA[5] | OutRegA[6] | OutRegA[7]);
    always_comb begin
        if (CurrentOp[7] && !CurrentOp[6] && CurrentOp[5] && Zero) JumpAdr = {Seg, OutRegB};
        else JumpAdr = {OutRegA, OutRegB};
    end
    
    always_comb begin
        if (((CurrentOp[7] && !CurrentOp[6] && CurrentOp[5] && Zero) || (CurrentOp[7] && !CurrentOp[6] && CurrentOp[5] && CurrentOp[2])) && MicroCounter[1]) NextAdr = JumpAdr;
        else NextAdr = IncAdr;
    end
    
    //Output
    always_comb DataOut = OutRegA;
    always_comb LdMem = (~MicroCounter[1]) | (CurrentOp[7] & CurrentOp[6]) | (CurrentOp[7] & ~CurrentOp[6] & ~CurrentOp[5] & ~CurrentOp[2] & MicroCounter[1]);
    always_comb WrtMem = CurrentOp[7] & ~CurrentOp[6] & ~CurrentOp[5] & CurrentOp[2] & MicroCounter[1];
    always_comb begin
        if ((CurrentOp[7] && !CurrentOp[6] && !CurrentOp[5]) && MicroCounter[1]) AdrOut = {Seg, OutRegB};
        else AdrOut = CurrentAdr;
    end
    
    //ALU
    always_comb begin
        case ({CurrentOp[5], CurrentOp[2]})
            2'b00 : {CarryOut, ALUOut} = OutRegA + OutRegB;
            2'b01 : {CarryOut, ALUOut} = OutRegA + OutRegB + Carry;
            2'b10 : begin
                ALUOut = ~(OutRegA & OutRegB);
                CarryOut = 1'b1;
            end
            2'b11 : begin
                ALUOut = OutRegA ^ OutRegB;
                CarryOut = 1'b1;
            end
        endcase
    end
    
    always_comb begin
        case ({CurrentOp[7],CurrentOp[6]})
            2'b11 : RegIn = DataIn;
            2'b10 : RegIn = DataIn;
            2'b01 : RegIn = ALUOut;
            2'b00 : RegIn = OutRegB;
        endcase
    end
    
    //Counters update
    always_ff @(posedge Clk) begin
        if (!CPUEn) MicroCounter <= 2'b00; //Update microcounter
        else if (CPUEnable) MicroCounter <= MicroCounter + 2'b01;
    end
    always_ff @(posedge Clk) begin
        if (!CPUEn) CurrentAdr <= 16'b0000000000000000;
        else if (CPUEnable && ((MicroCounter[0] && !MicroCounter[1]) || (MicroCounter[0] && MicroCounter[1] && (CurrentOp[7] && CurrentOp[6])) || (MicroCounter[0] && MicroCounter[1] && CurrentOp[7] && !CurrentOp[6] && CurrentOp[5] && Zero) || (MicroCounter[0] && MicroCounter[1] && CurrentOp[7] && !CurrentOp[6] && CurrentOp[5] && CurrentOp[2]))) CurrentAdr <= NextAdr; //Update counter
    end
    always_ff @(posedge Clk) begin
        if (MicroCounter[0] && !MicroCounter[1] && CPUEnable) CurrentOp <= DataIn; //Update current operation register
    end
    
    //Register input update
    always_ff @(posedge Clk) if (StoreToA) RegA <= RegIn;
    always_ff @(posedge Clk) if (StoreToB || (Write && CALL)) RegB <= InRegB;
    always_ff @(posedge Clk) if (StoreToC || (Write && CALL)) RegC <= InRegC;
    always_ff @(posedge Clk) if (StoreToSEG) Seg <= RegIn;
    always_ff @(posedge Clk) begin
        if (!CPUEn) Carry <= 1'b0;
        else if (!CurrentOp[7] && CurrentOp[6] && Write && CPUEnable) Carry <= CarryOut;
    end
    
endmodule
