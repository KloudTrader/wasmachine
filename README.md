[![Build Status](https://travis-ci.org/piranna/wasmachine.svg?branch=master)](https://travis-ci.org/piranna/wasmachine)

# wasmachine

Put WebAssembly in your washing machine

`wasmachine` is an implementation of the [WebAssembly](http://webassembly.org) specification in a FPGA.
It follows a sequential 6-steps design.

Currently it's in an initial state but is able to exec some basic commands.

## Features

- Stack-based (calls, blocks and operands), variable-length CISC architecture
  following the WebAssembly spec design
- Strict type-checking on runtime
- Optionally disable floating point, memory and 64 bits operations at instance
  time to generate a simpler core for smaller FPGAs

## WebAssembly Decoded (WAsD)

WebAssembly specification is mostly focused on reduce size length, mostly for
transmission purposses, but make it difficult and ineficient for direct
execution, needing by design to be translated to the target environment.
Wasmachine implement a version of the WebAssembly specification optimized for
direct execution, mostly by decoding the LEB128 values (from here the name), and
pre-calculating some implicit values like blocks sizes.

The name of the specification is also a tribute to the keyboard keys `W`, `A`,
`S` & `D` traditionally used on PC games, that several people noticed greatly
fit with the nomenclature of WebAssembly related projects but nobody used it yet
:-P

`WAsD` is heavily based on WebAssembly specification, for example on the
general architecture or instructions set or instructions arguments. Main
differences are:

- Inlined destination of blocks and branches labels
- Decoded LEB128 targets for `br_table`

Future
- Custom opcodes optimized with prefixes
- Relative offsets
- Decode all LEB128 values

## Keynotes

- [NodeJS Madrid](https://www.todojs.com/web-assembly-workshop-by-dan-callahan)
  (ad-hoc spontaneous keynote at end of the main one :-P)

## Roadmap

1. ~Implement integer mathematical operations~
2. ~Support for functions calling~
3. Add a 64 bits FPU for the floating point operations
4. Memory-based operations
5. Modules loader in RAM
6. ~Replace usage of ROM for modules on RAM~
7. Accept call of functions from outside
8. Use a pipelined design

## External dependencies

- [LEB128](https://github.com/piranna/LEB128)
- [fpu](https://github.com/dawsonjon/fpu)

They can be automatically upgraded executing

```sh
make update-dependencies
```

## Testing

If you want to test all the modules at once with all the features enabled (the
default build configuration), simply exec:

```sh
make test
```

You can also test the modules disabling some features using the `parameters`
argument, that will be directly passed to the `iverilog` executable:

```sh
make test parameters='-Pcpu_tb.HAS_FPU=0 -Pcpu_tb.USE_64B=0'
```
