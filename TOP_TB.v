`timescale 1ns / 1ps

module TOP_TB;
  reg         clk;
  reg         rst;
  wire        DTH;
  reg         button;
  reg         sw_h_t_select;
  wire        error;
  wire  [6:0] led_7seg_o;
  wire  [3:0] anode_o;
 
  reg           we;
  wire          DHT_in;
  reg           DHT_out;

  reg           DHT_data_bit;
  reg     [9:0] DTH_data_checksum;
  reg    [39:0] DTH_tb_data;

  reg     [63:0] time_a;
  reg     [63:0] time_b;
  wire    [63:0] time_diff;

  TOP dut (
    .clk            (clk),
    .rst            (rst),
    .DTH            (DTH),
    .button         (button),
    .sw_h_t_select  (sw_h_t_select),
    .error          (error),
    .led_7seg_o     (led_7seg_o),
    .anode_o        (anode_o)
     );

  assign DTH     = we ? DHT_out : 1'bz;
  assign DHT_in = DTH;

  assign time_diff = time_b - time_a;

  initial clk = 1'b0;
  always
    #5 clk = ~clk;


  integer i = 0;
  initial begin
    rst           = 1'b0;
    button        = 1'b0;
    we            = 1'b0;
    DHT_out       = 1'b0;
    sw_h_t_select = 1'b0;
    repeat(10) @(posedge clk);
    rst   = 1'b1;

    repeat(10) @(posedge clk);
    button  = 1'b1;
    @(posedge clk);
    button  = 1'b0;

    forever begin
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

   //    if (i >= 32)
   //      DTH_tb_data = DTH_data_checksum[39-i];
       else
            case (i)
            0: DHT_data_bit = 0;
            1: DHT_data_bit = 1;
            2: DHT_data_bit = 0;
            3: DHT_data_bit = 0;
            4: DHT_data_bit = 1;
            5: DHT_data_bit = 0;
            6: DHT_data_bit = 0;
            7: DHT_data_bit = 1;
            8: DHT_data_bit = 0;
            9: DHT_data_bit = 1; 
            10: DHT_data_bit = 0;
            11: DHT_data_bit = 1;
            12: DHT_data_bit = 0;
            13: DHT_data_bit = 0;
            14: DHT_data_bit = 1;
            15: DHT_data_bit = 0;
            16: DHT_data_bit = 0;
            17: DHT_data_bit = 0;
            18: DHT_data_bit = 0;
            19: DHT_data_bit = 1;
            20: DHT_data_bit = 1;
            21: DHT_data_bit = 0; 
            22: DHT_data_bit = 1;
            23: DHT_data_bit = 1;
            24: DHT_data_bit = 0;
            25: DHT_data_bit = 0;
            26: DHT_data_bit = 1;
            27: DHT_data_bit = 0;
            28: DHT_data_bit = 1;
            29: DHT_data_bit = 1;
            30: DHT_data_bit = 0;
            31: DHT_data_bit = 1;
            32: DHT_data_bit = 1;
            33: DHT_data_bit = 1;
            34: DHT_data_bit = 1;
            35: DHT_data_bit = 0;
            36: DHT_data_bit = 0;
            37: DHT_data_bit = 0;
            38: DHT_data_bit = 1;
            39: DHT_data_bit = 1;
            endcase

        DTH_tb_data[39-i] = DHT_data_bit;
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
      repeat(8000) @(posedge clk);
      $display("%tps END_OF_TRANSMISSION: DHT frees the line", $time);
      we      = 1'b0;
    end

  end

endmodule
