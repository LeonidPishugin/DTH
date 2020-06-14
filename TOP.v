`include "DTH_params.v"

module TOP
  (
    input         clk,
    input         rst,
    inout         DTH,
    input         button,
    input         sw_h_t_select,
    output        error,
    output  [6:0] led_7seg_o,
    output  [3:0] anode_o,
    output        led_dot
  );

  // 5ms
  localparam [28:0] SELF_MEASURE_PERIOD = 29'd500000000;
  // Every 5s
  parameter CNTR_WIDTH = $clog2(SELF_MEASURE_PERIOD);

  // DTH
  reg          [CNTR_WIDTH-1:0] cntr;
  wire                          start;
  wire                   [39:0] DTH_data;
  wire                          DHT_data_ready;
  // BCD H
  wire                    [7:0] bcd_humidity_d;
  wire                    [7:0] bcd_humidity_i;
  wire                          bcd_ready_H_d;
  wire                          bcd_ready_H_i;
  wire [`DECIMAL_DIGITS*4 -1:0] BCD_H_d;
  wire [`DECIMAL_DIGITS*4 -1:0] BCD_H_i;
  reg  [`DECIMAL_DIGITS*4 -1:0] BCD_H_d_reg;
  reg  [`DECIMAL_DIGITS*4 -1:0] BCD_H_i_reg;
  // BCD T
  wire                    [7:0] bcd_temp_d;
  wire                    [7:0] bcd_temp_i;
  wire                          bcd_ready_T_d;
  wire                          bcd_ready_T_i;
  wire [`DECIMAL_DIGITS*4 -1:0] BCD_T_i;
  wire [`DECIMAL_DIGITS*4 -1:0] BCD_T_d;
  reg  [`DECIMAL_DIGITS*4 -1:0] BCD_T_i_reg;
  reg  [`DECIMAL_DIGITS*4 -1:0] BCD_T_d_reg;
  // Dynamic Indicator
  wire [`DECIMAL_DIGITS*8 -1:0] di_BCD;


  always @(posedge clk or negedge rst)
    if (~rst)
      cntr <= {CNTR_WIDTH{1'b0}};
    else begin
      if (cntr == SELF_MEASURE_PERIOD)
        cntr <= {CNTR_WIDTH{1'b0}};
      else
        cntr <= cntr + 1'b1;
    end

  assign start = button | (cntr == SELF_MEASURE_PERIOD);

  DTH i_DTH (
    .DTH            (DTH),
    .clk            (clk),
    .rst            (rst),
    .start          (start),
    .error          (error),
    .DTH_data       (DTH_data),
    .DHT_data_ready (DHT_data_ready)
  );

  assign bcd_humidity_i = DTH_data[39 : 32];
  assign bcd_humidity_d = DTH_data[31 : 24];
  assign bcd_temp_i     = DTH_data[23 : 16];
  assign bcd_temp_d     = DTH_data[15 : 8];

  // H - humidity
  bcd i_bcd_H_i (
    .clk             (clk),
    .rst             (rst),
    .binary_i        (bcd_humidity_i),
    .start_i         (DHT_data_ready),
    .bcd_ready_o     (bcd_ready_H_d),
    .BCD_o           (BCD_H_i)
  );

  bcd i_bcd_H_d (
    .clk             (clk),
    .rst             (rst),
    .binary_i        (bcd_humidity_d),
    .start_i         (DHT_data_ready),
    .bcd_ready_o     (bcd_ready_H_i),
    .BCD_o           (BCD_H_d)
  );

  // T - temp
  bcd i_bcd_T_i (
    .clk             (clk),
    .rst             (rst),
    .binary_i        (bcd_temp_i),
    .start_i         (DHT_data_ready),
    .bcd_ready_o     (bcd_ready_T_i),
    .BCD_o           (BCD_T_i)
  );

  bcd i_bcd_T_d (
    .clk             (clk),
    .rst             (rst),
    .binary_i        (bcd_temp_d),
    .start_i         (DHT_data_ready),
    .bcd_ready_o     (bcd_ready_T_d),
    .BCD_o           (BCD_T_d)
  );

  always @(posedge clk)
    if (bcd_ready_H_d)
     BCD_H_d_reg <= BCD_H_d;

  always @(posedge clk)
    if (bcd_ready_H_i)
      BCD_H_i_reg <= BCD_H_i;

  always @(posedge clk)
    if (bcd_ready_T_d)
      BCD_T_d_reg <= BCD_T_d;

  always @(posedge clk)
    if (bcd_ready_T_i)
      BCD_T_i_reg <= BCD_T_i;

  // Switch to select between humidity and temperature
  // If 1 humidity, if 0 - temp
  assign di_BCD = sw_h_t_select ? {BCD_H_i_reg, BCD_H_d_reg}  : {BCD_T_i_reg, BCD_T_d_reg};

  dynamic_indicator i_dynamic_indicator (
    .clk             (clk),
    .rst             (rst),
    .BCD_i           (di_BCD),
    .led_7seg_o      (led_7seg_o),
    .anode_o         (anode_o)
  );

  assign led_dot = (anode_o == 4'b1101);

endmodule
