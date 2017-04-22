[![Build Status](https://travis-ci.org/piranna/wasmachine.svg?branch=master)](https://travis-ci.org/piranna/wasmachine)

# wasmachine
Put WebAssembly in your washing machine

`wasmachine` is an implementation of the [WebAssembly](http://webassembly.org) specification in a FPGA.
It follows a sequential 6-steps design.

Currently it's in an initial state but is able to exec some basic commands.

## Roadmap
1. Implement integer mathematical operations
2. Support for functions calling
3. Add a 64 bits FPU for the floating point operations
4. Memory-based operations
5. Modules loader in RAM
6. Replace usage of ROM for modules on RAM
7. Accept call of functions from outside
8. Use a pipelined design

## External dependencies

- [LEB128](https://github.com/piranna/LEB128)
- [fpu](https://github.com/dawsonjon/fpu)

They can be automatically upgraded executing

```sh
make update-dependencies
```
