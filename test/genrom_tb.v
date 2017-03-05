`include "assert.vh"


module Genrom_tb();

  parameter DW = 8;

  reg             clk = 0;
  reg  [3:0]      addr;
  reg  [1:0]      len;
  wire [8*DW-1:0] data;
  wire            error;

  Genrom #(
    .AW(4)
  )
  dut(
    .clk(clk),
    .addr(addr),
    .len(len),
    .data(data),
    .error(error)
  );

  always #1 clk = ~clk;

  initial begin
    $dumpfile("genrom_tb.vcd");
    $dumpvars(0, Genrom_tb);

    addr <= 0;
    len  <= 0;
    #2
    `assert(data , 64'h81);
    `assert(error, 0);

    addr <= 1;
    len  <= 1;
    #2
    `assert(data , 64'h0082);
    `assert(error, 0);

    addr <= 3;
    len  <= 2;
    #2
    `assert(data , 64'h00840088);
    `assert(error, 0);

    addr <= 0;
    len  <= 3;
    #2
    `assert(data , 64'h8100820084008800);
    `assert(error, 0);

    addr <= 15;
    len  <= 0;
    #2
    `assert(error, 0);

    addr <= 15;
    len  <= 1;
    #2
    `assert(error, 1);

    $display("ok");
    $finish;
  end

endmodule
