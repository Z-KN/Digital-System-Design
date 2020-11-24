

`timescale 1ns/1ps


module cmd_parse(
  input             clk_rx,         // Clock input
  input             rst_clk_rx,     // Active HIGH reset - synchronous to clk_rx

  input      [7:0]  rx_data,        // Character to be parsed
  input             rx_data_rdy,    // Ready signal for rx_data
  // From Character FIFO
  input             char_fifo_full, // The char_fifo is full
  // To/From Response generator
  output reg        send_char_val,  // A character is ready to be sent
  output reg [7:0]  send_char,      // Character to be sent
  output reg        send_resp_val,  // A response is requested
  output reg [1:0]  send_resp_type, // Type of response - see localparams
  output reg [15:0] send_resp_data, // Data to be output
  input             send_resp_done, // The response generation is complete
  // to system
  output reg [31:0] bt_data32,
  output reg [2:0] led,
  output reg     light1,
  output reg     light2,
  output reg     light3,
  output reg [2:0] decount,
  input         finish,
  input   dim,
  input   tilt,
  input   sound_1,
  input   sound_2,
  input   sound_3,
  output reg beepkey,
  output   reg  pause,
  input   music_enable,
  input   alarm_pause,
  output reg [1:0] select,
  input  remember
);
  
//***************************************************************************
// Parameter definitions
//***************************************************************************
  parameter MAX_ARG_CH   = 8;    // Number of characters in largest set of args

  localparam [1:0]
     RESP_OK   = 2'b00,
     RESP_ERR  = 2'b01;
  // States for the main state machine
  localparam
     IDLE      = 3'b000,
     CMD_WAIT  = 3'b001,
     GET_ARG   = 3'b010,
     SEND_RESP = 3'b011;

   localparam
     CMD_W     = 7'h57,//seg
     CMD_T     = 7'h54,
     CMD_L     = 7'h4c,//turn light
     CMD_D     = 7'h44,//turn dim
     CMD_R     = 7'h52,//reverse
     CMD_N     = 7'h4e,//new decount
     CMD_P     = 7'h50,
     CMD_S     = 7'h53,
     CMD_Z     = 7'h5a,//reset to zero
     CMD_n_l   = 7'h6e,
     CMD_p_l   = 7'h70,
     CMD_s_l   = 7'h73,
     CMD_G     = 7'h47,
     CMD_C     = 7'h43,//control
     CMD_M     = 7'h4d,//music
     CMD_H     = 7'h48;
//***************************************************************************
// Functions declarations
//***************************************************************************
  `include "clogb2.txt"
//***************************************************************************
// Reg declarations
//***************************************************************************
  reg [2:0]         state;    // State variable
  reg               old_rx_data_rdy; // rx_data_rdy on previous clock
  reg [6:0]         cur_cmd;  // Current cmd - least 7 significant bits of char
  reg [4*MAX_ARG_CH-5:0]        arg_sav;  // All but last char of args 
  reg [clogb2(MAX_ARG_CH)-1:0]  arg_cnt;  // Count the #chars in an argument
  reg  bt1_in,bt2_in,bt3_in;
  reg [1:0] switch;
  reg[1:0] revtype;

//***************************************************************************
// Wire declarations
//***************************************************************************

  // Accept a new character when one is available, and we can push it into
  // the response FIFO. A new character is available on the FIRST clock that
  // rx_data_rdy is asserted - it remains asserted for 1/16th of a bit period.
  wire new_char = rx_data_rdy && !old_rx_data_rdy && !char_fifo_full; 
  
//***************************************************************************
// Tasks and Functions
//***************************************************************************

  // This function takes the lower 7 bits of a character and converts them
  // to a hex digit. It returns 5 bits - the upper bit is set if the character
  // is not a valid hex digit (i.e. is not 0-9,a-f, A-F), and the remaining
  // 4 bits are the digit
  function [4:0] to_val;
    input [6:0] char;
  begin
    if ((char >= 7'h30) && (char <= 7'h39)) // 0-9
    begin
      to_val[4]   = 1'b0;
      to_val[3:0] = char[3:0];
    end
    else if (((char >= 7'h41) && (char <= 7'h46)) || // A-F
             ((char >= 7'h61) && (char <= 7'h66)) )  // a-f
    begin
      to_val[4]   = 1'b0;
      to_val[3:0] = char[3:0] + 4'h9; // gives 10 - 15
    end
    else 
    begin
      to_val      = 5'b1_0000;
    end
  end
  endfunction

//***************************************************************************
// Code
//***************************************************************************
  // capture the rx_data_rdy for edge detection
  always @(posedge clk_rx)
  begin
    if (rst_clk_rx)
    begin
      old_rx_data_rdy <= 1'b0;
    end
    else
    begin
      old_rx_data_rdy <= rx_data_rdy;
    end
  end
  // Echo the incoming character to the output, if there is room in the FIFO
  always @(posedge clk_rx)
  begin
    if (rst_clk_rx)
    begin
      send_char_val <= 1'b0;
      send_char     <= 8'h00;
    end
    else if (new_char)
    begin
      send_char_val <= 1'b1;
      send_char     <= rx_data;
    end // if !rst and new_char
    else
    begin
      send_char_val <= 1'b0;
    end
  end // always

  // For each character that is potentially part of an argument, we need to 
  // check that it is in the HEX range, and then figure out what the value is.
  // This is done using the function to_val
  wire [4:0]  char_to_digit = to_val(rx_data);
  wire        char_is_digit = !char_to_digit[4];

  // Assuming it is a value, the new digit is the least significant digit of
  // those that have already come in - thus we need to concatenate the new 4
  // bits to the right of the existing data
  wire [4*MAX_ARG_CH-1:0] arg_val       = {arg_sav,char_to_digit[3:0]};

  always @(posedge clk_rx)
  begin
    if (rst_clk_rx)
    begin
      state             <= IDLE;
      cur_cmd           <= 7'h00;
      arg_sav           <= 28'b0;
      arg_cnt           <= 3'b0;
      send_resp_val     <= 1'b0;
      send_resp_type    <= RESP_ERR;
      send_resp_data    <= 16'h0000;
	    bt_data32         <= 32'h00000000;
      bt1_in            <= 0;
      bt2_in            <= 0;
      bt3_in            <= 0;
      switch<=0;
      pause<=0;
      revtype<=0;
    end
    else
    begin
      // Defaults - overridden in the appropriate state
      case (state)

        IDLE: begin // Wait for the '*'
          if (new_char && (rx_data[6:0] == 7'h2A))
          begin
            state <= CMD_WAIT;
          end // if found *
        end // state IDLE

        CMD_WAIT: begin // Validate the incoming command
          if (new_char)
          begin
            cur_cmd <= rx_data[7:0];
            case (rx_data[6:0])
  
              CMD_W: begin 
                // Get 8 characters of arguments
                state   <= GET_ARG;
                arg_cnt <= 3'd7;
              end  // W
              
              CMD_C:begin
                // Get 3 characters of switch command
                state   <= GET_ARG;
                arg_cnt <= 3'd2;
              end  //  C
              CMD_N:begin
                // Get 4 characters of timing
                state   <= GET_ARG;
                arg_cnt <= 3'd3;
              end // N
              CMD_R:begin
                // Get characters of reverse
                state   <= GET_ARG;
                arg_cnt <= 3'd0;
              end  // R
              CMD_Z:begin
                // Get characters of reverse
                state   <= GET_ARG;
                arg_cnt <= 3'd0;
              end  // Z
              CMD_M:begin
                // Get characters of reverse
                state   <= GET_ARG;
                arg_cnt <= 3'd0;
              end  // M
              CMD_D:begin
                // Get characters of reverse
                state   <= GET_ARG;
                arg_cnt <= 3'd3;
              end  // D
              CMD_L:begin
                // Get characters of reverse
                state   <= GET_ARG;
                arg_cnt <= 3'd3;
              end  // L
              default: begin
                send_resp_val  <= 1'b1;
                send_resp_type <= RESP_ERR;
                state          <= SEND_RESP;
              end // default
            endcase // current character case
          end // if new character has arrived
        end // state CMD_WAIT
        
        GET_ARG: begin
          // Get the correct number of characters of argument. Check that
          // all characters are legel HEX values.
          // Once the last character is successfully received, take action
          // based on what the current command is
          if (new_char)
          begin
            if (!char_is_digit)
            begin
              // Send an error response
              send_resp_val  <= 1'b1;
              send_resp_type <= RESP_ERR;
              state          <= SEND_RESP;
            end
            else // character IS a digit
            begin
              if (arg_cnt != 3'b000) // This is NOT the last char of arg
              begin
                // append the current digit to the saved ones
                arg_sav <= arg_val;  
                // Wait for the next character
                arg_cnt <= arg_cnt - 1'b1;
              end // Not last char of arg
              else // This IS the last character of the argument - process
              begin
                case (cur_cmd) 
                  CMD_W: begin
                      bt_data32 <= arg_val[31:0]; 
					             // Send OK
                      decount<=0;
                      send_resp_val     <= 1'b1;
                      send_resp_type    <= RESP_OK;
                      state             <= SEND_RESP;
                  end // CMD_W
                  CMD_C: begin
                      bt_data32 <= {20'd0,arg_val[11:0]};
                      decount<=0;
                      if (arg_val[11:8]==4'b1)bt3_in<=1;
                      else if (arg_val[11:8]==4'b0) bt3_in<=0;
                      if (arg_val[7:4]==4'b1)bt2_in<=1;
                      else if (arg_val[7:4]==4'b0) bt2_in<=0;
                      if (arg_val[3:0]==4'b1)bt1_in<=1;
                      else if (arg_val[3:0]==4'b0) bt1_in<=0;
                      // Send OK
                      send_resp_val  <= 1'b1;
                      send_resp_type <= RESP_OK;
                      state          <= SEND_RESP;
                  end //CMD_C
                  CMD_N: begin
                      bt_data32 <= {16'd0,arg_val[15:0]};
                      decount<=1;
                      revtype<=0;
                      // Send OK
                      send_resp_val     <= 1'b1;
                      send_resp_type    <= RESP_OK;
                      state             <= SEND_RESP;
                  end  // CMD_N
                  CMD_M: begin
                      bt_data32 <= {16'd0,arg_val[15:0]};
                      decount<=4;
                      // Send OK
                      send_resp_val     <= 1'b1;
                      send_resp_type    <= RESP_OK;
                      state             <= SEND_RESP;
                  end  // CMD_M
                  CMD_D: begin
                      bt_data32 <= {16'd0,arg_val[15:0]};
                      decount<=1;
                      revtype<=1;
                      // Send OK
                      send_resp_val     <= 1'b1;
                      send_resp_type    <= RESP_OK;
                      state             <= SEND_RESP;
                  end  // CMD_D
                  CMD_L: begin
                      bt_data32 <= {16'd0,arg_val[15:0]};
                      decount<=1;
                      revtype<=2;
                      // Send OK
                      send_resp_val     <= 1'b1;
                      send_resp_type    <= RESP_OK;
                      state             <= SEND_RESP;
                  end  // CMD_L
                  CMD_R:begin
                      bt_data32 <= {16'd0,arg_val[15:0]};
                      decount<=2;
                      if(switch==0)begin
                      switch<=1;
                      pause<=1;
                      end
                      else begin
                      switch<=0;
                      pause<=0;  
                      end
                      // Send OK
                      send_resp_val     <= 1'b1;
                      send_resp_type    <= RESP_OK;
                      state             <= SEND_RESP;
                    end  // CMD_R
                  CMD_Z:begin
                      bt_data32 <= {32'd0};
                      decount<=3;
                      bt3_in<=0;
                      bt2_in<=0;
                      bt1_in<=0;
                      // Send OK
                      send_resp_val     <= 1'b1;
                      send_resp_type    <= RESP_OK;
                      state             <= SEND_RESP;

                  end  // CMD_Z
                endcase
              end // received last char of arg
            end // if the char is a valid HEX digit
          end // if new_char
        end // state GET_ARG

        SEND_RESP: begin
          // The response request has already been sent - all we need to
          // do is keep the request asserted until the response is complete.
          // Once it is complete, we return to IDLE
          if (send_resp_done)
          begin
            
            send_resp_val <= 1'b0;
            state         <= IDLE;
          end
        end // state SEND_RESP

        default: begin
          state <= IDLE;
        end // state default

      endcase
    end // if !rst
  end // always


reg c=0;
always @(posedge clk_rx) begin
    led[2:0] = decount;
    if (rst_clk_rx||tilt||(decount==3)) begin
    beepkey<=0;
    select<=0;
    end  //end stop
    else if (decount==4&&(beepkey||select)) begin
    beepkey<=0;
    select<=0;
    end
    else begin//start
    //control beep and music
    if (alarm_pause&&music_enable)begin
      beepkey<=0;
      select<=0;
    end
    if (finish&&alarm_pause==0&&music_enable==0) begin
      beepkey<=1;
      select<=0;
    end
    if (alarm_pause==0&&music_enable) begin
      beepkey<=1;
      select<=1;
    end
    end

    //control light
    if (rst_clk_rx||tilt||(decount==3)) begin
    light3<=0;
    light2<=0;
    light1<=0;
    end  
    else begin 
    c<=0;
    if (finish&&remember==1) begin
    c<=~c;
    if (c==0) begin
    if (revtype==0) begin
    light1<=~light1;
    light2<=~light2;
    light3<=~light3;
    end
    else if(revtype==1) begin
    light3<=0;
    light2<=0;
    light1<=0;  
    end
    else if(revtype==2) begin
    light3<=dim;
    light2<=1;
    light1<=1;  
    end
    end 
    end
    else if(decount==1||decount==4||decount==2)begin
    light1<=light1;
    light2<=light2;
    light3<=light3;  
    end
    else if(dim)begin
      light1<=(sound_1||bt1_in); 
      light2<=(sound_2||bt2_in);
      light3<=(sound_3||bt3_in); 
      end  //end dim
    else begin
      if((sound_1||bt1_in)&&(sound_2||bt2_in)&&(sound_3||bt3_in))
      begin
      light1<=(sound_1||bt1_in); 
      light2<=(sound_2||bt2_in); 
      end
      else begin
      light1<=(sound_1||bt1_in); 
      light2<=(sound_2||bt2_in);
      light3<=(sound_3||bt3_in); 
      end
    end
    
    end  //end start
end //end always


endmodule