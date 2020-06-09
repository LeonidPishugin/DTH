`timescale 1ns / 1ps

module DTH_TB;

  wire          DTH;
  reg           clk;
  reg           rst;
  reg           start;
  wire          error;
  wire   [39:0] DTH_data;
  wire          DHT_data_ready;

  reg           we;
  wire          DHT_in;
  reg           DHT_out;

  reg           DHT_data_bit;
  reg     [7:0] DTH_data_checksum;
  reg    [39:0] DTH_tb_data;

  reg     [63:0] time_a;
  reg     [63:0] time_b;
  wire    [63:0] time_diff;

	// Instantiate the Unit Under Test (UUT)
	DTH dut (
    .DTH            (DTH),
    .clk            (clk),
    .rst_n          (rst),
    .start          (start),
    .error          (error),
    .DTH_data       (DTH_data),
    .DHT_data_ready (DHT_data_ready)
  );

  assign DTH     = we ? DHT_out : 1'bz;
  assign DHT_in = DTH;

  assign time_diff = time_b - time_a;

  initial clk = 1'b0;
  always
    #5 clk = ~clk;

  integer i = 0;
  initial begin
    rst     = 1'b0;
    start   = 1'b0;
    we      = 1'b0;
    DHT_out = 1'b0;
    repeat(10) @(posedge clk);
    rst   = 1'b1;

    repeat(10) @(posedge clk);
    start  = 1'b1;
    @(posedge clk);
    start  = 1'b0;
    wait(~DHT_in);
    $display("%tps START: MCU pulled down", $time);
    time_a = $time;
    wait(DHT_in);
    time_b = $time;
    if ((time_diff > 64'd18_000_000_000))
      $display("%tps START: MCU pulled up in correct time", $time);
    else
      $error("START: MCU pulled up in incorrect time");

    repeat(2500) @(posedge clk);
    $display("%tps START_RESP: DHT takes control of the line", $time);
    we      = 1'b1;
    DHT_out = 1'b1;
    repeat(1500) @(posedge clk);
    $display("%tps START_RESP: DHT pulls line down", $time);
    DHT_out = 1'b0;
    repeat(8000) @(posedge clk);
    $display("%tps START_RESP: DHT pulls line up", $time);
    DHT_out = 1'b1;
    repeat(8000) @(posedge clk);

    $display("%tps TRANSMISSION: DHT starts transmission", $time);
    DTH_tb_data = {40{1'b0}};
    for (i = 0; i < 40; i = i + 1) begin
      if (i == 32)
        DTH_data_checksum = DTH_tb_data[39 -: 8] + DTH_tb_data[31 -: 8] + DTH_tb_data[23 -: 8] + DTH_tb_data[15 -: 8];

      if (i >= 32)
        DTH_tb_data = DTH_data_checksum[39-i];
      else
        DHT_data_bit = $random;

      DTH_tb_data[i] = DHT_data_bit;
      $display("%tps TRANSMISSION: data bit %d = %b", $time, i, DHT_data_bit);
      $display("%tps TRANSMISSION: DHT pulls line down before bit transmission", $time);
      DHT_out = 1'b0;
      repeat(5000) @(posedge clk);
      $display("%tps TRANSMISSION: DHT pulls line up for bit transmission", $time);
      DHT_out = 1'b1;
      if (DHT_data_bit) begin
        repeat(7000) @(posedge clk);
        $display("%tps TRANSMISSION: DHT keeps line up for 1 bit transmission", $time);
      end else begin
        repeat(2650) @(posedge clk);
        $display("%tps TRANSMISSION: DHT keeps line up for 0 bit transmission", $time);
      end
    end

    $display("%tps END_OF_TRANSMISSION: DHT pulls line down for end of transmission", $time);
    DHT_out = 1'b0;
    repeat(5000) @(posedge clk);
    $display("%tps END_OF_TRANSMISSION: DHT pulls line up for end of transmission", $time);
    DHT_out = 1'b1;
    wait(DHT_data_ready);
    @(negedge clk);
    if (DTH_tb_data != DTH_data)
      $error("DATA doesn't match");
    else
      $display("%tps DATA MATCHES", $time);
    repeat(8000) @(posedge clk);
    $display("%tps END_OF_TRANSMISSION: DHT frees the line", $time);
    we      = 1'b0;

    $finish;
  end

endmodule

