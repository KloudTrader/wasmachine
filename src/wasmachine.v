`default_nettype none


module wasmachine
#(
  parameter RAM_WIDTH = 16,
  parameter RAM_DEPTH = 18  // 256K * 16 = 512KB
)
(
  input clk,
  input reset,

  inout  [RAM_WIDTH-1:0] ram_data,
  output [RAM_DEPTH-1:0] ram_address
);

  localparam MEM_DEPTH = $clog2(RAM_WIDTH * RAM_DEPTH / 8);
  localparam STACK_DEPTH = 5;


  //
  // Loader
  //


  //
  // Execution Controller
  //

  wire [  MEM_DEPTH:0] pc;
  wire [STACK_DEPTH:0] index;
  wire [         65:0] stack_out;
  wire [          3:0] trap;
  wire                 pushStack;
  wire [         65:0] stack_in;

  ExecController #(
    .MEM_DEPTH(MEM_DEPTH),
    .STACK_DEPTH(STACK_DEPTH)
  ) controller
  (
    .clk(clk),
    .pc(pc),
    .index(index),
    .stack_out(stack_out),
    .trap(trap),
    .cpuReset(cpuReset),
    .pushStack(pushStack),
    .stack_in(stack_in)
  );


  //
  // CPU
  //

  cpu #(
    .MEM_DEPTH(MEM_DEPTH),
    .STACK_DEPTH(STACK_DEPTH)
  ) cpu
  (
    .clk(clk),
    .reset(reset || cpuReset),
    .pc(pc),
    .index(index),
    .stack_out(stack_out),
    .trap(trap),
    .pushStack(pushStack),
    .stack_in(stack_in)
  );

endmodule // wasmachine
