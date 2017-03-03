/*
 * Stack
 *
 * (c) 2017 - Jesús Leganés-Combarro 'piranna' <piranna@gmail.com>
 *
 * Based on https://github.com/whitequark/bfcpu2/blob/master/verilog/Stack.v
 */

`default_nettype none

module Stack
#(
  parameter WIDTH = 8,  // bits
  parameter DEPTH = 8   // frames (exponential)
)
(
  input                    clk,
  input                    reset,
  input wire [1:0]         op,         // none / push / pop / replace
  input      [WIDTH - 1:0] data,       // Data to be inserted on the stack
  output reg [WIDTH - 1:0] tos,        // What's currently on the Top of Stack
  output reg [1:0]         status = 1  // none / empty / underflow / overflow
);

  localparam PUSH    = 1;
  localparam POP     = 2;
  localparam REPLACE = 3;

  localparam NONE      = 0;
  localparam EMPTY     = 1;
  localparam UNDERFLOW = 2;
  localparam OVERFLOW  = 3;

  localparam MAX_STACK  = 1 << DEPTH;

  reg [WIDTH - 1:0] stack [0:MAX_STACK - 1];
  reg [DEPTH - 1:0] index = 0;

  always @(posedge clk) begin
    if (reset) begin
      index <= 0;
      status <= EMPTY;
    end

    else
      case(op)
        PUSH:
        begin
          if (index == MAX_STACK)
            status <= OVERFLOW;
          else begin
            stack[index] <= data;

            index <= index + 1;

            tos <= data;
            status <= NONE;
          end
        end

        POP:
        begin
          if (index == 0)
            status <= UNDERFLOW;
          else begin
            index <= index - 1;

            tos <= stack[index - 1];
            status <= (index == 1) ? EMPTY : NONE;
          end
        end

        REPLACE:
        begin
          if (index == 0)
            status <= UNDERFLOW;
          else
            stack[index] <= data;

            tos <= data;
            status <= NONE;
        end
      endcase
  end

endmodule
