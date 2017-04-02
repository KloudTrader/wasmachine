// Types
`define i32 2'b00
`define i64 2'b01
`define f32 2'b10
`define f64 2'b11

// Traps
`define NONE             0
`define STACK_EMPTY      1
`define STACK_ERROR      2
`define ROM_ERROR        3
`define UNREACHABLE      4
`define CALL_STACK_EMPTY 5
`define CALL_STACK_ERROR 6
`define BAD_BLOCK_TYPE   7
`define TYPE_MISMATCH    8
`define UNKOWN_OPCODE    9
`define TYPES_MISMATCH   10
//`define BAD_LABEL        11
`define ENDED            15

// blocks
`define block          2'h0
`define block_loop     2'h1
`define block_if       2'h2
`define block_function 2'h3
