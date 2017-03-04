/**
 * Generic ROM memory
 *
 * (C) BQ. October 2015. Written by Juan Gonzalez (Obijuan)
 * GPL license
 *
 * Memory with the next parameters:
 * - AW: Number of bits for directions
 * - DW: Number of bits for data
 * - ROMFILE: File to be used to load the memory
 */

module genrom #(     // Parameters
  parameter AW = 5,  // Address width in bits
  parameter DW = 8   // Data witdh in bits
)
(                            // Ports
  input clk,                 // Global clock signal
  input wire [AW-1: 0] addr, // Address
  output reg [DW-1: 0] data  // Output data
);

  // Parameter: name of the file with the ROM content
  parameter ROMFILE = "prog.list";

  // Calc the number of total positions of memory
  localparam NPOS = 2 ** AW;

  // Memory
  reg [DW-1: 0] rom [0: NPOS-1];

  // Read the memory
  always @(posedge clk) begin
    data <= rom[addr];
  end

  // Load in memory the `ROMFILE` file. Values must be given in hexadecimal
  initial begin
    $readmemh(ROMFILE, rom);
  end

endmodule
