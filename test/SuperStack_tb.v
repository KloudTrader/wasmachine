`include "assert.vh"

`include "stack.vh"


module SuperStack_tb();

  parameter WIDTH = 8;
  parameter DEPTH = 1;  // frames (exponential)

  localparam MAX_STACK = 1 << (DEPTH+1) - 1;

  reg              clk = 0;
  reg              reset;
  reg  [      1:0] op;
  reg  [WIDTH-1:0] data;
  reg  [DEPTH  :0] underflow_limit=0;
  wire [WIDTH-1:0] tos;
  wire [1:0]       status;

  SuperStack #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH)
  )
  dut(
    .clk(clk),
    .reset(reset),
    .op(op),
    .data(data),
    .underflow_limit(underflow_limit),
    .tos(tos),
    .status(status)
  );

  always #1 clk = ~clk;

  initial begin
    $dumpfile("SuperStack_tb.vcd");
    $dumpvars(0, SuperStack_tb);

    // `status` is `empty` by default
    `assert(status, `EMPTY);

    // Underflow
    op <= `POP;
    #2
    `assert(status, `UNDERFLOW);

    // Push
    op   <= `PUSH;
    data <= 0;
    #2
    `assert(status, `NONE);
    `assert(tos   , 8'h00);

    op   <= `PUSH;
    data <= 1;
    #2
    `assert(status, `NONE);
    `assert(tos   , 8'h01);

    op   <= `PUSH;
    data <= 2;
    #2
    `assert(status, `NONE);
    `assert(tos   , 8'h02);

    // Top of Stack
    op <= `NONE;
    #2
    `assert(status, `NONE);
    `assert(tos   , 8'h02);

    // Overflow
    op   <= `PUSH;
    data <= 3;
    #2
    `assert(status, `OVERFLOW);
    `assert(tos   , 8'h02);

    // Pop
    op <= `POP;
    #2
    `assert(status, `NONE);
    `assert(tos   , 8'h01);

    op <= `POP;
    #2
    `assert(status, `NONE);
    `assert(tos   , 8'h00);

    op <= `POP;
    #2
    `assert(status, `EMPTY);
//    `assert(tos   , 8'h00);

    // Replace
    op   <= `REPLACE;
    data <= 4;
    #2
    `assert(status, `UNDERFLOW);
//    `assert(tos   , 8'h00);

    op   <= `PUSH;
    data <= 5;
    #2
    `assert(status, `NONE);
    `assert(tos   , 8'h05);

    op   <= `REPLACE;
    data <= 6;
    #2
    `assert(status, `NONE);
    `assert(tos   , 8'h06);

    // Reset
    reset <= 1;
    #2
    reset <= 0;
    `assert(status, `EMPTY);
    `assert(tos   , 8'h06);

    //
    // Underflow limit
    //

    // Underflow after change limit
    op              <= `NONE;
    underflow_limit <= 2;
    #2
    `assert(status, `UNDERFLOW);
    `assert(tos   , 8'h06);

    // Push data while we are under the underflow limit
    op   <= `PUSH;
    data <= 7;
    #2
    `assert(status, `UNDERFLOW);
    `assert(tos   , 8'h07);

    // We push more data... and get an empty stack! Magic! :-P
    op   <= `PUSH;
    data <= 8;
    #2
    `assert(status, `EMPTY);
    `assert(tos   , 8'h08);

    // Reset with underflow limit set
    op   <= `PUSH;
    data <= 9;
    #2
    `assert(status, `NONE);
    `assert(tos   , 8'h09);

    reset <= 1;
    #2
    reset <= 0;
    `assert(status, `EMPTY);
    `assert(tos   , 8'h09);

    // Get underflow error when underflow limit is not zero (data is protected)
    op <= `POP;
    #2
    op <= `NONE;
    `assert(status, `UNDERFLOW);
    `assert(tos   , 8'h09);

    // Reset underflow limit, and now we can access the data
    underflow_limit <= 0;
    #2
    `assert(status, `NONE);
    `assert(tos   , 8'h08);

    // Get empty when index get zero
    op <= `POP;
    #2
    `assert(status, `NONE);
    `assert(tos   , 8'h07);
    #2
    `assert(status, `EMPTY);

    $finish;
  end

endmodule
