`timescale 1ns / 1ps

module Dyn_ind
	(
    input rst, clk,
    input [39:0] dth_data,
    output [3:0] anode_out,
    output [6:0] LED_out
    );
    
localparam [15:0] di_clk_half = 16'd49999;  

    
    wire    [3:0]   di_num;
    reg     [6:0]   di_led7;
    reg     [3:0]   di_anode;
    reg     [3:0]   di_anode_next;
    reg     [15:0]  di_cntrl_time;
    reg     [3:0]   di_cntrl_ind;
    reg             di_clk;
	 
	 
                
   always @(posedge clk or negedge rst) begin
    if (~rst) begin
        di_cntrl_time <= {16{1'b0}};
        di_clk <=1'b1;
        end
    else begin
          if (di_cntrl_time == di_clk_half) begin
              di_cntrl_time <= {16{1'b0}};
              di_clk <= ~di_clk;
              end
          else di_cntrl_time <= di_cntrl_time + 1'b1;
          end
    end     
    
    //bridhtness
    always @(posedge di_clk or negedge rst) begin
        if (~rst) di_cntrl_ind <= {4{1'b0}};
        else di_cntrl_ind <= di_cntrl_ind + 1'b1;
        end
           
    always @*    
    case (di_cntrl_ind)
    4'd0: di_anode_next = 4'b0111;
    4'd4: di_anode_next = 4'b1011; 
    4'd8: di_anode_next = 4'b1101; 
    4'd12: di_anode_next = 4'b1110;   
    default: di_anode_next = di_anode;
    endcase
    
    assign di_num = di_cntrl_ind[3] ? (di_cntrl_ind[1] ? dth_data[11:8] : dth_data[15:12]) : (di_cntrl_ind[2] ? dth_data[27:24] : dth_data[31:28]);
    
    always @(posedge di_clk or negedge rst) 
        if (~rst) di_anode <= 4'b1111;
        else di_anode <= di_anode_next;

    always @(*)
    case (di_num)
    4'b0000: di_led7 = 7'b0000001; //0
    4'b0001: di_led7 = 7'b1001111; //1
    4'b0010: di_led7 = 7'b0010010; //2
    4'b0011: di_led7 = 7'b0000110; //3
    4'b0100: di_led7 = 7'b1001100; //4
    4'b0101: di_led7 = 7'b0100100; //5
    4'b0110: di_led7 = 7'b0100000; //6
    4'b0111: di_led7 = 7'b0001111; //7
    4'b1000: di_led7 = 7'b0000000; //8
    4'b1001: di_led7 = 7'b0000100; //9
    default: di_led7 = 7'b0110110;
    endcase
   
assign anode_out = di_anode;
assign LED_out = di_led7;


endmodule
