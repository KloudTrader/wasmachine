`include "assert.vh"


module cpu_tb();

  reg         clk   = 0;
  reg         reset = 0;
  wire [63:0] result;
  wire        result_empty;
  wire [ 3:0] trap;

  cpu #(
    .ROM_FILE("drop.hex"),
    .ROM_ADDR(4)
  )
  dut
  (
    .clk(clk),
    .reset(reset),
    .result(result),
    .result_empty(result_empty),
    .trap(trap)
  );

  always #1 clk = ~clk;

  initial begin
    $dumpfile("drop_tb.vcd");
    $dumpvars(0, cpu_tb);

    #18
    `assert(result_empty, 1);

    $finish;
  end

endmodule
