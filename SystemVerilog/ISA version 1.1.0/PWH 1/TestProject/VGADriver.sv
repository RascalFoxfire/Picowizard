`timescale 1ns / 1ps

module VGADriver
    (
    input logic Clk, VGADriverClk,
    input logic WrtMem, LdMem, Reset,
    input logic[7:0] DataIn,
    input logic[15:0] AdrIn,
    output logic[7:0] DataOut,
    output logic VSync, HSync, R0, R1, R2, G0, G1, G2, B0, B1, CPUReset
    );
    
    logic[15:0] CorrectedAdr;
    logic[10:0] PixelCounter, NextPixel;
    logic[9:0] LineCounter, NextLine;
    logic[7:0] DataOutBuf0, DataOutBuf1, DataOutActBuf, CCR; // [0] => Framebuffer, [1] => CPU finished, [2] => GPU finished
    logic LdBuf0, LdBuf1, GoToNextLine, VSyncFF, VSyncFFCDC;
    
    (* ASYNC_REG = "TRUE" *) logic sync0, sync1; 
    always_ff @(posedge Clk) begin
        sync1 <= sync0;
        sync0 <= VSyncFF;
    end
    always_comb VSyncFFCDC = sync1;
    
    // Insert here a memory block with 8 bit width and 49152 depth (1024 x 768 divided by 4 => 256 x 192)
    // Shown is a Vivado block RAM with 8 bit width and 49152 depth
    VGABuffer FrameBuffer0(
        .addra(CorrectedAdr),
        .clka(Clk),
        .dina(DataIn),
        .ena(LdBuf0),
        .wea((CCR[0] & WrtMem)),
        .addrb({LineCounter[9:2], PixelCounter[9:2]}),
        .clkb(VGADriverClk),
        .doutb(DataOutBuf0),
        .enb(~PixelCounter[10] & ~(LineCounter[8] & LineCounter[9]))
    );
    
    VGABuffer FrameBuffer1(
        .addra(CorrectedAdr),
        .clka(Clk),
        .dina(DataIn),
        .ena(LdBuf1),
        .wea((~CCR[0] & WrtMem)),
        .addrb({LineCounter[9:2], PixelCounter[9:2]}),
        .clkb(VGADriverClk),
        .doutb(DataOutBuf1),
        .enb(~PixelCounter[10] & ~(LineCounter[8] & LineCounter[9]))
    );
    
    always_comb CorrectedAdr = {{AdrIn[15:14] - 1, AdrIn[13:0]}}; //0x4000-0xFFFF => Buffer, 0x3800-3FFF => CCR
    always_comb LdBuf0 = (CCR[0] & (LdMem | WrtMem));
    always_comb LdBuf1 = (~CCR[0] & (LdMem | WrtMem));
    always_comb CPUReset = CCR[1] & ~CCR[2]; 
    
    always_comb begin
        if (CCR[0]) begin
            DataOutActBuf = DataOutBuf1;
        end
        else begin
            DataOutActBuf = DataOutBuf0;
        end
    end
    
    always_comb begin
        if (PixelCounter < 1024 && LineCounter < 768) {R0, R1, R2, G0, G1, G2, B0, B1} = DataOutActBuf;
        else {R0, R1, R2, G0, G1, G2, B0, B1} = 8'b00000000;
    end
    
    always_comb begin
        if (CorrectedAdr[15] && CorrectedAdr[14] && LdMem) DataOut = CCR;
        else DataOut = 0;
    end
    
    always_comb begin
        if (PixelCounter == 1344) begin
            NextPixel = 0;
            GoToNextLine = 1;
        end
        else begin
            NextPixel = PixelCounter + 1;
            GoToNextLine = 0;
        end
    end
    
    always_comb begin
        if ((LineCounter == 806) && GoToNextLine) begin
            NextLine = 0;
        end
        else begin
            NextLine = LineCounter + GoToNextLine;
        end
    end
    
    always_comb begin
        if (PixelCounter > 1047 && PixelCounter <= 1183) HSync = 1; //If it doesn't work: change from 1048 to 1047 & 1184 to 1183
        else HSync = 0;
    end
    
    always_comb begin
        if (LineCounter > 770 && LineCounter <= 776) VSync = 1; //If it doesn't work: change from 771 to 770 & 777 to 776
        else VSync = 0;
    end
    
    always_ff @(posedge VGADriverClk) begin
        if (Reset) begin
            PixelCounter <= 0;
            LineCounter <= 0;
        end
        else begin
            PixelCounter <= NextPixel;
            LineCounter <= NextLine;
        end
    end
    
    always_ff @(posedge VGADriverClk) begin
        if (PixelCounter[10:2] == 256 && LineCounter[9:2] == 192) VSyncFF <= 1;
        else VSyncFF <= 0;
    end
    
    always_ff @(posedge Clk) begin
        if (Reset) CCR <= 0;
        else if (CorrectedAdr[15] && CorrectedAdr[14] && CorrectedAdr[13] && CorrectedAdr[12] && CorrectedAdr[11] && WrtMem) CCR <= {DataIn[7:1], CCR[0]}; //CPU addres 3800-3FFF
        else if (VSyncFFCDC && CCR[1]) CCR <= {7'b0000010, ~CCR[0]};
    end
    
endmodule
