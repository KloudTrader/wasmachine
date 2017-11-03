/**
 * Based on https://github.com/Obijuan/open-fpga-verilog-tutorial/wiki/Cap%C3%ADtulo-15:-Divisor-de-frecuencias
 */

module divM
#(
  parameter M = 2
)
(
  input  wire clk_in,
  output wire clk_out
);

localparam N = $clog2(M);

reg [N-1:0] counter = 0;

always @(posedge clk_in)
  counter <= (counter == M-1) ? 0 : counter+1;

assign clk_out = counter[N-1];

endmodule
