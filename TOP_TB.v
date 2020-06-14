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

 
 reg [7:0] DTH_tb_H_i;
 reg [7:0] DTH_tb_H_d;
 reg [7:0] DTH_tb_T_i;
 reg [7:0] DTH_tb_T_d;
 reg [7:0] DTH_tb_fin;
 
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
      DTH_tb_H_i = 8'b01001001;
      DTH_tb_H_d = 8'b01010010;
      DTH_tb_T_i = 8'b00011011;
      DTH_tb_T_d = 8'b00101101;
      DTH_tb_fin = 8'b11100011;
      DTH_tb_data = {DTH_tb_H_i, DTH_tb_H_d, DTH_tb_T_i, DTH_tb_T_d, DTH_tb_fin};

      for (i = 0; i < 40; i = i + 1) begin
      
        if (i == 32)
          DTH_data_checksum = DTH_tb_data[39 -: 8] + DTH_tb_data[31 -: 8] + DTH_tb_data[23 -: 8] + DTH_tb_data[15 -: 8];

      DHT_data_bit = DTH_tb_data[39-i];      
      

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
