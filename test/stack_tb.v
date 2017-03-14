`include "assert.vh"

`include "stack.vh"


module Stack_tb();

  parameter WIDTH = 8;

  reg                clk = 0;
  reg                reset;
  reg  [1:0]         op;
  reg  [WIDTH - 1:0] data;
  wire [WIDTH - 1:0] tos;
  wire [1:0]         status;

  stack #(
    .WIDTH(WIDTH),
    .DEPTH(0)
  )
  dut(
    .clk(clk),
    .reset(reset),
    .op(op),
    .data(data),
    .tos(tos),
    .status(status)
  );

  always #1 clk = ~clk;

  initial begin
    $dumpfile("stack_tb.vcd");
    $dumpvars(0, Stack_tb);

    // `status` is `empty` by default
    `assert(status, `EMPTY);

    // Underflow
    op <= `POP;
    #2
    `assert(status, `UNDERFLOW);

    // Push
    op   <= `PUSH;
    data <= 1;
    #2
    `assert(status, `NONE);
    `assert(tos   , 8'h01);

    // Top of Stack
    op <= `NONE;
    #2
    `assert(tos   , 8'h01);
    `assert(status, `NONE);

    // Overflow
    op   <= `PUSH;
    #2
    `assert(tos   , 8'h01);
    `assert(status, `OVERFLOW);

    // Pop
    op <= `POP;
    #2
    // `assert(tos   , 8'h01);
    `assert(status, `NONE);

    // Push & replace
    data <= 2;
    op   <= `PUSH;
    #2
    `assert(tos   , 8'h02);
    `assert(status, `NONE);

    data <= 3;
    op   <= `REPLACE;
    #2
    `assert(tos   , 8'h03);
    `assert(status, `NONE);

    // Reset
    reset <= 1;
    #2
    // `assert(tos   , 8'h03);
    `assert(status, `EMPTY);

    $display("ok");
    $finish;
  end

endmodule
