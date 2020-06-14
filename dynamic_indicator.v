`include "DTH_params.v"

module dynamic_indicator (
  input                          clk,
  input                          rst,
  input [`DECIMAL_DIGITS*8 -1:0] BCD_i,

  output                   [6:0] led_7seg_o,
  output                   [3:0] anode_o
  );

  parameter         DIGIT_IDX_WIDTH = $clog2(`DECIMAL_DIGITS);
  localparam [15:0] INDICATOR_CLK_HALF_PERIOD = 16'd49_999;

  //internal
  reg                     [15:0] di_cntr_ms;
  reg                            di_indicator_clk;
  reg                      [3:0] di_cntr_indicator;
  reg                      [1:0] di_digit_idx_next;
  reg                      [1:0] di_digit_idx;
  reg                      [3:0] di_anode_next;
  reg                      [3:0] di_anode;
  wire                     [3:0] di_digit;
  reg                      [6:0] di_led_7seg;

  // counts 1 ms (100_000 clk ticks) and increments counter_indicator
  always @(posedge clk or negedge rst) begin
    if (~rst) begin
      di_cntr_ms       <= {16{1'b0}};
      di_indicator_clk    <= 1'b1;
    end else begin
      if (di_cntr_ms == INDICATOR_CLK_HALF_PERIOD) begin
        di_cntr_ms     <= {16{1'b0}};
        di_indicator_clk  <= ~di_indicator_clk;
      end else
        di_cntr_ms     <= di_cntr_ms + 1'b1;
    end
  end

  // In order for each of the four digits to appear bright 
  // and continuously illuminated, all four digits should be driven
  // once every 1 to 16ms, for a refresh frequency of 1KHz to 60Hz. 
  // For example, in a 60Hz refresh scheme, the entire display would be 
  // refreshed once every 16ms, and each digit would be illuminated 
  // for ¼ of the refresh cycle, or 4ms.
  always @(posedge di_indicator_clk or negedge rst) begin
    if (~rst)
      di_cntr_indicator <= {4{1'b0}};
    else
      di_cntr_indicator <= di_cntr_indicator + 1'b1;
  end

  always @*
    case (di_cntr_indicator)
      4'b0000:
        begin
          di_anode_next      = 4'b1110;
          di_digit_idx_next  = 0;
        end
    4'b0100:
        begin
          di_anode_next      = 4'b1101;
          di_digit_idx_next  = 1;
        end
    4'b1000:
        begin
          di_anode_next      = 4'b1011;
          di_digit_idx_next  = 2;
        end
    4'b1100:
        begin
          di_anode_next      = 4'b0111;
          di_digit_idx_next  = 3;
        end
    default: begin
      di_anode_next          = di_anode;
      di_digit_idx_next      = di_digit_idx;
    end
  endcase

  always @(posedge di_indicator_clk or negedge rst)
    if (~rst) begin
      di_anode       <= 4'b1111;
      di_digit_idx   <= {DIGIT_IDX_WIDTH{1'b0}};
    end else begin
      di_anode       <= di_anode_next;
      di_digit_idx   <= di_digit_idx_next;
    end


  assign di_digit = BCD_i[di_digit_idx*4 +: 4];

  // Convert digit value to 7segment code
  always @(*)
    case(di_digit)
      4'h0: di_led_7seg    = 7'b0000001; // "0"
      4'h1: di_led_7seg    = 7'b1001111; // "1"
      4'h2: di_led_7seg    = 7'b0010010; // "2"
      4'h3: di_led_7seg    = 7'b0000110; // "3"
      4'h4: di_led_7seg    = 7'b1001100; // "4"
      4'h5: di_led_7seg    = 7'b0100100; // "5"
      4'h6: di_led_7seg    = 7'b0100000; // "6"
      4'h7: di_led_7seg    = 7'b0001111; // "7"
      4'h8: di_led_7seg    = 7'b0000000; // "8"
      4'h9: di_led_7seg    = 7'b0000100; // "9"
      default: di_led_7seg = 7'b0110110; //
    endcase

  assign led_7seg_o = di_led_7seg;
  assign anode_o    = di_anode;

endmodule