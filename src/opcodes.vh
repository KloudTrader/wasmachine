// Control flow operators
`define op_unreachable 8'h00
`define op_nop         8'h01
`define op_block       8'h02
`define op_loop        8'h03
`define op_if          8'h04
`define op_else        8'h05
`define op_end         8'h0b
`define op_br          8'h0c
`define op_br_if       8'h0d
`define op_br_table    8'h0e
`define op_return      8'h0f

// Call operators

// Parametric operators
`define op_drop   8'h1a
`define op_select 8'h1b

// Variable access

// Memory-related operators

// Constants
`define op_i32_const 8'h41
`define op_i64_const 8'h42
`define op_f32_const 8'h43
`define op_f64_const 8'h44

// Comparison operators
`define op_i32_eqz  8'h45
`define op_i64_eqz  8'h50

// Numeric operators

// Conversions

// Reinterpretations
`define op_i32_reinterpret_f32 8'hbc
`define op_f32_reinterpret_i32 8'hbe
