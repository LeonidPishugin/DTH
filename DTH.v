`timescale 1ns / 1ps

module DTH(
      inout    DTH,
		input 	clk,
		input	   rst

    );

    localparam fsm_state_num =6;
    localparam [fsm_state_num-1 : 0] startup = 1'b1 <<0;
    localparam [fsm_state_num-1 : 0] transfer = 1'b1 <<1;
	 localparam [fsm_state_num-1 : 0] prepare = 1'b1 <<2;
    localparam [fsm_state_num-1 : 0] receive = 1'b1 <<3;
	 localparam [fsm_state_num-1 : 0] final = 1'b1 <<4;
    localparam [fsm_state_num-1 : 0] error = 1'b1 <<5;  
    
       reg         [fsm_state_num-1 : 0]       state;
       reg         [39:0]      dth_data;
       reg                     buss_volt;
       reg         [20:0]      timing;
       reg         [28:0]      global_timing;
		 reg							 flag;
       reg         [5:0]       cnt;
       reg         [9:0]       sum;
  //     reg                     btn;  
       
    assign 		DTH = buss_volt;   
    
    always @ (posedge clk or negedge rst) begin
    
        if (~rst) begin
            dth_data <= {40{1'b0}};
            buss_volt =1;
            timing <=0;
            global_timing <=0;
            state <= startup;
				flag<=0;
            cnt <=0;
      //      btn <=0;
        end
        
    else begin    
    global_timing <= global_timing + 1'b1;
            
			case (state)
            
            startup: begin
            //   case (btn)
             //  1'b1: state <= transfer;
					dth_data <= {40{1'b0}};
					buss_volt =1;
					timing <=0;
					global_timing <=0;
					flag<=0;
					cnt <=0;
               state <= transfer;
					//  endcase
               end   
					
					
            transfer: begin
								case (flag)
								1'b0: begin
								  buss_volt =0;
                          timing <= timing +1'b1;
								  
                          if (timing == 21'd1800000) begin 
                              buss_volt = 1'bz;
                              timing <=0;
										flag<=1;
                              end
								
                          end
                          
                        1'b1: begin
                          
								  timing <= timing+1'b1;
                         if (buss_volt == 0)  begin //от датчика приходит низкий сигнал
                              timing <= 0;
                              state <= prepare;
                              end
                         else if (timing > 21'd4100) state <= error;
                          
								 end
                         endcase
								  
                       end



				  prepare: begin
								case (flag)
								1'b1: begin
									timing <= timing + 1'b1;
									if (buss_volt == 1) begin
											timing <=0;
											flag <=0;
											end
										end	
								1'b0: begin
									timing <= timing + 1'b1;
									if(buss_volt == 0) begin
											timing <=0;
											state <= receive;
											end
									else if ((buss_volt == 1) & (timing > 21'd8100)) state <= error;		
										end
								endcase
								end



								
				  receive: begin
                        
                           if (buss_volt == 1) begin
                              timing <= timing + 1'b1; end
										
										if (buss_volt == 0) begin
											
												if (timing == 21'd7000) begin
													dth_data[39-cnt] <=1;
													cnt <= cnt + 1'b1;
													end
													
												else if ((timing > 21'd2600) & (timing < 21'd2800)) begin
													dth_data[39-cnt] <= 0;
													cnt <= cnt + 1'b1;
													end
												else if (timing > 21'd7000) 
													state <= error;
													
										timing <= 0;
											
										end
									
									
                                                      
									if (cnt == 6'd40) state <= final;
									
								end
								


					final: begin
					
							sum <= dth_data[39:32] + dth_data[31:24] + dth_data[23:16] + dth_data[15:8];
										
									if (sum[7:0] != dth_data[7:0]) 
											state <= error;
									else if (buss_volt == 1) 
											state <=startup;
										
																	
	
                     end   


					error: state <= startup;
					
					
            endcase					
                   
            //   if (global_timing >> 100000000) btn <= 0;
               //else 
               if (global_timing >> 29'd500000000) state <= transfer;   
					
    end 
	 

	 
    end 
    
endmodule








       
                

                       
							  

				  
				  
				  




            
