`timescale 1ns / 1ps

module TOP_TB;

	//Inputs
	reg	clk;
	reg	rst;
	reg [39:0] dth_data;
	
	// Outputs
	wire [3:0] anode_out;
	wire [6:0] LED_out;
	reg	[5:0] cnt;
	reg	[20:0] timing;
	
	//bidir
	wire input_DTH;
	wire DTH;
	reg output_DTH;
	reg output_value_valid;

	// Instantiate the Unit Under Test (UUT)
	TOP uut (
		.clk(clk),
		.rst(rst),
		.dth_data(dth_data),
		.DTH(DTH),
		.anode_out(anode_out),
		.LED_out(LED_out),
		.cnt(cnt),
		.timing(timing)
	);

assign input_DTH = DTH;
assign DTH = (output_value_valid == 1'b1)?output_DTH : 1'bZ;

	initial begin
		// Initialize Inputs
		output_value_valid =1;
		clk = 0;
		rst = 1;
		output_DTH = 1;
		dth_data = {40{1'b0}};
		#10;
		rst = 0;
		output_DTH = 0;
		#18000000;
		output_DTH = 1;
		#30000;
		output_DTH = 0;
		#80000;
		output_DTH = 1;
		#80000;
		
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#70000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#70000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#70000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#70000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#70000;
		
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#70000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#70000;
		
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#70000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#70000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#70000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#70000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#70000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#70000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#70000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#70000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#70000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#70000;
		
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#70000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#70000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		output_DTH = 0;
		#50000;
		output_DTH = 1;
		#27000;
		
		
		output_DTH = 0;
		#50000;
		
		output_DTH = 1;
		#1000000000;
		$finish;
	end	
        
		initial forever
		#1 clk = ~clk;

	endmodule

