`default_nettype none


module MemoryController #(
  parameter RAM_WIDTH    = 8,
  parameter RAM_DEPTH    = 16,
  parameter MEM_WIDE_IN  = 1,  // Multiplied by RAM_WIDTH
  parameter MEM_WIDE_OUT = 1   // Multiplied by RAM_WIDTH
)
(
  input clk,

  // Memory
  input  write,
  output write_ready = 1,

  input      [             RAM_DEPTH -1:0] mem_address,
  input      [RAM_WIDTH*MEM_WIDE_IN  -1:0] mem_in,
  output reg [RAM_WIDTH*MEM_WIDE_OUT -1:0] mem_out,
  output reg [   $clog2(MEM_WIDE_OUT)-1:0] size,

  // RAM
  output reg [RAM_DEPTH-1:0] ram_address,
  inout      [RAM_WIDTH-1:0] ram_data,

  output ram_cs = 1,  // Disabled
  output ram_we = 1   // Read
);

  reg [RAM_DEPTH-1:0] ram_address_in;
  reg [RAM_DEPTH-1:0] mem_address_prev;

  reg [(RAM_WIDTH-1)*MEM_WIDE_IN-1:0] write_data;

  reg dataIsWrite [0:1];

  always @(posedge clk)
    dataIsWrite[1] <= dataIsWrite[0];

  // De-select the chip to allow it to enter into its energy-saving mode when
  // there's nothing to do
  always @(posedge clk)
    ram_cs <= write_ready && size == MEM_WIDE_OUT;

  // Stage 1 - Do request to RAM
  always @(posedge clk)
    // Writting data
    if(!ram_we) begin
      ram_address <= mem_address/(RAM_WIDTH/8) + size_in;
      ram_data    <= write_data[(RAM_WIDTH-size_in)*MEM_WIDE_IN-1 -: RAM_WIDTH];

      if(size_in < MEM_WIDE_IN-1)
        size_in <= size_in + 1;

      else begin
        write_ready <= 1;
        ram_we      <= 1;
      end
    end

    // Data to be written
    else if(write && write_ready) begin
      write_ready <= 0;
      ram_we      <= 0;

      // TODO allow to discard read requests if there's a new write one
      // TODO update read buffer with write data
      write_data  <= mem_in;

      ram_address <= mem_address/(RAM_WIDTH/8);
      ram_data    <= mem_in[RAM_WIDTH*MEM_WIDE_IN-1 -: RAM_WIDTH];

      size_in = 1;

      if(size_in == MEM_WIDE_IN) begin
        write_ready <= 1;
        ram_we      <= 1;
      end
    end

    // Changed read address
    else if(mem_address_prev != mem_address) begin
      write_ready <= 0;

      mem_address_prev <= mem_address;

      // New address is at the currently buffered ones, just fetch the
      // unbuffered data
      if(mem_address_prev < mem_address && mem_address < mem_address_prev+size)
        size = size - (mem_address - mem_address_prev);

      // New address is outside of the currently buffered ones, fetch everything
      else
        size = 0;

      ram_address <= mem_address/(RAM_WIDTH/8) + size;
    end

    // Fetch more data from RAM
    else if(size < MEM_WIDE_OUT-1)
      ram_address <= mem_address/(RAM_WIDTH/8) + size + 1;

    // There's no read operation in process, allow to write on next tick
    else
      write_ready <= 1;

  // Stage 2 - Fetch data from RAM
  always @(posedge clk) begin
    if(ram_we && mem_address_prev == mem_address && size < MEM_WIDE_OUT) begin
      // TODO Check when address changes to don't waste this fetch
      mem_out[RAM_WIDTH*(MEM_WIDE_OUT-size-1) -: RAM_WIDTH] <= ram_data;

      size <= size + 1;
    end
  end

endmodule // MemoryController
