# Picowizard: a tiny 8 bit RISC ISA
## What is Picowizard?
Picowizard is an extremly small ISA designed for CPUs to be used in ASICs and FPGAs for management purposes where larger ISAs and subsequent CPU designs (like RISC-V) just don't fit/aren't needed. It focuses on the bare minimum needed to manage its surroundings while still being easily programmable and reasonably fast.

## Basic informations about the Picowizard ISA
- Tested on a FPGA (Digilent Nexy A7 100T) running at 180 MHz while only using 59 FF and 138 LUTs for itself!
- ISA is minimized to avoid the need for internal memory (like BRAM)
- 4 or 8 (Picowizard+) registers (A, B, C, SEG, TA, TB, TC, TD)
- 10 instructions for data movement, program control and arithmetics/bitwise logic
- 8 bit data
- 16 bit address space
- I/O via memory mapped areas only (no specialised I/O ports)

## What does this repo include?
The folder "Documentation" holds all current ratified ISA versions including documentation and explaination, suggested address space guidelines and proposed changes.
The folder "LogisimEvolution" holds all implementations of the ISA in Logisim Evolution (tested for version 3.9.0) including description files made by RascalFoxfire.
The folder "SystemVerilog" holds all implementations of the ISA in SystemVerilog including description files made by RascalFoxfire.

## How can i develop software for the Picowizard?
There is currently an Assembler and a simple ANSI C => Picowizard bitcode compiler in development

## What is next?
Picowizard is still further developed! There are multiple constructions sides around it:
- ~~Developing a fitting graphic driver following the same principles (as small as possible)~~ Currently in early alpha phase (Pixospark), available in the PWH1 project folder. Currently a pure tile monochrome tile engine using 62 LUTs, 67 FFs and only 2 KByte of memory! (technically 4 KByte of FPGA BRAM since 2 x 1 KByte of simple dual port RAM is needed)
- Further optimize the SystemVerilog implementation to get closer to the 100 Xilinx LUT mark
- Define the recommended address layout
- Build the assembler and compiler
- Software, like SPI drivers
- A programmers tutorial with tips and tricks on how to efficiently code on Picowizard CPUs

## The Pico-series
Picowizard is only one of three similar ISAs for different use cases:
- Picowizard: the smallest of the Picos for cases where LUTs/silicon area is precious or only a minimalistic management engine is needed
- Picoalchemist: the middle child ISA supporting up to 3 external interrupts + an internal 8 bit timer when I/O handling is the main goal (coming soon)
- Picomage: the largest of the Pico-ISAs supporting a ring system (User/Kernel), multiple internal and one external interrupt (including 8 bit timer) and virtual addressing for tasks where secure management is the top priority (coming soon)

## Additional hard-/software