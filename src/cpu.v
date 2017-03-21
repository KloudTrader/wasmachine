`include "cpu.vh"

`include "opcodes.vh"
`include "stack.vh"


`default_nettype none

module cpu
(
  input  wire        clk,
  input  wire        reset,
  output reg  [63:0] result,
  output reg  [ 1:0] result_type,
  output reg         result_empty,
  output reg  [ 2:0] trap = 0
);

  // ROM
  parameter ROM_FILE = "prog.list";
  parameter ROM_ADDR = 4;

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
    .data(rom_data),
    .error(rom_error)
  );

  // Stack
  localparam STACK_WIDTH = 66;
  localparam STACK_DEPTH = 8;

  reg  [1:0]               stack_op;
  reg  [STACK_WIDTH - 1:0] stack_data;
  wire [STACK_WIDTH - 1:0] stack_tos;
  wire [1:0]               stack_status;

  stack #(
    .WIDTH(STACK_WIDTH),
    .DEPTH(STACK_DEPTH)
  )
  stack (
    .clk(clk),
    .reset(reset),
    .op(stack_op),
    .data(stack_data),
    .tos(stack_tos),
    .status(stack_status)
  );

  // LEB128 - decoder of `varintN` values
  reg [ 7:0] leb128_i0, leb128_i1, leb128_i2, leb128_i3, leb128_i4, leb128_i5,
             leb128_i6, leb128_i7, leb128_i8, leb128_i9;
  wire[63:0] leb128_out;
  wire[ 3:0] leb128_len;

  unpack_i64 leb128(leb128_i0, leb128_i1, leb128_i2, leb128_i3, leb128_i4,
                    leb128_i5, leb128_i6, leb128_i7, leb128_i8, leb128_i9,
                    leb128_out, leb128_len);

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

  // Main loop
  always @(posedge clk) begin
    if(reset) begin
      trap <= 0;
      step <= FETCH;
      PC   <= 0;
    end

    else if(!trap) begin
      stack_op <= `NONE;

      case (step)
        FETCH: begin
          rom_addr  <= PC;
          rom_extra <= 10;

          PC <= PC+1;
          step <= FETCH2;
        end

        FETCH2: begin
          if(stack_status > `EMPTY) trap <= 1;

          else
            step <= EXEC;
        end

        EXEC: begin
          if(rom_error) trap <= 2;

          else begin
            step <= FETCH;

            opcode = rom_data[87:80];

            // Operations
            case (opcode)
              // Control flow operators
              `op_unreachable: begin
                trap <= 3;
              end

              `op_nop: begin
              end

              `op_end: begin
                result <= stack_tos[63:0];
                result_type <= stack_tos[65:64];
                result_empty <= stack_status == `EMPTY;
              end

              // Call operators

              // Parametric operators
              `op_drop: begin
                stack_op <= `POP;
              end

              `op_select: begin
                // Store condition for checking and remove it from the stack
                stack_aux1 <= stack_tos;
                stack_op <= `POP;

                step <= EXEC2;
              end

              // Constants
              `op_i32_const: begin
                leb128_i0 <= rom_data[79:72]; leb128_i1 <= rom_data[71:64];
                leb128_i2 <= rom_data[63:56]; leb128_i3 <= rom_data[55:48];
                leb128_i4 <= rom_data[47:40];
                leb128_i5 <= 0; leb128_i6 <= 0; leb128_i7 <= 0; leb128_i8 <= 0;
                leb128_i9 <= 0;

                step <= EXEC2;
              end

              `op_i64_const: begin
                leb128_i0 <= rom_data[79:72]; leb128_i1 <= rom_data[71:64];
                leb128_i2 <= rom_data[63:56]; leb128_i3 <= rom_data[55:48];
                leb128_i4 <= rom_data[47:40]; leb128_i5 <= rom_data[39:32];
                leb128_i6 <= rom_data[31:24]; leb128_i7 <= rom_data[23:16];
                leb128_i8 <= rom_data[15: 8]; leb128_i9 <= rom_data[ 7: 0];

                step <= EXEC2;
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
                stack_op <= `REPLACE;
                stack_data <= {`i32, 32'b0, stack_tos[31:0] ? 32'b0 : 32'b1};
              end

              `op_i64_eqz: begin
                stack_op <= `REPLACE;
                stack_data <= {`i64, stack_tos[63:0] ? 64'b0 : 64'b1};
              end

              // Reinterpretations
              `op_i32_reinterpret_f32: begin
                stack_op <= `REPLACE;
                stack_data <= {`f32, stack_tos[63:0]};
              end

              // Unknown opcode
              default:
                trap <= 4;
            endcase
          end
        end

        EXEC2: begin
          step <= FETCH;

          case (opcode)
            // Parametric operators
            `op_select: begin
              // Remove first operator from stack
              stack_op <= `POP;

              step <= EXEC3;
            end

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
          endcase
        end

        EXEC3: begin
          if(rom_error) trap <= 5;

          else begin
            step <= EXEC4;

            case (opcode)
              // Parametric operators
              `op_select: begin
                // Store second operator before gets removed from stack
                stack_aux2 <= stack_tos;
              end
            endcase
          end
        end

        EXEC4: begin
          step <= FETCH;

          case (opcode)
            // Parametric operators
            `op_select: begin
              // Validate both operators are of the same type
              if(stack_aux2[65:64] != stack_tos[65:64])
                trap <= 6;

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
