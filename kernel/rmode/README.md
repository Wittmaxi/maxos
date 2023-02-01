# rmode
While we are still in real mode, we can use a lot of the BIOS-calls.
However, we need to make sure that all code is .8086 compatible.

These tools are used throughout the first few phases of the kernel while the kernel
sets up an environment that fits the computer.

## displaytools
Tools for the INT10H syscall.

`DPT_printStr`
prints a null-terminated string.
--
ES:DI = string location.

`DPT_clearScr`
clears the screen completely

`DPT_printNum`
prints a number

`DPT_printNumBase`
prints a number with specified base
