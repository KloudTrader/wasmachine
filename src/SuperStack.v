/*
 * Stack
 *
 * (c) 2017 - Jesús Leganés-Combarro 'piranna' <piranna@gmail.com>
 *
 * Based on https://github.com/whitequark/bfcpu2/blob/master/verilog/Stack.v
 */

`include "SuperStack.vh"


`default_nettype none

module SuperStack
#(
  parameter WIDTH = 8,  // bits
  parameter DEPTH = 7   // frames (exponential)
)
(
  input                  clk,
  input                  reset,
  input wire [      2:0] op,              // none / push / pop / replace /
                                          // underflow_reset / underflow_push /
                                          // underflow_get / underflow_set
  input      [WIDTH-1:0] data,            // Data to be inserted on the stack
  input      [DEPTH  :0] offset,          // position of getter/setter
  input      [DEPTH  :0] underflow_limit, // Depth of underflow error
  output reg [DEPTH  :0] index = 0,       // Current top of stack position
  output reg [WIDTH-1:0] out,             // top of stack, or output of getter
  output reg [      2:0] status = `EMPTY  // none / empty / full / underflow /
                                          // overflow / unknown_op
);

  localparam MAX_STACK = 1 << (DEPTH+1) - 1;

  reg [WIDTH-1:0] stack [0:MAX_STACK-1];

  always @(posedge clk) begin
    if (reset) begin
      index  <= 0;
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
            out <= stack[index-1];
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

            out <= data;

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

            out <= stack[index-1];
            status <= index == underflow_limit ? `EMPTY : `NONE;
          end
        end

        `REPLACE:
        begin
          if (index <= underflow_limit)
            status <= `UNDERFLOW;
          else begin
            stack[index-1] <= data;

            out <= data;
            status <= index == MAX_STACK ? `FULL : `NONE;
          end
        end

        `UNDERFLOW_RESET:
        begin
          // New underflow_limit is greater than current index
          if (index < underflow_limit)
            status <= `UNDERFLOW;

          // New underflow_limit is equal or lower than current index
          else begin
            index = underflow_limit;

            status <= index == MAX_STACK ? `FULL : `EMPTY;
          end
        end

        `UNDERFLOW_RESET_PUSH:
        begin
          // Underflow_limit is greater than current index
          if (index < underflow_limit) begin
            stack[index] <= data;

            index = index + 1;

            out <= data;

            // Adjust status when underflow limit has been changed
            if(index == MAX_STACK)
              status <= `FULL;
            else if(index == underflow_limit)
              status <= `EMPTY;
            else
              status <= `UNDERFLOW;
          end

          // Both index and underflow_limit are equal to MAX_STACK
          else if (underflow_limit == MAX_STACK)
            status <= `OVERFLOW;

          // Underflow_limit is equal or lower than current index
          else begin
            stack[underflow_limit] <= data;

            index = underflow_limit+1;

            out <= data;

            // Adjust status when underflow limit has been changed
            if(index == MAX_STACK)
              status <= `FULL;
            else if(index == underflow_limit)
              status <= `EMPTY;
            else
              status <= `NONE;
          end
        end

        `UNDERFLOW_GET:
        begin
          if (index <= offset)
            status <= `BAD_OFFSET;

          else begin
            out <= stack[offset];
            status <= `NONE;
          end
        end

        `UNDERFLOW_SET:
        begin
          if (index <= offset)
            status <= `BAD_OFFSET;

          else begin
            stack[offset] <= data;

            if(offset < index-1)
              status <= `NONE;

            // Update out if we are modifying ToS
            else begin
              out <= data;
              status <= index == MAX_STACK ? `FULL : `NONE;
            end
          end
        end
      endcase
  end

endmodule
