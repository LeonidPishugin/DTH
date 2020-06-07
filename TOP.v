`timescale 1ns / 1ps

module TOP

        /*(
            parameter       CLK_F      =       100000000,
            parameter       BAUD       =       115200
        )  */
        
        (
            input         clk,
            input         rst,
         //   input         RX_in,
            input  [39:0] dth_data,
            inout           DTH,
          //  output  wire  tx_out,
            output [3:0]  anode_out,
            output [6:0]  LED_out,
				output [5:0] cnt,
				output [20:0] timing
            
        );
    
     //   assign                         nrst = !rst;
    /*   wire         [7:0]             rx_out; 
        wire                           rx_rdy;
        wire         [31:0]            data;
        wire         [7:0]             to_tx;
        wire                           ctr;    
    
        assign                         to_tx             =        {data[22:15]}; 
            
        reg    ctr_dly_1;
        reg    ctr_dly_2;
        reg    ctr_dly_3;
    
        always @ (posedge clk) begin
            ctr_dly_1    <=    ctr;
            ctr_dly_2    <=    ctr_dly_1;
            ctr_dly_3    <=    ctr_dly_2; 
        end
    
        wire  ctr_n;
    
        assign ctr_n  =  ctr & ~ctr_dly_3;
    
    
    defparam uart_rx.CLK_FREQ     =   CLK_F;
    defparam uart_rx.BAUD_RATE    =   BAUD;
    
    UART_RX uart_rx 
        (
            .clk(clk),
            .RX_rst(nrst),
            .RX_in(RX_in),
            .RX_out(rx_out),
            .RX_rdy(rx_rdy)
        );
    
    defparam uart_tx.clk_f         =        CLK_F;
    defparam uart_tx.baund         =        BAUD;
    
    UART_TX uart_tx 
        (
            .clk(clk),
            .TX_rst(nrst),
            .TX_in(to_tx),
            .TX_ctr(ctr_n),
            .TX_out(tx_out)
        );  */
        
    DTH Datchik
        (.clk(clk),
        .rst(rst),
        .DTH(DTH)
		  );    
    
    Dyn_ind DINAMO
        (
            .clk(clk),
            .rst(rst),
            .dth_data(dth_data),
            .anode_out(di_anode_out),
            .LED_out(di_led_out)
        );   
        
   assign anode_out = di_anode_out;
   assign LED_out = di_led_out;     


endmodule
