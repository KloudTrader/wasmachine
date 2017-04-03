`include "assert.vh"

`include "SuperStack.vh"


module SuperStack_tb();

  parameter WIDTH = 8;
  parameter DEPTH = 1;  // frames (exponential)

  localparam MAX_STACK = 1 << (DEPTH+1) - 1;

  reg              clk = 0;
  reg              reset;
  reg  [      2:0] op;
  reg  [WIDTH-1:0] data;
  reg  [DEPTH  :0] offset;
  reg  [DEPTH  :0] underflow_limit=0;
  reg  [DEPTH  :0] new_index;
  wire [DEPTH  :0] index;
  wire [WIDTH-1:0] out;
  wire [      2:0] status;

  SuperStack #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH)
  )
  dut(
    .clk(clk),
    .reset(reset),
    .op(op),
    .data(data),
    .offset(offset),
    .underflow_limit(underflow_limit),
    .new_index(new_index),
    .index(index),
    .out(out),
    .status(status)
  );

  always #1 clk = ~clk;

  initial begin
    $dumpfile("SuperStack_tb.vcd");
    $dumpvars(0, SuperStack_tb);

    // `status` is `empty` by default
    `assert(status, `EMPTY);

    // Underflow
    op   <= `POP;
    data <= 0;
    #2
    `assert(status, `UNDERFLOW);

    // Push
    op   <= `PUSH;
    data <= 0;
    #2
    `assert(status, `NONE);
    `assert(out   , 8'h00);

    op   <= `PUSH;
    data <= 1;
    #2
    `assert(status, `FULL);
    `assert(out   , 8'h01);

    // Top of Stack
    op <= `NONE;
    #2
    `assert(status, `FULL);
    `assert(out   , 8'h01);

    // Overflow
    op   <= `PUSH;
    data <= 2;
    #2
    `assert(status, `OVERFLOW);
    `assert(out   , 8'h01);

    // Pop
    op   <= `POP;
    data <= 0;
    #2
    `assert(status, `NONE);
    `assert(out   , 8'h00);

    op   <= `POP;
    data <= 0;
    #2
    `assert(status, `EMPTY);
    // `assert(out   , 8'h00);

    // Replace
    op   <= `REPLACE;
    data <= 4;
    #2
    `assert(status, `UNDERFLOW);
    // `assert(out   , 8'h00);

    op   <= `PUSH;
    data <= 5;
    #2
    `assert(status, `NONE);
    `assert(out   , 8'h05);

    op   <= `REPLACE;
    data <= 6;
    #2
    `assert(status, `NONE);
    `assert(out   , 8'h06);

    op <= `NONE;
    #2
    `assert(status, `NONE);
    `assert(out   , 8'h06);

    // Reset
    reset <= 1;
    #2
    reset <= 0;
    `assert(status, `EMPTY);
    `assert(out   , 8'h06);
    `assert(index , 0);

    //
    // Underflow limit
    //

    // Underflow after change limit
    op              <= `NONE;
    underflow_limit <= 1;
    #2
    `assert(status, `UNDERFLOW);
    // `assert(out   , 8'h06);
    `assert(index , 0);

    // Push data while we are under the underflow limit...
    // and get an empty stack! Magic! :-P
    op   <= `PUSH;
    data <= 8;
    #2
    `assert(status, `EMPTY);
    `assert(out   , 8'h08);
    `assert(index , 1);

    // Reset with underflow limit set
    op   <= `PUSH;
    data <= 9;
    #2
    `assert(status, `FULL);
    `assert(out   , 8'h09);
    `assert(index , 2);

    op <= `INDEX_RESET;
    new_index <= 1;
    #2
    `assert(status, `EMPTY);
    `assert(out   , 8'h09);
    `assert(index , 1);

    // Get underflow error when underflow limit is not zero (data is protected)
    op   <= `POP;
    data <= 0;
    #2
    op <= `NONE;
    `assert(status, `UNDERFLOW);
    `assert(out   , 8'h09);
    `assert(index , 1);

    // Reset underflow limit, and now we can access the data
    underflow_limit <= 0;
    #2
    `assert(status, `NONE);
    `assert(out   , 8'h08);
    `assert(index , 1);

    // Get empty when index get zero
    op   <= `POP;
    data <= 0;
    #2
    `assert(status, `EMPTY);
    `assert(index , 0);

    // Underflow reset push
    underflow_limit <= 2;
    op <= `INDEX_RESET_AND_PUSH;
    data <= 10;
    new_index <= 0;
    #2
    `assert(status, `UNDERFLOW);
    `assert(out   , 8'h0a);
    `assert(index , 1);

    underflow_limit <= 0;
    op <= `INDEX_RESET_AND_PUSH;
    data <= 11;
    #2
    `assert(status, `NONE);
    `assert(out   , 8'h0b);
    `assert(index , 1);

    // Underfow get
    offset <= 0;
    op <= `UNDERFLOW_GET;
    #2
    `assert(status, `NONE);
    `assert(out   , 8'h0b);
    `assert(index , 1);

    // Underfow set
    offset <= 0;
    op <= `UNDERFLOW_SET;
    data <= 12;
    #2
    `assert(status, `NONE);
    `assert(out   , 8'h0c);
    `assert(index , 1);

    $finish;
  end

endmodule
