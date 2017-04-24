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
                                          // index_reset / index_push /
                                          // underflow_get / underflow_set
  input      [WIDTH-1:0] data,            // Data to be inserted on the stack
  input      [DEPTH  :0] offset,          // position of getter/setter/new index
  input      [DEPTH  :0] underflow_limit, // Depth of underflow error
  input      [DEPTH  :0] upper_limit,     // Underflow get/set upper limit
  input      [DEPTH  :0] lower_limit,     // Underflow get/set lower limit
  input                  dropTos,
  output reg [DEPTH  :0] index = 0,       // Current top of stack position
  output reg [WIDTH-1:0] out,             // top of stack, or output of getter
  output reg [WIDTH-1:0] out1,
  output reg [WIDTH-1:0] out2,
  output reg [      2:0] status = `EMPTY  // none / empty / full / underflow /
                                          // overflow / unknown_op
);

  localparam MAX_STACK = (1 << DEPTH+1) - 1;

  reg [WIDTH-1:0] stack [0:MAX_STACK-1];
  reg [DEPTH  :0] i;

  task setOutput;
    out  <= stack[index-1];
    out1 <= stack[index-2];
    out2 <= stack[index-3];

    // Adjust status when underflow limit has been changed
    if(index == MAX_STACK)
      status <= `FULL;
    else if(index == underflow_limit)
      status <= `EMPTY;
    else if(index < underflow_limit)
      status <= `UNDERFLOW;
    else
      status <= `NONE;
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
          // Stack is full
          if (index == MAX_STACK)
            status <= `OVERFLOW;

          // Push data to ToS
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
          // New index is greater than current one, fill with zeroes
          for(i=index; i < offset; i = i + 1)
            stack[i] = 0;

          index = offset;

          setOutput();
        end

        `INDEX_RESET_AND_PUSH:
        begin
          // New index is equal to MAX_STACK, raise error
          if (offset == MAX_STACK)
            status <= `OVERFLOW;

          else begin
            // New index is greater than current one, fill with zeroes
            for(i=index; i < offset; i = i + 1)
              stack[i] = 0;

            stack[offset] = data;

            index = offset+1;

            setOutput();
          end
        end

        `UNDERFLOW_GET:
        begin
          if (upper_limit - lower_limit <= offset)
            status <= `BAD_OFFSET;

          else begin
            out <= stack[lower_limit + offset];
            status <= `NONE;
          end
        end

        `UNDERFLOW_SET:
        begin
          if (upper_limit - lower_limit <= offset)
            status <= `BAD_OFFSET;

          else if(dropTos && index == underflow_limit)
            status <= `UNDERFLOW;

          else begin
            stack[lower_limit + offset] = data;

            if(dropTos) index = index - 1;

            setOutput();
          end
        end
      endcase
  end

endmodule
