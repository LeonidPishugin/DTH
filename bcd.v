`include "DTH_params.v"

module bcd (
    input                               clk,
    input                               rst,
    input                               flush_i,
    input      [`RES_WIDTH -1:0]        binary_i,
    input                               start_i,

    output                              bcd_ready_o,
    output reg [`DECIMAL_DIGITS*4 -1:0] BCD_o
  );

  // ---------------------------------------------------------------------------
  // Local Parameters
  // ---------------------------------------------------------------------------
  localparam FSM_STATE_NUM = 4;
  localparam [FSM_STATE_NUM-1:0] IDLE           = 1'b1 << 0;
  localparam [FSM_STATE_NUM-1:0] SHIFT          = 1'b1 << 1;
  localparam [FSM_STATE_NUM-1:0] DIGIT_CHECK    = 1'b1 << 2;
  localparam [FSM_STATE_NUM-1:0] DONE           = 1'b1 << 3;
  localparam [FSM_STATE_NUM-1:0] ERROR          = 4'b1111;

  parameter  DIGITS_IDX_WIDTH = $clog2(`DECIMAL_DIGITS);
  parameter  LOOP_COUNT_WIDTH = $clog2(`RES_WIDTH);

  // ---------------------------------------------------------------------------
  // Local Declarations
  // ---------------------------------------------------------------------------
  reg   [FSM_STATE_NUM       -1:0] bcd_fsm;
  reg   [`DECIMAL_DIGITS*4   -1:0] bcd_BCD;          // The vector that contains the output BCD
  wire  [`RES_WIDTH          -1:0] bcd_binary_next;
  reg   [`RES_WIDTH          -1:0] bcd_binary;       // The vector that contains the input binary value being shifted.
  wire                             bcd_sign_next;
  reg                              bcd_sign;
  reg   [DIGITS_IDX_WIDTH    -1:0] bcd_digit_idx;  // Keeps track of which Decimal Digit we are indexing

  // Keeps track of which loop iteration we are on.
  // Number of loops performed = `RES_WIDTH
  reg   [LOOP_COUNT_WIDTH    -1:0] bcd_loop_count;

  wire                       [3:0] bcd_digit;


  // ---------------------------------------------------------------------------
  // Main Code
  // ---------------------------------------------------------------------------

  assign bcd_digit       = bcd_BCD[bcd_digit_idx*4 +: 4];
  assign bcd_sign_next   = binary_i[`RES_WIDTH -1];
  // Converts two's complement to signed magnitued without sign
  assign bcd_binary_next = bcd_sign_next ? {~binary_i + 1'b1}
                                         : binary_i;

  // bcd_fsm_ff machine
  always @(posedge clk or negedge rst) begin
    if (~rst) begin
      bcd_BCD          <= {(`DECIMAL_DIGITS*4){1'b0}};
      bcd_binary       <= {`RES_WIDTH{1'b0}};
      bcd_sign         <= 1'b0;
      bcd_digit_idx    <= {DIGITS_IDX_WIDTH{1'b0}};
      bcd_loop_count   <= {LOOP_COUNT_WIDTH{1'b0}};
      bcd_fsm          <= IDLE;
      BCD_o            <= {(`DECIMAL_DIGITS*4){1'b0}};
    end else begin
      case (bcd_fsm)
      /////////////////////////
      // Idle until start_i comes
        IDLE: begin
          if (start_i)  begin
            bcd_binary      <= bcd_binary_next;
            bcd_sign        <= bcd_sign_next;
            bcd_BCD         <= {(`DECIMAL_DIGITS*4){1'b0}};
            bcd_digit_idx   <= {DIGITS_IDX_WIDTH{1'b0}};
            bcd_loop_count  <= {LOOP_COUNT_WIDTH{1'b0}};
            bcd_fsm         <= SHIFT;
          end else
            bcd_fsm         <= IDLE;
        end
      /////////////////////////
      // Shift the most significant bit of bcd_binary_ff into bcd_BCD_ff lowest bit.
        SHIFT: begin
          bcd_BCD          <= bcd_BCD << 1'b1;
          bcd_BCD[0]       <= bcd_binary[`RES_WIDTH-1];
          bcd_binary       <= bcd_binary << 1'b1;
          bcd_digit_idx    <= {DIGITS_IDX_WIDTH{1'b0}};

          if (flush_i)
            bcd_fsm        <= IDLE;
          else if (bcd_loop_count == `RES_WIDTH-1)  begin
            bcd_fsm        <= DONE;
          end else begin
            bcd_loop_count <= bcd_loop_count + 1'b1;
            bcd_fsm        <= DIGIT_CHECK;
          end
        end
      /////////////////////////
      // Sequentially check all BCD digits
      // If digit > 4, increment it by 3
        DIGIT_CHECK: begin
          if (bcd_digit > 4'd4)  begin
            bcd_BCD[bcd_digit_idx*4 +: 4] <= bcd_digit + 4'd3;
          end

          if (flush_i)
            bcd_fsm          <= IDLE;
          if (bcd_digit_idx == (`DECIMAL_DIGITS - 1)) begin
            bcd_digit_idx    <= {DIGITS_IDX_WIDTH{1'b0}};
            bcd_fsm          <= SHIFT;
          end else begin
            bcd_digit_idx    <= bcd_digit_idx + 1'b1;
            bcd_fsm          <= DIGIT_CHECK;
          end
        end
      /////////////////////////
      // Conversion complete. bcd_BCD_ff to out
        DONE: begin
          bcd_fsm            <= IDLE;
          BCD_o              <= bcd_BCD;
        end
      /////////////////////////
        default:
          bcd_fsm            <= ERROR;
    endcase
    end
  end

  assign bcd_ready_o = (bcd_fsm == IDLE);

endmodule : bcd
