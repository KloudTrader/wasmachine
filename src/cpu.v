`include "cpu.vh"

`include "opcodes.vh"
`include "SuperStack.vh"


`default_nettype none

module cpu
#(
  parameter ROM_ADDR = 4
)
(
  input  wire                clk,
  input  wire                reset,
  input  wire [ROM_ADDR-1:0] pc,
  output wire [        63:0] result,
  output wire [         1:0] result_type,
  output wire                result_empty,
  output reg  [         3:0] trap = `NONE
);

  // ROM
  parameter ROM_FILE = "prog.list";

  localparam ROM_WIDTH = 8;
  localparam ROM_EXTRA = 4;

  reg  [ROM_ADDR-1:0]               rom_addr;
  reg  [ROM_EXTRA-1:0]              rom_extra;
  wire [2**ROM_EXTRA*ROM_WIDTH-1:0] rom_data;
  wire                              rom_error;

  genrom #(
    .ROMFILE(ROM_FILE),
    .AW(ROM_ADDR),
    .DW(ROM_WIDTH),
    .EXTRA(ROM_EXTRA)
  )
  ROM (
    .clk(clk),
    .addr(rom_addr),
    .extra(rom_extra),
    .lower_bound(4'h0),
    .upper_bound(4'hf),
    .data(rom_data),
    .error(rom_error)
  );

  // Stack
  localparam STACK_WIDTH = 66;
  localparam STACK_DEPTH = 7;

  reg  [            2:0] stack_op;
  reg  [STACK_WIDTH-1:0] stack_data;
  reg  [STACK_DEPTH  :0] stack_underflow = 0;
  reg  [STACK_DEPTH  :0] stack_newIndex = 0;
  wire [STACK_DEPTH  :0] stack_index;
  wire [STACK_WIDTH-1:0] stack_out;
  wire [STACK_WIDTH-1:0] stack_out1;
  wire [STACK_WIDTH-1:0] stack_out2;
  wire [            2:0] stack_status;

  SuperStack #(
    .WIDTH(STACK_WIDTH),
    .DEPTH(STACK_DEPTH)
  )
  stack (
    .clk(clk),
    .reset(reset),
    .op(stack_op),
    .data(stack_data),
    .underflow_limit(stack_underflow),
    .new_index(stack_newIndex),
    .index(stack_index),
    .out(stack_out),
    .out1(stack_out1),
    .out2(stack_out2),
    .status(stack_status)
  );

  // Block stack
  localparam BLOCK_STACK_WIDTH = ROM_ADDR + 2 + 7 + 2*(STACK_DEPTH+1);
  localparam BLOCK_STACK_DEPTH = 3;

  reg  [                  2:0] blockStack_op;
  reg  [BLOCK_STACK_WIDTH-1:0] blockStack_data;
  reg  [BLOCK_STACK_DEPTH  :0] blockStack_underflow = 0;
  reg  [BLOCK_STACK_DEPTH  :0] blockStack_newIndex = 0;
  wire [BLOCK_STACK_DEPTH  :0] blockStack_index;
  wire [BLOCK_STACK_WIDTH-1:0] blockStack_out;
  wire [                  2:0] blockStack_status;

  SuperStack #(
    .WIDTH(BLOCK_STACK_WIDTH),
    .DEPTH(BLOCK_STACK_DEPTH)
  )
  blockStack (
    .clk(clk),
    .reset(reset),
    .op(blockStack_op),
    .data(blockStack_data),
    .new_index(blockStack_newIndex),
    .index(blockStack_index),
    .out(blockStack_out),
    .status(blockStack_status)
  );

  // Call stack
  localparam CALL_STACK_WIDTH = ROM_ADDR + 7 + 2*(BLOCK_STACK_DEPTH+1) + 2*(STACK_DEPTH+1);
  localparam CALL_STACK_DEPTH = 1;

  reg  [                 1:0] callStack_op;
  reg  [CALL_STACK_WIDTH-1:0] callStack_data;
  wire [CALL_STACK_WIDTH-1:0] callStack_out;
  wire [                 1:0] callStack_status;

  stack #(
    .WIDTH(CALL_STACK_WIDTH),
    .DEPTH(CALL_STACK_DEPTH)
  )
  callStack (
    .clk(clk),
    .reset(reset),
    .op(callStack_op),
    .data(callStack_data),
    .tos(callStack_out),
    .status(callStack_status)
  );

  // LEB128 - decoder of `varintN` values
  wire[63:0] leb128_out;
  wire[ 3:0] leb128_len;

  unpack_i64 leb128(rom_data[79:72], rom_data[71:64], rom_data[63:56],
                    rom_data[55:48], rom_data[47:40], rom_data[39:32],
                    rom_data[31:24], rom_data[23:16], rom_data[15: 8],
                    rom_data[ 7: 0], leb128_out, leb128_len);

  // Double to Float

  wire        double_to_float_a_ack;
  reg         double_to_float_a_stb;
  wire [31:0] double_to_float_z;
  wire        double_to_float_z_stb;
  reg         double_to_float_z_ack;

  double_to_float d2f(
    .clk(clk),
    .rst(reset),
    .input_a_ack(double_to_float_a_ack),
    .input_a(stack_out[63:0]),
    .input_a_stb(double_to_float_a_stb),
    .output_z(double_to_float_z),
    .output_z_stb(double_to_float_z_stb),
    .output_z_ack(double_to_float_z_ack)
  );

  // Continuous assignments & wire aliases
  assign result       = stack_out[63: 0];
  assign result_type  = stack_out[65:64];
  assign result_empty = stack_status == `EMPTY;

  wire[31:0] rom_data_PC = rom_data[71:40];

  wire[ ROM_ADDR-1:0] blockStack_out_PC         = blockStack_out[ROM_ADDR-1+9+2*(1+STACK_DEPTH)  :9+2*(1+STACK_DEPTH)];
  wire[          1:0] blockStack_out_type       = blockStack_out[           8+2*(1+STACK_DEPTH)  :7+2*(1+STACK_DEPTH)];
  wire[          6:0] blockStack_out_returnType = blockStack_out[           6+2*(1+STACK_DEPTH)  :  2*(1+STACK_DEPTH)];
  wire[STACK_DEPTH:0] blockStack_out_index      = blockStack_out[             2*(1+STACK_DEPTH)-1:     1+STACK_DEPTH ];
  wire[STACK_DEPTH:0] blockStack_out_underflow  = blockStack_out[                  STACK_DEPTH   :                  0];

  wire[ ROM_ADDR-1:0] callStack_out_PC             = callStack_out[ROM_ADDR-1+7+2*(BLOCK_STACK_DEPTH+1)+2*(STACK_DEPTH+1)  :7+2*(BLOCK_STACK_DEPTH+1)+2*(STACK_DEPTH+1)];
  wire[          6:0] callStack_out_returnType     = callStack_out[           6+2*(BLOCK_STACK_DEPTH+1)+2*(STACK_DEPTH+1)  :  2*(BLOCK_STACK_DEPTH+1)+2*(STACK_DEPTH+1)];
  wire[STACK_DEPTH:0] callStack_out_blockIndex     = callStack_out[             2*(BLOCK_STACK_DEPTH+1)+2*(STACK_DEPTH+1)-1:     BLOCK_STACK_DEPTH+1 +2*(STACK_DEPTH+1)];
  wire[STACK_DEPTH:0] callStack_out_blockUnderflow = callStack_out[                BLOCK_STACK_DEPTH+1 +2*(STACK_DEPTH+1)-1:                          2*(1+STACK_DEPTH)];
  wire[STACK_DEPTH:0] callStack_out_index          = callStack_out[                                     2*(1+STACK_DEPTH)-1:                             1+STACK_DEPTH ];
  wire[STACK_DEPTH:0] callStack_out_underflow      = callStack_out[                                          STACK_DEPTH   :                                          0];

  // CPU internal status
  localparam FETCH  = 3'b000;
  localparam FETCH2 = 3'b001;
  localparam EXEC   = 3'b010;
  localparam EXEC2  = 3'b011;
  localparam EXEC3  = 3'b100;
  localparam EXEC4  = 3'b101;

  reg [2:0]          step = FETCH;
  reg [ROM_ADDR-1:0] PC   = 0;
  reg [7:0]          opcode;

  logic [STACK_WIDTH - 1:0] stack_aux1, stack_aux2;

  task call_return;
    // Set program counter to next instruction after function call
    PC <= callStack_out_PC;

    // Reset stacks
    callStack_op   <= `POP;
    callStack_data <= 0;

    blockStack_newIndex  <= callStack_out_blockIndex;
    blockStack_underflow <= callStack_out_blockUnderflow;
    blockStack_op        <= `INDEX_RESET;

    stack_newIndex  <= blockStack_out_index;
    stack_underflow <= blockStack_out_underflow;

    // Check type and set result value
    if(callStack_out_returnType == 7'h40)
      stack_op <= `INDEX_RESET;

    // TODO Get and check function return types
    // else if(7'h7f - callStack_out_returnType == stack_out[65:64]) begin
    else if(1) begin
      stack_op   <= `INDEX_RESET_AND_PUSH;
      stack_data <= stack_out;
    end

    else
      trap <= `TYPE_MISMATCH;
  endtask

  task block_return;
    reg [65:0] data;
    data = (opcode == `op_br_if) ? stack_out1 : stack_out;

    // Set program counter to next instruction after block
    PC <= blockStack_out_PC;

    // Reset stacks
    blockStack_op   <= `POP;
    blockStack_data <= 0;

    stack_newIndex  <= blockStack_out_index;
    stack_underflow <= blockStack_out_underflow;

    // Check type and set result value
    if(blockStack_out_returnType == 7'h40)
      stack_op <= `INDEX_RESET;

    // TODO Get and check function return types
    // else if(7'h7f - blockStack_out_returnType == data[65:64]) begin
    else if(1) begin
      stack_op   <= `INDEX_RESET_AND_PUSH;
      stack_data <= data;
    end

    else
      trap <= `TYPE_MISMATCH;
  endtask

  task block_break;
    input [31:0] depth;

    // Break to outter block, remove inner ones first
    if(depth) begin
      blockStack_op   <= `POP;
      blockStack_data <= depth-1;  // Remove all slices except the desired one

      step <= EXEC2;
    end

    // Current block
    else
      block_break2();
  endtask

  task block_break2;
    if(blockStack_status == `EMPTY) begin
      if(callStack_status == `EMPTY)
        trap <= `CALL_STACK_EMPTY;

      else
        call_return();
    end

    else
      case (blockStack_out_type)
        `block     : block_return();
        `block_loop: block_loop_back();

        default:
          trap <= `BAD_BLOCK_TYPE;
      endcase
  endtask

  // Main loop
  always @(posedge clk) begin
    if(reset) begin
      trap <= `NONE;
      step <= FETCH;
      PC   <= pc;
      stack_underflow <= 0;
      stack_newIndex <= 0;
    end

    else if(!trap) begin
      stack_op <= `NONE;
      blockStack_op <= `NONE;

      case (step)
        FETCH: begin
          rom_addr  <= PC;
          rom_extra <= 10;

          PC <= PC+1;
          step <= FETCH2;
        end

        FETCH2: begin
          if(stack_status > `EMPTY) trap <= `STACK_ERROR;

          else
            step <= EXEC;
        end

        EXEC: begin
          if(rom_error) trap <= `ROM_ERROR;

          else begin
            step <= FETCH;

            opcode = rom_data[87:80];

            // Operations
            case (opcode)
              // Control flow operators
              `op_unreachable: begin
                trap <= `UNREACHABLE;
              end

              `op_nop: begin
              end

              `op_block: begin
                // Store current status on the blocks stack
                blockStack_op   <= `PUSH;
                // TODO should we use relative addresses for destination?
                blockStack_data <= {rom_data_PC, `block, leb128_out[6:0],
                                    stack_index, stack_underflow};

                // Set an empty stack for the called block
                stack_underflow <= stack_index;

                PC <= PC+5;
              end

              `op_end: begin
                // Main call (`start`, `export`), return results and halt
                if(callStack_status == `EMPTY)
                  trap <= `ENDED;

                // Function
                else if(blockStack_status == `EMPTY)
                  call_return();

                // Block or if
                else
                  block_return();
              end

              `op_br: begin
                if(blockStack_status == `EMPTY) begin
                  if(leb128_out)
                    trap <= `BLOCK_STACK_EMPTY;

                  else if(callStack_status == `EMPTY)
                    trap <= `CALL_STACK_EMPTY;

                  else
                    block_return();
                end

                else
                  block_break(leb128_out);
              end

              `op_br_if: begin
                // TODO break functions
                if(blockStack_status == `EMPTY)
                  trap <= `BLOCK_STACK_EMPTY;

                else if(stack_status == `EMPTY)
                  trap <= `STACK_EMPTY;

                else if(stack_out[65:64] != `i32)
                  trap <= `TYPE_MISMATCH;

                else if(stack_out[31:0])
                  block_break(leb128_out);
              end

              `op_return: begin
                // Returning from main call (`start`, `export`), return results and halt
                if(callStack_status == `EMPTY)
                  trap <= `ENDED;

                // Returning from a function call
                else
                  call_return();
              end

              // Call operators
              `op_call: begin
                rom_addr  <= leb128_out;  //1+leb128_out;
                rom_extra <= 10;  // 5

                // Store block stack index on the call stack
                callStack_op   <= `PUSH;
                callStack_data <= blockStack_index;

                // Store current return status on the block stack
                blockStack_op   <= `PUSH;
                // TODO Spec says "A direct call to a function with a mismatched
                //      signature is a module verification error". Should return
                //       value be verified, or it's already done at loading?
                // TODO get function return value
                // TODO substract function arguments
                blockStack_data <= {PC+leb128_len, `block_function, 7'b0,
                                    stack_index-8'b0, stack_underflow};

                // Set an empty stack for the called function
                stack_underflow <= stack_index;

                step <= EXEC2;
              end

              // Parametric operators
              `op_drop: begin
                stack_op   <= `POP;
                stack_data <= 0;
              end

              // Variable access

              // Memory-related operators

              // Constants
              `op_i32_const: begin
                stack_op <= `PUSH;
                stack_data <= {`i32, leb128_out};

                PC <= PC+leb128_len;
              end

              `op_i64_const: begin
                stack_op <= `PUSH;
                stack_data <= {`i64, leb128_out};

                PC <= PC+leb128_len;
              end

              `op_f32_const: begin
                stack_op <= `PUSH;
                stack_data <= {`f32, 32'b0, rom_data[79:48]};

                PC <= PC+4;
              end

              `op_f64_const: begin
                stack_op <= `PUSH;
                stack_data <= {`f64, rom_data[79:16]};

                PC <= PC+8;
              end

              // Comparison operators
              `op_i32_eqz: begin
                if(stack_out[65:64] != `i32)
                  trap <= `TYPE_MISMATCH;

                else begin
                  stack_op <= `REPLACE;
                  stack_data <= {`i32, 32'b0, stack_out[31:0] ? 32'b0 : 32'b1};
                end
              end

              `op_i64_eqz: begin
                if(stack_out[65:64] != `i64)
                  trap <= `TYPE_MISMATCH;

                else begin
                  stack_op <= `REPLACE;
                  stack_data <= {`i64, stack_out[63:0] ? 64'b0 : 64'b1};
                end
              end

              // Numeric operators

              // Conversions
              `op_f32_demote_f64: begin
                double_to_float_a_stb <= 0;
                double_to_float_z_ack <= 0;

                if(stack_out[65:64] != `f64)
                  trap <= `TYPE_MISMATCH;

                else if(double_to_float_z_stb) begin
                  stack_op   <= `REPLACE;
                  stack_data <= {`f32, 32'b0, double_to_float_z};

                  double_to_float_z_ack <= 1;
                end

                else begin
                  if(double_to_float_a_ack)
                    double_to_float_a_stb <= 1;

                  // Wait at the same step until the FPU is ready
                  step <= EXEC;
                end
              end

              // Reinterpretations
              `op_i32_reinterpret_f32: begin
                if(stack_out[65:64] != `i32)
                  trap <= `TYPE_MISMATCH;

                else begin
                  stack_op <= `REPLACE;
                  stack_data <= {`f32, stack_out[63:0]};
                end
              end

              // Binary and ternary operations
              `op_select,
              `op_i32_eq,
              `op_i32_ne,
              `op_i64_eq,
              `op_i64_ne,
              `op_i32_add,
              `op_i32_sub,
              `op_i64_add,
              `op_i64_sub:
              begin
                stack_aux1 <= stack_out;
                stack_op   <= `POP;
                stack_data <= 0;

                step <= EXEC2;
              end

              // Unknown opcode
              default:
                trap <= `UNKOWN_OPCODE;
            endcase
          end
        end

        EXEC2: begin
          step <= EXEC3;

          case (opcode)
            // Parametric operators
            `op_select: begin
              // Remove first operator from stack on next tick after condition
              // gets removed
              stack_op   <= `POP;
              stack_data <= 0;
            end
          endcase
        end

        EXEC3: begin
          step <= FETCH;

          case (opcode)
            // Control flow operators
            `op_br,
            `op_br_if: begin
              if(blockStack_status > `EMPTY)
                trap <= `CALL_STACK_ERROR;

              else
                block_break2();
            end

            // Call operators
            `op_call: begin
              PC <= leb128_out;
            end

            // Parametric operators
            `op_select: begin
              // Store first operator before gets removed from stack and after
              // condition has been already removed
              stack_aux2 <= stack_out;

              step <= EXEC4;
            end

            // Comparison operators
            `op_i32_eq:
            begin
              if(stack_aux1[65:64] != `i32 || stack_out[65:64] != `i32)
                trap <= `TYPE_MISMATCH;

              else begin
                stack_op   <= `REPLACE;
                stack_data <= {`i32, (stack_aux1[31:0] == stack_out[31:0]) ? 64'b1 : 64'b0};
              end
            end

            `op_i32_ne:
            begin
              if(stack_aux1[65:64] != `i32 || stack_out[65:64] != `i32)
                trap <= `TYPE_MISMATCH;

              else begin
                stack_op   <= `REPLACE;
                stack_data <= {`i32, (stack_aux1[31:0] != stack_out[31:0]) ? 64'b1 : 64'b0};
              end
            end

            `op_i64_eq:
            begin
              if(stack_aux1[65:64] != `i64 || stack_out[65:64] != `i64)
                trap <= `TYPE_MISMATCH;

              else begin
                stack_op   <= `REPLACE;
                stack_data <= {`i64, (stack_aux1[63:0] == stack_out[63:0]) ? 64'b1 : 64'b0};
              end
            end

            `op_i64_ne:
            begin
              if(stack_aux1[65:64] != `i64 || stack_out[65:64] != `i64)
                trap <= `TYPE_MISMATCH;

              else begin
                stack_op   <= `REPLACE;
                stack_data <= {`i64, (stack_aux1[63:0] != stack_out[63:0]) ? 64'b1 : 64'b0};
              end
            end

            // Numeric operators
            `op_i32_add:
            begin
              if(stack_aux1[65:64] != `i32 || stack_out[65:64] != `i32)
                trap <= `TYPE_MISMATCH;

              else begin
                stack_op   <= `REPLACE;
                stack_data <= {`i32, stack_aux1[31:0] + stack_out[31:0]};
              end
            end

            `op_i32_sub:
            begin
              if(stack_aux1[65:64] != `i32 || stack_out[65:64] != `i32)
                trap <= `TYPE_MISMATCH;

              else begin
                stack_op   <= `REPLACE;
                stack_data <= {`i32, stack_out[31:0] - stack_aux1[31:0]};
              end
            end

            `op_i64_add:
            begin
              if(stack_aux1[65:64] != `i64 || stack_out[65:64] != `i64)
                trap <= `TYPE_MISMATCH;

              else begin
                stack_op   <= `REPLACE;
                stack_data <= {`i64, stack_aux1[63:0] + stack_out[63:0]};
              end
            end

            `op_i64_sub:
            begin
              if(stack_aux1[65:64] != `i64 || stack_out[65:64] != `i64)
                trap <= `TYPE_MISMATCH;

              else begin
                stack_op   <= `REPLACE;
                stack_data <= {`i64, stack_out[63:0] - stack_aux1[63:0]};
              end
            end
          endcase
        end

        EXEC4: begin
          step <= FETCH;

          case (opcode)
            // Parametric operators
            `op_select: begin
              // Validate both operators are of the same type
              if(stack_aux2[65:64] != stack_out[65:64])
                trap <= `TYPES_MISMATCH;

              else begin
                // Condition is true, replace second operator with first one (we
                // have just got it, and at the same time it will be removed
                // from the stack on the next cycle due to `EXEC2`)
                if(stack_aux1) begin
                  stack_op <= `REPLACE;
                  stack_data <= stack_aux2;
                end

                // Second operator is already on tos, so there's no need to do
                // anything with it
              end
            end
          endcase
        end
      endcase
    end
  end
endmodule
