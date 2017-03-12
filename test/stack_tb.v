`include "assert.vh"


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
    `assert(status, 2'b01);

    // Underflow
    op <= 2;
    #2
    `assert(status, 2'b10);

    // Push
    op   <= 1;
    data <= 1;
    #2
    `assert(tos   , 8'h01);
    `assert(status, 2'b00);

    // Top of Stack
    op <= 0;
    #2
    `assert(tos   , 8'h01);
    `assert(status, 2'b00);

    // Overflow
    op <= 1;
    #2
    `assert(tos   , 8'h01);
    `assert(status, 2'b11);

    // Pop
    op <= 2;
    #2
    // `assert(tos   , 8'h01);
    `assert(status, 2'b01);

    // Push & replace
    op   <= 1;
    data <= 2;
    #2
    `assert(tos   , 8'h02);
    `assert(status, 2'b00);

    op   <= 3;
    data <= 3;
    #2
    `assert(tos   , 8'h03);
    `assert(status, 2'b00);

    // Reset
    reset <= 1;
    #2
    // `assert(tos   , 8'h03);
    `assert(status, 2'b01);

    $display("ok");
    $finish;
  end

endmodule
