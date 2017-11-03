`default_nettype none


module board
(
  input  wire       clk,
  input  wire       rstn_ini,
  output wire [3:0] leds,
  output wire       stop
);

  ram ram();

  wasmachine wasmachine();

endmodule
