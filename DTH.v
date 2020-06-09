module DTH(
  inout         DTH,
  input         clk,
  input         rst,
  input         start,
  output        error,
  output [39:0] DTH_data,
  output        DHT_data_ready
);

  localparam FSM_STATE_NUM = 9;
  localparam [FSM_STATE_NUM-1 : 0] FSM_IDLE                = 1'b1 << 0;
  localparam [FSM_STATE_NUM-1 : 0] FSM_START_REQ_DOWN      = 1'b1 << 1;
  localparam [FSM_STATE_NUM-1 : 0] FSM_START_REQ_UP        = 1'b1 << 2;
  localparam [FSM_STATE_NUM-1 : 0] FSM_START_RESP_DOWN     = 1'b1 << 3;
  localparam [FSM_STATE_NUM-1 : 0] FSM_START_RESP_UP       = 1'b1 << 4;
  localparam [FSM_STATE_NUM-1 : 0] FSM_DATA_TRANSMIT_DOWN  = 1'b1 << 5;
  localparam [FSM_STATE_NUM-1 : 0] FSM_DATA_TRANSMIT_UP    = 1'b1 << 6;
  localparam [FSM_STATE_NUM-1 : 0] FSM_DONE                = 1'b1 << 7;
  localparam [FSM_STATE_NUM-1 : 0] FSM_ERROR               = 1'b1 << 8; // REVIEW: unused!!!

  localparam [20:0] TIME_CNTR_RESET = {21{1'b0}};

  reg                       dth_we;
  wire                      dht_data_i;
  reg                       dht_data_o;

  reg                [20:0] time_cntr_next;
  reg                [20:0] time_cntr;

  reg                       data_bit_next;
  reg                       data_bit_end;
  reg                       dth_data_ready;

  reg [FSM_STATE_NUM-1 : 0] state_next;
  reg [FSM_STATE_NUM-1 : 0] state;
  wire               [39:0] dth_data_next;
  reg                [39:0] dth_data;
  wire                [5:0] bit_cntr_next;
  reg                 [5:0] bit_cntr;
  
  wire                [7:0] error_next;
  reg                 [7:0] error_reg;
  wire                [7:0] sum;



  // If DTH Write Enable is 1, we drive data, otherwise pull up and read
  assign DTH = dth_we ? dht_data_o : 1'bz;
  assign dht_data_i = DTH;

  always @(posedge clk or negedge rst)
    // If we use ~rst, then it's rst_n meaning when it's negative (0) we reset
    if (~rst) begin
      state <= FSM_IDLE;
    end else begin
      state <= state_next;
    end

  always @(posedge clk or negedge rst)
    if (~rst)
      time_cntr <= TIME_CNTR_RESET;
    else
      time_cntr <= time_cntr_next;


  always @* begin
    // To prevent latches we define default values for all signals
    time_cntr_next = TIME_CNTR_RESET;
    dth_we         = 1'b1;
    dht_data_o     = 1'b1;
    data_bit_end   = 1'b0;
    data_bit_next  = 1'b0;
    dth_data_ready = 1'b0;

    case (state)
      // In IDLE state, line is up and nothing happens
      FSM_IDLE : begin
        dth_we     = 1'b1;
        dht_data_o = 1'b1;
        state_next = start ? FSM_START_REQ_DOWN : FSM_IDLE;
      end
      // Send out "start" signal and pull down voltage for at least 18ms to let
      // DHT11 detect the signal
      FSM_START_REQ_DOWN : begin
        dth_we         = 1'b1;
        dht_data_o     = 1'b0;
        time_cntr_next = time_cntr + 1'b1;
        if (time_cntr == 21'd1800000) begin
          time_cntr_next = TIME_CNTR_RESET;
          state_next     = FSM_START_REQ_UP;
        end else begin
          time_cntr_next = time_cntr + 1'b1;
          state_next     = FSM_START_REQ_DOWN;
        end
      end
      // Pull up signal and wait 20-40us for DHT11 before freeing the line
      FSM_START_REQ_UP : begin
        dth_we         = 1'b1;
        dht_data_o     = 1'b1;
        // 30us is between 20 and 40
        if (time_cntr > 21'd3000) begin
          time_cntr_next = TIME_CNTR_RESET;
          state_next     = FSM_START_RESP_DOWN;
        end else begin
          time_cntr_next = time_cntr + 1'b1;
          state_next     = FSM_START_REQ_UP;
        end
      end
      // MCU frees the line and waits for DHT to pull it down for 80us
      // (approximate)
      FSM_START_RESP_DOWN : begin
        dth_we         = 1'b0;
        dht_data_o     = 1'b1;
        // If line is down, we increment the counter
        if (~dht_data_i)
          time_cntr_next = time_cntr + 1'b1;
        else
          time_cntr_next = TIME_CNTR_RESET;
        // If line was pulled for more than ~80us, we go to next state
        // otherwise - keep it
        if (dht_data_i & (time_cntr > 21'd7500))
          state_next = FSM_START_RESP_UP;
        else
          state_next = FSM_START_RESP_DOWN;
      end
      FSM_START_RESP_UP : begin
        dth_we         = 1'b0;
        dht_data_o     = 1'b1;
        // If line is up, we increment the counter
        if (dht_data_i)
          time_cntr_next = time_cntr + 1'b1;
        else
          time_cntr_next = TIME_CNTR_RESET;
        // If line was pulled for more than ~80us, we go to next state
        // otherwise - keep it
        if (~dht_data_i & (time_cntr > 21'd7500))
          state_next = FSM_DATA_TRANSMIT_DOWN;
        else
          state_next = FSM_START_RESP_UP;
      end
      FSM_DATA_TRANSMIT_DOWN : begin
        dth_we         = 1'b0;
        dht_data_o     = 1'b1;
        if (dht_data_i & (time_cntr > 21'd5000)) begin
          time_cntr_next = TIME_CNTR_RESET;
          state_next     = (bit_cntr == 6'd40) ? FSM_DONE : FSM_DATA_TRANSMIT_UP;
        end else begin
          time_cntr_next = time_cntr + 1'b1;
          state_next     = FSM_DATA_TRANSMIT_DOWN;
        end
      end
      FSM_DATA_TRANSMIT_UP : begin
        dth_we         = 1'b0;
        dht_data_o     = 1'b1;
        // 0 bit
        if (~dht_data_i & (time_cntr > 21'd2500) & (time_cntr < 21'd2900)) begin
          time_cntr_next = TIME_CNTR_RESET;
          state_next     = FSM_DATA_TRANSMIT_DOWN;
          data_bit_next  = 1'b0;
          data_bit_end   = 1'b1;
        // 1 bit
        end else if (~dht_data_i & (time_cntr > 21'd6900)) begin
          time_cntr_next = TIME_CNTR_RESET;
          state_next     = FSM_DATA_TRANSMIT_DOWN;
          data_bit_next  = 1'b1;
          data_bit_end   = 1'b1;
        // Bit transaction is still in progress
        end else begin
          time_cntr_next = time_cntr + 1'b1;
          state_next     = FSM_DATA_TRANSMIT_UP;
        end
      end
      FSM_DONE : begin
        dth_data_ready = 1'b1;
        state_next     = FSM_IDLE;
        
      end
    endcase
  end


  assign dth_data_next = dth_data | ({{39{1'b0}}, data_bit_next} << bit_cntr);
  always @(posedge clk or negedge rst)
    if (~rst) begin
      dth_data <= {40{1'b0}};
    end else if (data_bit_end) begin
      dth_data <= dth_data_next;
    end

  assign bit_cntr_next = (state == FSM_IDLE) ? {6{1'b0}} : (bit_cntr + 1'b1);
  always @(posedge clk or negedge rst)
    if (~rst)
      bit_cntr <= {6{1'b0}};
    else if (data_bit_end | (state == FSM_IDLE))
      bit_cntr <= bit_cntr_next;

  assign sum = dth_data[39 : 32] + dth_data[31:24] + dth_data[23:16] + dth_data[15:8];
  always @(posedge clk or negedge rst) 
      if (~rst)
          error_reg <= 8'h0;
      else if (state == FSM_DONE)
          error_reg <= error_next; 

  assign DHT_data_ready = dth_data_ready;
  assign DTH_data       = {40{(state == FSM_DONE)}} & dth_data;
  assign error          = error_reg;
  assign error_next     = (sum != dth_data[7:0]);        

endmodule