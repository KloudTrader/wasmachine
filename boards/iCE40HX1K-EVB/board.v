`default_nettype none


module board
(
  input wire sysclk,
  input wire reset,

  output wire [2:1] leds,
  input  wire [2:1] buttons,

  output wire        sram_cs,
  output wire        sram_oe = 0,  // Enabled
  output wire        sram_we,
  inout  wire [15:0] sd,
  output wire [17:0] sa
);

  localparam RAM_WIDTH    = 16;
  localparam RAM_DEPTH    = 18;  // 256K * 16 = 512KB
  localparam MEM_WIDE_IN  = 4;
  localparam MEM_WIDE_OUT = 7;

  //
  // Memory controller
  //

  MemoryController #(
    .RAM_WIDTH(RAM_WIDTH),
    .RAM_DEPTH(RAM_DEPTH),
    .MEM_WIDTH_IN(MEM_WIDTH_IN),
    .MEM_WIDTH_OUT(MEM_WIDTH_OUT)
  )
  memoryController (
    .clk(sysclk),
    .ram_address(sa),
    .ram_data(sd),
    .ram_we(sram_we)
  );


  //
  // CPU
  //

  divM #(
    .M(8)  // 12.5MHz
  )
  divClk (
    .clk_in(sysclk),
    .clk_out(clk)
  );

  wasmachine #(
    .MEM_WIDTH(MEM_WIDTH)
  )
  wasmachine
  (
    .clk(clk),
    .reset(reset),
    .mem_address(mem_address),
    .mem_data(mem_data),
    .mem_size(mem_size)
  );

endmodule
