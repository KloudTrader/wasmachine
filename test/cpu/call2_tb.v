`include "assert.vh"

`include "cpu.vh"


module cpu_tb();

  parameter ROM_ADDR = 4;

  reg                 clk   = 0;
  reg                 reset = 1;
  reg  [ROM_ADDR-1:0] pc    = 6;
  wire [        63:0] result;
  wire [         1:0] result_type;
  wire                result_empty;
  wire [         2:0] trap;

  cpu #(
    .ROM_FILE("call2.hex"),
    .ROM_ADDR(ROM_ADDR)
  )
  dut
  (
    .clk(clk),
    .reset(reset),
    .pc(pc),
    .result(result),
    .result_type(result_type),
    .result_empty(result_empty),
    .trap(trap)
  );

  always #1 clk = ~clk;

  initial begin
    $dumpfile("call2_tb.vcd");
    $dumpvars(0, cpu_tb);

    #1
    reset <= 0;

    #45
    `assert(result, 3);
    `assert(result_type, `i64);
    `assert(result_empty, 0);

    $finish;
  end

endmodule
