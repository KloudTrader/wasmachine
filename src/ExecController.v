module ExecController
#(
  parameter MEM_DEPTH   = 3,
  parameter STACK_DEPTH = 7
)
(
  input clk,

  output [  MEM_DEPTH:0] pc,
  output [STACK_DEPTH:0] index,
  input  [         65:0] stack_out,
  input  [          3:0] trap,

  output        cpuReset  = 1,
  output        pushStack = 0,
  output [65:0] stack_in
);

endmodule // IoController
