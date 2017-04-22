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
`define op_call          8'h10

// Parametric operators
`define op_drop   8'h1a
`define op_select 8'h1b

// Variable access
`define op_get_local  8'h20
`define op_set_local  8'h21
`define op_tee_local  8'h22

// Memory-related operators

// Constants
`define op_i32_const 8'h41
`define op_i64_const 8'h42
`define op_f32_const 8'h43
`define op_f64_const 8'h44

// Comparison operators
`define op_i32_eqz  8'h45
`define op_i32_eq   8'h46
`define op_i32_ne   8'h47
`define op_i64_eqz  8'h50
`define op_i64_eq   8'h51
`define op_i64_ne   8'h52

// Numeric operators
`define op_i32_add  8'h6a
`define op_i32_sub  8'h6b
`define op_i64_add  8'h7c
`define op_i64_sub  8'h7d

// Conversions
`define op_f32_demote_f64  8'hb6

// Reinterpretations
`define op_i32_reinterpret_f32 8'hbc
`define op_f32_reinterpret_i32 8'hbe
`define op_f64_reinterpret_i64 8'hbf
