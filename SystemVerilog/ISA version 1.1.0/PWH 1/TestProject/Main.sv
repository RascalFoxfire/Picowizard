`timescale 1ns / 1ps

module Main (
    input logic CLK100MHZ, SW0, //Switch with your own FPGA system clock and input you want to use for reset
    output logic VGA_R0, VGA_R1, VGA_R2, VGA_R3, VGA_G0, VGA_G1, VGA_G2, VGA_G3, VGA_B0, VGA_B1, VGA_B2, VGA_B3, VGA_HS, VGA_VS //Change to your output
    );
    
    logic[15:0] AdrFromCPUToModules;
    logic[7:0] DataFromModulesToCPU, DataFromCPUToModules, DataFromMemToCPU, DataFromVGAToCPU;

    logic LoadFromModules, WriteToModules;
    logic EnCPUGPU;
    logic CPUEnable, SysReset;
    logic SysMainClk;
    logic SysVGAClk;
    logic WrtToVGA, WrtToMem, LdFromVGA, LdFromMem;
    
    // Insert here a MMCM that can generate from the system clock the VGA clock and CPU main clock
    // Shown is Vivado a clock manager outputing 65 MHz for the SysVGAClk and 170 MHz for the SysMainClk
    SysClkGen VGAMainClkGen (
        .BoardClk(CLK100MHZ),
        .CPUClkGen(SysMainClk),
        .VGAClkGen(SysVGAClk)
    );
    
    CPUPWH1 MainCPU(
        .Clk(SysMainClk),
        .CPUEn(CPUEnable),
        .DataIn(DataFromModulesToCPU),
        .LdMem(LoadFromModules),
        .WrtMem(WriteToModules),
        .DataOut(DataFromCPUToModules),
        .AdrOut(AdrFromCPUToModules)
    );
    
    // Insert here a memory block which lays at CPU address 0x0000 to 0x3FFF (8 KByte)
    // Shown is a Vivado block RAM with 8 bit width and 8192 depth
    BIOSMem MainCPUMem(
        .addra(AdrFromCPUToModules[12:0]),
        .clka(SysMainClk),
        .dina(DataFromCPUToModules),
        .douta(DataFromMemToCPU),
        .ena(LdFromMem | WrtToMem),
        .wea(WrtToMem)
    );
    
    VGADriver MainVGADriver(
        .Clk(SysMainClk),
        .VGADriverClk(SysVGAClk),
        .WrtMem(WriteToModules),
        .LdMem(LoadFromModules),
        .DataIn(DataFromCPUToModules),
        .Reset(SysReset),
        .AdrIn(AdrFromCPUToModules),
        .DataOut(DataFromVGAToCPU),
        .VSync(VGA_VS),
        .HSync(VGA_HS),
        .R0(VGA_R0),
        .R1(VGA_R1),
        .R2(VGA_R2),
        .G0(VGA_G0),
        .G1(VGA_G1),
        .G2(VGA_G2),
        .B0(VGA_B0),
        .B1(VGA_B1),
        .CPUReset(EnCPUGPU)
    );
    
    //Some more always stuff to get the addressing right
    always_comb begin
        if (AdrFromCPUToModules < 8192) begin
            DataFromModulesToCPU = DataFromMemToCPU;
            LdFromMem = LoadFromModules;
            WrtToMem = WriteToModules;
        end
        else if (AdrFromCPUToModules >= 8192) begin
            DataFromModulesToCPU = DataFromVGAToCPU;
            LdFromMem = 0;
            WrtToMem = 0;
        end
        else begin
            DataFromModulesToCPU = 0;
            LdFromMem = 0;
            WrtToMem = 0;
        end
    end
    
    always_comb SysReset = ~SW0;
    always_comb CPUEnable = ~(EnCPUGPU | ~SW0);
    
    always_comb VGA_R3 = VGA_R0;
    always_comb VGA_G3 = VGA_G0;
    always_comb VGA_B2 = VGA_B0;
    always_comb VGA_B3 = VGA_B1;
endmodule
