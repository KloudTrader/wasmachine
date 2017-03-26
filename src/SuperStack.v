/*
 * Stack
 *
 * (c) 2017 - Jesús Leganés-Combarro 'piranna' <piranna@gmail.com>
 *
 * Based on https://github.com/whitequark/bfcpu2/blob/master/verilog/Stack.v
 */

`include "stack.vh"


`default_nettype none

module SuperStack
#(
  parameter WIDTH = 8,  // bits
  parameter DEPTH = 7   // frames (exponential)
)
(
  input                  clk,
  input                  reset,
  input wire [      1:0] op,              // none / push / pop / replace
  input      [WIDTH-1:0] data,            // Data to be inserted on the stack
  input      [DEPTH  :0] underflow_limit, // Depth of underflow error
  output reg [WIDTH-1:0] tos,             // What's currently on the Top of Stack
  output reg [      2:0] status = `EMPTY  // none / empty / full / underflow /
                                          // overflow
);

  localparam MAX_STACK = 1 << (DEPTH+1) - 1;

  reg [WIDTH-1:0] stack [0:MAX_STACK-1];
  reg [  DEPTH:0] index = 0;

  always @(posedge clk) begin
    if (reset) begin
      index  <= underflow_limit;
      status <= `EMPTY;
    end

    else
      case(op)
        `NONE:
        begin
          // Adjust status when underflow limit has been changed
          if(index < underflow_limit)
            status <= `UNDERFLOW;
          else if(index == underflow_limit)
            status <= `EMPTY;
          else begin
            tos <= stack[index-1];
            status <= index == MAX_STACK ? `FULL : `NONE;
          end
        end

        `PUSH:
        begin
          if (index == MAX_STACK)
            status <= `OVERFLOW;
          else begin
            stack[index] <= data;

            index = index + 1;

            tos <= data;

            // Adjust status when underflow limit has been changed
            if(index == MAX_STACK)
              status <= `FULL;
            else if(index == underflow_limit)
              status <= `EMPTY;
            else if(index < underflow_limit)
              status <= `UNDERFLOW;
            else
              status <= `NONE;
          end
        end

        `POP:
        begin
          if (index <= underflow_limit)
            status <= `UNDERFLOW;
          else begin
            index = index - 1;

            tos <= stack[index-1];  // HACK Should not have `-1`
            status <= index == underflow_limit ? `EMPTY : `NONE;
          end
        end

        `REPLACE:
        begin
          if (index <= underflow_limit)
            status <= `UNDERFLOW;
          else begin
            stack[index-1] <= data;

            tos <= data;
            status <= index == MAX_STACK ? `FULL : `NONE;
          end
        end
      endcase
  end

endmodule
