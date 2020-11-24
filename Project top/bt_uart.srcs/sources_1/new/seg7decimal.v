`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/07/2015 06:29:31 PM
// Design Name: 
// Module Name: seg7decimal
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module seg7decimal(
input [15:0] x,
input clk,
input clr,
output reg [6:0] a_to_g,
output reg [3:0] an,
output wire dp, 
input [2:0] decount,
output reg finish,
output [7:0] led,
input   pause,
output reg remember
);


wire [1:0] s;     
reg [3:0] digit;
wire [3:0] aen;
reg [19:0] clkdiv;
reg [15:0] val;
reg [2:0]  state;

parameter MAXDELAY=28'd2000_0000,MAXBITS = 28;
reg [MAXBITS-1:0] count;
reg clk_s=0;

assign dp = 0;
assign s = clkdiv[19:18];
assign aen = 4'b1111; // all turned off initially

// quad 4to1 MUX.


always @(posedge clk)// or posedge clr)
begin
case(s)
0:digit = val[15:12]; // s is 00 -->0 ;  digit gets assigned 4 bit value assigned to x[3:0]
1:digit = val[11:8]; // s is 01 -->1 ;  digit gets assigned 4 bit value assigned to x[7:4]
2:digit = val[7:4]; // s is 10 -->2 ;  digit gets assigned 4 bit value assigned to x[11:8
3:digit = val[3:0]; // s is 11 -->3 ;  digit gets assigned 4 bit value assigned to x[15:12]

default:digit = val[3:0];
endcase 

end


//decoder or truth-table for 7a_to_g display values
always @(*)

case(digit)


//////////<---MSB-LSB<---
//////////////gfedcba////////////////////////////////////////////              a
0:a_to_g = 7'b0111111;////0000                                                   __                    
1:a_to_g = 7'b0000110;////0001                                                f/      /b
2:a_to_g = 7'b1011011;////0010                                                  g
//                                                                           __    
3:a_to_g = 7'b1001111;////0011                                              e /   /c
4:a_to_g = 7'b1100110;////0100                                                 __
5:a_to_g = 7'b1101101;////0101                                               d  
6:a_to_g = 7'b1111101;////0110
7:a_to_g = 7'b0000111;////0111
8:a_to_g = 7'b1111111;////1000
9:a_to_g = 7'b1101111;////1001
'hA:a_to_g = 7'b1110111; // dash-(g)
'hB:a_to_g = 7'b1111100; // all turned off
'hC:a_to_g = 7'b1110011;
'hD:a_to_g = 7'b1011110; // dash-(g)
'hE:a_to_g = 7'b1111001; // all turned off
'hF:a_to_g = 7'b1110001;
default: a_to_g = 7'b1111111; // U

endcase

initial 
begin
    val[15:0]<=16'b0;
    remember<=0;
    finish<=0; 
    state<=IDLE;
end//reset

always @(*)begin
an=4'b0000;
if(aen[s] == 1)
an[s] = 1;
end

localparam IDLE = 0;
localparam READ = 1;
localparam DECOUNT = 2;
localparam REVERSE = 3;
localparam RESET = 4;

//clkdiv

always @(posedge clk or posedge clr) begin
if ( clr == 1)
clkdiv <= 0;
else
clkdiv <= clkdiv+1;
end

always @(posedge clk)
if(count==MAXDELAY)
begin clk_s<=~clk_s;
count<=0;
end
else count<=count+1;

always @(posedge clk_s ) begin
    
    //begin
    case(state)
    IDLE:begin
    if(pause==1)
    state<=IDLE;
    else if (decount==3&&(remember||finish)) begin//
    state<=RESET;    
    end
    else if(decount==4&&(remember||finish))begin
    state<=RESET;    
    end
    else if(finish)
    remember<=0;
    else if(remember==0&&decount==1)//&&finish==0
    begin
    state<=READ;
    remember<=1;
    end
    else if(decount==0)
    state<=READ;
    else if(decount==2)//&&finish==0
    state<=DECOUNT;
    else if(decount==1)//&&finish==0
    state<=DECOUNT;
    else
    state<=IDLE;
    end//idle
    READ:begin
        val[15:0]<=x[15:0];
        state<=IDLE;
    end//read
    DECOUNT:begin
    if (val[3:0]==4'd0)
        begin
        if(val[7:4]==4'd0)
            begin
            if(val[11:8]==4'd0)
                begin
                if (val[15:12]==4'd0)
                finish<=1;
                else 
                    begin 
                    val[15:12]<=val[15:12]-1;
                    val[11:8]<=4'd9;
                    val[7:4]<=4'd9;
                    val[3:0]<=4'd9;
                    end // if 1 bit is 0
                end
            else 
                begin
                val[11:8]<=val[11:8]-4'd1;
                val[7:4]<= 4'd9;
                val[3:0]<=4'd9;
                end// if 2 bit is 0
            end // if 3 bit is 0
        else
            begin
            val[7:4]<=val[7:4]-4'd1;
            val[3:0]<=4'd9;
            end
        end // if 4 bit is 0
    else 
    val[3:0]<=val[3:0]-4'd1;
    state<=IDLE;    
    end
    RESET:
    begin
        val[15:0]<=16'b0;
        remember<=0;
        finish<=0; 
        state<=IDLE;
    end//reset
    
    endcase    
    //end
    
end
assign led = state;
endmodule
