/*
 * SuperStack
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
  input      [DEPTH  :0] new_index,       // New index
  output reg [DEPTH  :0] index = 0,       // Current top of stack position
  output reg [WIDTH-1:0] out,             // top of stack, or output of getter
  output reg [WIDTH-1:0] out1,
  output reg [WIDTH-1:0] out2,
  output reg [      2:0] status = `EMPTY  // none / empty / full / underflow /
                                          // overflow / unknown_op
);

  localparam MAX_STACK = 1 << (DEPTH+1) - 1;

  reg [WIDTH-1:0] stack [0:MAX_STACK-1];

  // Adjust status when underflow limit has been changed
  function [2:0] getStatus([DEPTH:0] index);
    if(index == MAX_STACK)
      getStatus = `FULL;
    else if(index == underflow_limit)
      getStatus = `EMPTY;
    else if(index < underflow_limit)
      getStatus = `UNDERFLOW;
    else
      getStatus = `NONE;
  endfunction

  task setOutput;
    out  <= stack[index-1];
    out1 <= stack[index-2];
    out2 <= stack[index-3];

    status <= getStatus(index);
  endtask

  always @(posedge clk) begin
    if (reset) begin
      index  <= 0;
      status <= `EMPTY;
    end

    else
      case(op)
        `NONE: setOutput();

        `PUSH:
        begin
          if (index == MAX_STACK)
            status <= `OVERFLOW;
          else begin
            stack[index] = data;

            index = index + 1;

            setOutput();
          end
        end

        `POP:
        begin
          if (index-data <= underflow_limit)
            status <= `UNDERFLOW;
          else begin
            index = index - (1+data);

            setOutput();
          end
        end

        `REPLACE:
        begin
          if (index <= underflow_limit)
            status <= `UNDERFLOW;
          else begin
            stack[index-1] = data;

            setOutput();
          end
        end

        `INDEX_RESET:
        begin
          // New index is greater than current one
          if (index < new_index)
            status <= `BAD_INDEX;

          // New index is equal or lower than current one
          else begin
            index = new_index;

            status <= getStatus(index);
          end
        end

        `INDEX_RESET_AND_PUSH:
        begin
          // New index is greater than current one
          if (index < new_index)
            status <= `BAD_INDEX;

          // Both index and new index are equal to MAX_STACK
          else if (new_index == MAX_STACK)
            status <= `OVERFLOW;

          // New index is equal or lower than current index
          else begin
            stack[new_index] = data;

            index = new_index+1;

            setOutput();
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
          if (offset < index) begin
            stack[offset] = data;

            if(offset < index-1)
              status <= `NONE;

            // Update out if we are modifying ToS
            else
              setOutput();
          end

          // Setting over current index
          else if (index < offset)
            status <= `BAD_OFFSET;

          // Stack is full
          else if (offset == MAX_STACK)
            status <= `OVERFLOW;

          // Push to ToS
          else begin
            stack[offset] = data;

            index = index + 1;

            setOutput();
          end
        end
      endcase
  end

endmodule
