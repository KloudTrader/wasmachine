// Types
// TODO Remove useless bits when not using FPU or 64 bits data
`define i32 2'b00
`define i64 2'b01
`define f32 2'b10
`define f64 2'b11

// Traps
`define NONE              0
`define ENDED             1
`define STACK_EMPTY       2
`define STACK_ERROR       3
`define BLOCK_STACK_EMPTY 4
`define BLOCK_STACK_ERROR 5
`define CALL_STACK_ERROR  6
`define MEM_ERROR         7
`define UNREACHABLE       8
`define BAD_BLOCK_TYPE    9
`define TYPE_MISMATCH     10
`define UNKOWN_OPCODE     11
`define TYPES_MISMATCH    12
`define NO_FPU            13
`define NO_RAM            14
`define NO_64B            15

// blocks
`define block      2'h0
`define block_loop 2'h1
`define block_if   2'h2
