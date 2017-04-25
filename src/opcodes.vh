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
`define op_i32_lt_s 8'h48
`define op_i32_lt_u 8'h49
`define op_i32_gt_s 8'h4a
`define op_i32_gt_u 8'h4b
`define op_i32_le_s 8'h4c
`define op_i32_le_u 8'h4d
`define op_i32_ge_s 8'h4e
`define op_i32_ge_u 8'h4f
`define op_i64_eqz  8'h50
`define op_i64_eq   8'h51
`define op_i64_ne   8'h52
`define op_i64_lt_s 8'h53
`define op_i64_lt_u 8'h54
`define op_i64_gt_s 8'h55
`define op_i64_gt_u 8'h56
`define op_i64_le_s 8'h57
`define op_i64_le_u 8'h58
`define op_i64_ge_s 8'h59
`define op_i64_ge_u 8'h5a

// Numeric operators
`define op_i32_add  8'h6a
`define op_i32_sub  8'h6b
`define op_i64_add  8'h7c
`define op_i64_sub  8'h7d

// Conversions
`define op_f32_demote_f64  8'hb6

// Reinterpretations
`define op_i32_reinterpret_f32 8'hbc
`define op_i64_reinterpret_f64 8'hbd
`define op_f32_reinterpret_i32 8'hbe
`define op_f64_reinterpret_i64 8'hbf
