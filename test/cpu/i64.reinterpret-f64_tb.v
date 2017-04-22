`include "assert.vh"

`include "cpu.vh"


module cpu_tb();

  reg         clk   = 0;
  reg         reset = 0;
  wire [63:0] result;
  wire [ 1:0] result_type;
  wire        result_empty;
  wire [ 2:0] trap;

  cpu #(
    .ROM_FILE("i64.reinterpret-f64.hex"),
    .ROM_ADDR(4)
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
    $dumpfile("i64.reinterpret-f64_tb.vcd");
    $dumpvars(0, cpu_tb);

    #30
    `assert(result, 64'hc000000000000000);
    `assert(result_type, `i64);
    `assert(result_empty, 0);

    $display("ok");
    $finish;
  end

endmodule
