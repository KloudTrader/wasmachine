# 2017-03-01

`-I` option of `iverilog` allow to define include folders. It allow to be
separated from the argument although manual page seems to say other thing.

`iverilog` generate "executable" script files for the `vvp` command that's the
one that effectively run the simulation, so probably there could be an option to
define some devices (like a serial port) and interactuate with it.

# 2017-03-02

Since `Makefile` instructions are executed verbatin, you can use shell comments
to print some text to `stdout`.

# 2017-03-03

Verilog `vcc` is the command with the simulation runtime. Its `-N` flag makes
the simulation to exit when invoking the `$stop` command with `1` as error code.

Icarus Verilog support `__FILE__` and `__LINE__` statements (http://stackoverflow.com/a/12953585/586382).
There's a test suite at https://github.com/steveicarus/ivtest

# 2017-03-05

FPUs implemented in Verilog:
- https://opencores.org/project,fpu
- https://github.com/dawsonjon/fpu

[Chips: design components in C, design FPGAs in Python](http://dawsonjon.github.io/Chips-2.0/home/index.html)

# 2017-03-07

`-y` option of `iverilog` allow to define library folders, to search for modules
that otherwise it would error as not found.

# 2017-03-09

`-g2005-sv` flag enable support for SystemVerilog

To make `-y` option to work, modules has to have the same name and
capitalization that the filename of the file that host them.

Icarus Verilog is forcing to define registers as input and output of modules,
so it's needed two tick to access ROM data, one to define address and another to
read it. It must to be a solution for that, maybe using combinational logic.
Seems the `logic` type autodetect if should be a `wire` or a `reg`.

# 2017-03-11

Stack operation at the end of the pipeline are processed while the opcode of the
next instruction is being fetch to earn some CPU cycles.

[WebAssembly Explorer](http://mbebenita.github.io/WasmExplorer/)
[WasmFiddle](https://wasdk.github.io/WasmFiddle/?)

# 2017-03-12

It's needed to decide what to do when fetching extra bytes from ROM beyond its
actual size. Error, zeros, or unset bits?

# 2017-03-13

To identify the end of a WebAssembly module, we'll use at its end a custom empty
section. This means that just two zero bytes will be appended, and we'll get the
same effect when reading from a previously zeroed memory. When loading from a
serial line we could use other methods to identify module EOL.

Sync `=` asignation can be used when the asigned data will be used on the same
cycle, async `<=` asignation is not warranted when it will be done during that
cycle.

# 2017-03-15

Max length of single inmediate values is 9 bytes (`i64.const`), and for combined
ones 10 bytes (`memory_immediate`, made of two `varuint32` fields). `br_table`
has a variable length inmediate with the fields `target_count`, `target_table`
(variable 0-n) and `default_target`, so just 5 or 10 bytes would be enought.

# 2017-03-16

[WebAssembly S-expressions](https://developer.mozilla.org/en-US/docs/WebAssembly/Understanding_the_text_format)
