`include "assert.vh"


module cpu_tb();

  reg         clk   = 0;
  reg         reset = 0;
  wire [63:0] result;
  wire        result_empty;
  wire [ 2:0] trap;

  cpu #(
    .ROM_FILE("select1.hex"),
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
    $dumpfile("select1_tb.vcd");
    $dumpvars(0, cpu_tb);

    #42
    `assert(result, 1);
    `assert(result_empty, 0);

    $finish;
  end

endmodule
