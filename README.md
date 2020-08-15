# The DarkRising Library (TDL)

## System requirements
* x86 PC with MS-DOS and SVGA video card, or [DOSBox](https://www.dosbox.com/download.php?main=1)
* Borland Make 3.7 &ast;
* Turbo Assembler 4.0 &ast;
* Watcom Compiler 11.0 &ast;
* Watcom Linker 11.0 &ast;
* DOS extender binary in the linker's directory, e.g. DOS4GW, PMODEW, DOS32, or [DarkX](https://github.com/uavster/DarkX)

&ast;Reachable via PATH environment variable

Different versions of the listed tools may work, too. That is just a configuration I found to work.

## How to build the library
From the base directory, run:
```
maker
```
Or, if you'd like to discard any pre-generated OBJ files:
```
maker -B
```

## How to build the examples
The EXAMPLES directory contains programs showcasing library features. Each example normally has an ```M.BAT``` file that will build it, or a MAKEFILE that can be run with ```make```.
## Troubleshooting
### Building for the first time fails because output files cannot be written
Try deleting all files in the OBJS and LIB directories, and run ```make -B```.
### An example does not build because it cannot find the extender binary
Try a different extender in the invocation to the Watcom Linker:
```
wlink system my_extender_name file executable_name lib path_to_tdl
```
The extender binary must be located in the same directory as WLINK.EXE.
### An example crashes
First, try changing the extender. I empirically found that crashers that can be solved with a change of extender are normally caused by a bug in the program itself. It just happens that that new extender (or binary layout in memory) may be more "tolerant" to the bug. Even if that solves the issue, we would still need to track down and fix the bug.

If changing the extender does not work, try adding more RAM to DOSBox, in case that the crash is caused by an out-of-memory error that was just not reported.
