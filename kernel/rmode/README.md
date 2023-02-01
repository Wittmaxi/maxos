# rmode
While we are still in real mode, we can use a lot of the BIOS-calls.
However, we need to make sure that all code is .8086 compatible.

These tools are used throughout the first few phases of the kernel while the kernel
sets up an environment that fits the computer.

## tools
file that includes all rmode tools

## displaytools
Tools for the INT10H syscall.

`DPT_putChar` puts a single char to terminal
--
al = char to put

`DPT_printStr` prints a null-terminated string.
--
ES:DI = string location.

`DPT_clearScr` clears the screen completely
--

`DPT_printNum` prints a number
--
CX = number to print

`DPT_printNumSigned` prints a number with sign. with sign.
--
CX = number to print

requires sign bit in bit 16, requires 2s complement
