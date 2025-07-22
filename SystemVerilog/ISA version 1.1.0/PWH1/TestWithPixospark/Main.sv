`timescale 1ns / 1ps
//This is an experimental release to include the Pixospark terminal driver! Cut for Pixospark alpha version 0.1
module AltMain (
    input logic CLK100MHZ, SW0,
    output logic VGA_R0, VGA_R1, VGA_R2, VGA_R3, VGA_G0, VGA_G1, VGA_G2, VGA_G3, VGA_B0, VGA_B1, VGA_B2, VGA_B3, VGA_HS, VGA_VS
    );
    
    logic[15:0] AdrFromCPUToModules;
    logic[7:0] DataFromModulesToCPU, DataFromCPUToModules;
    logic LoadFromModules, WriteToModules;
    logic VGAOut;
    logic EnCPUGPU;
    logic SysEnable, ClkLocked;
    logic SysMainClk;
    logic SysVGAClk;
    logic WrtToVGA, WrtToMem, LdFromVGA, LdFromMem;
    
    SysClkGen VGAMainClkGen (
        .clk_in1(CLK100MHZ),
        .CPUClkGen(SysMainClk),
        .VGAClkGen(SysVGAClk),
        .locked(ClkLocked)
    );
    
    CPUPW1 MainCPU(
        .Clk(SysMainClk),
        .CPUEn(SysEnable),
        .DataIn(DataFromModulesToCPU),
        .LdMem(LoadFromModules),
        .WrtMem(WriteToModules),
        .DataOut(DataFromCPUToModules),
        .AdrOut(AdrFromCPUToModules)
    );
    
    //Module for memory
    BIOSMem MainCPUMem(
        .addra(AdrFromCPUToModules[13:0]),
        .clka(SysMainClk),
        .dina(DataFromCPUToModules),
        .douta(DataFromModulesToCPU),
        .ena(LoadFromModules | (~AdrFromCPUToModules[15] & ~AdrFromCPUToModules[14] & WriteToModules)),
        .wea(~AdrFromCPUToModules[15] & ~AdrFromCPUToModules[14] & WriteToModules)
    );
    
    Pixospark GraphicsDriver(
        .Reset(!SysEnable),
        .SysClk(SysMainClk),
        .VGADriverClk(SysVGAClk),
        .WrtTextMem(WriteToModules & ~AdrFromCPUToModules[15] & AdrFromCPUToModules[14] & ~AdrFromCPUToModules[13] & ~AdrFromCPUToModules[12] & ~AdrFromCPUToModules[11]), //0x4000-0x47FF
        .WrtFrameMem(WriteToModules & ~AdrFromCPUToModules[15] & AdrFromCPUToModules[14] & ~AdrFromCPUToModules[13] & ~AdrFromCPUToModules[12] & AdrFromCPUToModules[11]), //0x4800-0x4FFF
        .DataIn(DataFromCPUToModules),
        .AdrIn(AdrFromCPUToModules[9:0]),
        .VSync(VGA_VS),
        .HSync(VGA_HS),
        .White(VGAOut)
    );
    
    assign SysEnable = SW0 & ClkLocked;
    
    always_comb VGA_R0 = VGAOut;
    always_comb VGA_R1 = VGAOut;
    always_comb VGA_R2 = VGAOut;
    always_comb VGA_R3 = VGAOut;
    always_comb VGA_G0 = VGAOut;
    always_comb VGA_G1 = VGAOut;
    always_comb VGA_G2 = VGAOut;
    always_comb VGA_G3 = VGAOut;
    always_comb VGA_B0 = VGAOut;
    always_comb VGA_B1 = VGAOut;
    always_comb VGA_B2 = VGAOut;
    always_comb VGA_B3 = VGAOut;
endmodule
