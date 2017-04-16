`include "assert.vh"

`include "cpu.vh"


module cpu_tb();

  parameter ROM_ADDR = 4;

  reg         clk   = 0;
  reg         reset = 0;
  wire [63:0] result;
  wire [ 1:0] result_type;
  wire        result_empty;
  wire [ 3:0] trap;

  cpu #(
    .ROM_FILE("i64.sub.hex"),
    .ROM_ADDR(ROM_ADDR)
  )
  dut
  (
    .clk(clk),
    .reset(reset),
    .result(result),
    .result_type(result_type),
    .result_empty(result_empty),
    .trap(trap)
  );

  always #1 clk = ~clk;

  initial begin
    $dumpfile("i64.sub_tb.vcd");
    $dumpvars(0, cpu_tb);

    #24
    `assert(result, 1);
    `assert(result_type, `i64);
    `assert(result_empty, 0);

    $finish;
  end

endmodule
