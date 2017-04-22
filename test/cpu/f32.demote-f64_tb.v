`include "assert.vh"

`include "cpu.vh"


module cpu_tb();

  reg         clk   = 0;
  wire [63:0] result;
  wire [ 1:0] result_type;
  wire        result_empty;
  wire [ 3:0] trap;

  cpu #(
    .ROM_FILE("f32.demote-f64.hex"),
    .ROM_ADDR(4)
  )
  dut
  (
    .clk(clk),
    .result(result),
    .result_type(result_type),
    .result_empty(result_empty),
    .trap(trap)
  );

  always #1 clk = ~clk;

  initial begin
    $dumpfile("f32.demote-f64_tb.vcd");
    $dumpvars(0, cpu_tb);

    #26
    `assert(result, 32'hc0000000);
    `assert(result_type, `f32);
    `assert(result_empty, 0);

    $finish;
  end

endmodule
