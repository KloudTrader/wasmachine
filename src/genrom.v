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

module Genrom #(     // Parameters
  parameter AW = 5,  // Address width in bits
  parameter DW = 8   // Data witdh in bits
)
(                               // Ports
  input clk,                    // Global clock signal
  input wire [AW-1: 0]   addr,  // Address
  input wire [1: 0]      len ,  // Length of data to be fetch
  output reg [8*DW-1: 0] data,  // Output data
  output reg             error  // none / len out of limits
);

  // Parameter: name of the file with the ROM content
  parameter ROMFILE = "prog.list";

  // Calc the number of total positions of memory
  localparam NPOS = 1 << AW;

  // Memory
  reg [DW-1: 0] rom [0: NPOS-1];

  // Read the memory
  always @(posedge clk) begin
    error <= (addr + (1 << len) - 1) >= NPOS;

    case (len)
      0: data <=  rom[addr  ];
      1: data <= {rom[addr  ], rom[addr+1]};
      2: data <= {rom[addr  ], rom[addr+1], rom[addr+2], rom[addr+3]};
      3: data <= {rom[addr  ], rom[addr+1], rom[addr+2], rom[addr+3],
                  rom[addr+4], rom[addr+5], rom[addr+6], rom[addr+7]};
    endcase
  end

  // Load in memory the `ROMFILE` file. Values must be given in hexadecimal
  initial begin
    $readmemh(ROMFILE, rom);
  end

endmodule
