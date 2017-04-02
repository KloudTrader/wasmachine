`include "assert.vh"


module cpu_tb();

  reg         clk   = 0;
  reg         reset = 0;
  wire [63:0] result;
  wire        result_empty;
  wire [ 2:0] trap;

  cpu #(
    .ROM_FILE("f64.const.hex"),
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
    $dumpfile("f64.const_tb.vcd");
    $dumpvars(0, cpu_tb);

    #12
    `assert(result, 64'hc000000000000000);
    `assert(result_empty, 0);

    $finish;
  end

endmodule
