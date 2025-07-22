`timescale 1ns / 1ps
//Version 0.1
module Pixospark(
        input logic Reset,
        input logic SysClk, VGADriverClk, //Half VGA freq. clock
        input logic WrtTextMem, WrtFrameMem,
        input logic[7:0] DataIn,
        input logic[9:0] AdrIn,
        output logic VSync, HSync, White
    );
    
    (* ASYNC_REG = "TRUE" *) logic ResetSync0, ResetSync1;
    
    always_ff @(posedge VGADriverClk) begin
        ResetSync1 <= ResetSync0;
        ResetSync0 <= Reset;
    end
    
    logic VGAData, HSync0, VSync0, HSync1, VSync1, HSync2, VSync2, HSync3, VSync3;
    logic[4:0] HSyncBuf, VSyncBuf;
    logic[7:0] C0R, C0G, C0B, C1R, C1G, C1B, C2R, C2G, C2B, C3R, C3G, C3B, C4R, C4G, C4B, C5R, C5G, C5B;
    logic[7:0] CharMemOut, PixelDataOut, PixelDataShift;
    logic[8:0] XCounter;
    logic[9:0] YCounter, FrameCounter, CharAdr;
    
//    typedef enum {IDLE, INIT, RUN, FINISH} EngineState;
//    EngineState CurrentEngineState, NextEngineState;
    
    // The two different memories with 1 KByte each
    SimpleDualPort TextureBuffer (
        .addra(AdrIn),
        .clka(SysClk),
        .dina(DataIn),
        .ena(~Reset),
        .wea(WrtTextMem),
        .addrb(CharAdr),
        .clkb(VGADriverClk),
        .doutb(PixelDataOut),
        .enb(~Reset)
    );
    
    SimpleDualPort FrameBuffer (
        .addra(AdrIn),
        .clka(SysClk),
        .dina(DataIn),
        .ena(~Reset),
        .wea(WrtFrameMem),
        .addrb(FrameCounter),
        .clkb(VGADriverClk),
        .doutb(CharMemOut),
        .enb(~Reset)
    );
    
    // Load from frame buffer
    always_ff @(posedge VGADriverClk) begin
        if (ResetSync1) CharAdr <= 0;
        else if (!XCounter[2] && !XCounter[1] && XCounter[0]) CharAdr <= {CharMemOut[6:0], YCounter[4:2]};
    end
    
    always_ff @(posedge VGADriverClk) begin
        if (ResetSync1 || (FrameCounter == 999 && XCounter[2] && XCounter[1] && XCounter[0]) || YCounter > 479) FrameCounter <= 0;
        else if (XCounter[2] && XCounter[1] && XCounter[0] && (XCounter < 320) && (YCounter < 480)) FrameCounter <= FrameCounter + 1;
        else if (XCounter == 320 && (!YCounter[4] || !YCounter[3] || !YCounter[2] || !YCounter[1] || !YCounter[0])) FrameCounter <= FrameCounter - 40;
    end
    
    // Format the output data
    always_ff @(posedge VGADriverClk) begin
        if (ResetSync1 || XCounter > 322) PixelDataShift <= 0;
        else if (!XCounter[2] && XCounter[1] && XCounter[0]) PixelDataShift <= PixelDataOut;
        else PixelDataShift[7:1] <= PixelDataShift[6:0];
    end
    
    assign White = PixelDataShift[7];
    
    // The VGA driver
    always_ff @(posedge VGADriverClk) begin
        if (ResetSync1 || XCounter == 399) XCounter <= 0;
        else XCounter <= XCounter + 1;
    end
    
    always_ff @(posedge VGADriverClk) begin
        if (ResetSync1 || YCounter == 524) YCounter <= 0;
        else if (XCounter == 399) YCounter <= YCounter + 1;
    end
    
    always_ff @(posedge VGADriverClk) begin
        if (Reset) HSync0 <= 0;
        else if (XCounter > 327 && XCounter < 376) HSync0 <= 1;
        else HSync0 <= 0;
    end
    always_ff @(posedge VGADriverClk) begin
        if (Reset) HSync1 <= 0;
        else HSync1 <= HSync0;
    end
    always_ff @(posedge VGADriverClk) begin
        if (Reset) HSync2 <= 0;
        else HSync2 <= HSync1;
    end
    always_ff @(posedge VGADriverClk) begin
        if (Reset) HSync3 <= 0;
        else HSync3 <= HSync2;
    end
    
    assign HSync = HSync3;
    
    always_ff @(posedge VGADriverClk) begin
        if (Reset) VSync0 <= 0;
        else if (YCounter > 489 && YCounter < 492) VSync0 <= 1;
        else VSync0 <= 0;
    end
    always_ff @(posedge VGADriverClk) begin
        if (Reset) VSync1 <= 0;
        else VSync1 <= VSync0;
    end
    always_ff @(posedge VGADriverClk) begin
        if (Reset) VSync2 <= 0;
        else VSync2 <= VSync1;
    end
    always_ff @(posedge VGADriverClk) begin
        if (Reset) VSync3 <= 0;
        else VSync3 <= VSync2;
    end
    
    assign VSync = VSync3;
endmodule
