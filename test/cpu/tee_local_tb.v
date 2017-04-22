`include "assert.vh"

`include "cpu.vh"


module cpu_tb();

  parameter ROM_ADDR = 6;
  parameter STACK_DEPTH = 7;

  reg                  clk   = 0;
  reg                  reset = 1;
  reg  [ ROM_ADDR-1:0] pc    = 17;
  reg  [STACK_DEPTH:0] index = 1;
  wire [         63:0] result;
  wire [          1:0] result_type;
  wire                 result_empty;
  wire [          3:0] trap;

  cpu #(
    .ROM_FILE("tee_local.hex"),
    .ROM_ADDR(ROM_ADDR),
    .STACK_DEPTH(STACK_DEPTH)
  )
  dut
  (
    .clk(clk),
    .reset(reset),
    .pc(pc),
    .index(index),
    .result(result),
    .result_type(result_type),
    .result_empty(result_empty),
    .trap(trap)
  );

  always #1 clk = ~clk;

  initial begin
    $dumpfile("tee_local_tb.vcd");
    $dumpvars(0, cpu_tb);

    #1
    reset <= 0;

    #39
    `assert(result, 2);
    `assert(result_type, `i64);
    `assert(result_empty, 0);

    $finish;
  end

endmodule
