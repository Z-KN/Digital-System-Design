`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/06/17 20:09:37
// Design Name: 
// Module Name: beep
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


module beep(
input key,
input clk,
input [1:0] select,
output reg beep
);

parameter do = 47774;
parameter ri = 42568;
parameter mi = 37919;
parameter fa = 35791;
parameter so = 31888;
parameter la = 28410;
parameter bxi = 26770;
parameter xi = 25309;
parameter dfa = 71581;
parameter dso = 63776;

reg [20:0] cnt;
reg [20:0] prediv;
reg [20:0] delay;

always @(posedge clk) begin
if (key == 1'b0&&select==0) begin
	beep <= 1'b0;
	delay <= 13'd0;
	cnt <= 16'd0;
	prediv <= 16'hBA9E;
end
else if(key == 1'b0&&select==1) begin
	beep <= 1'b0;
	delay <= 13'd0;
	cnt <= 16'd0;
	prediv <= 16'hBA9E;
end
else if (key == 1'b1&&select==0)begin
	cnt <= cnt + 1'b1;
	if (cnt == prediv) begin
		beep <= ~beep;
		cnt <= 0;
		delay <= delay +1'b1;
		case(delay)
			13'd0000:prediv <= do;
			13'd1000:prediv <= ri;
			13'd2000:prediv <= mi;
			13'd3000:prediv <= do;
			13'd4000:prediv <= do;
			13'd5000:prediv <= ri;
			13'd6000:prediv <= mi;
		    13'd7000:prediv <= do;
			8000:prediv <= mi;
			9000:prediv <= fa;
			10000:prediv <= so;
			11000:prediv <= so;
			12000:prediv <= mi;
			13000:prediv <= fa;
			14000:prediv <= so;
		    15000:prediv <= so;	
		    
		    16000:prediv <= so;	
		    16500:prediv <= la;
		    17000:prediv <= so;
		    17500:prediv <= fa;
		    18000:prediv <= mi;
		    19000:prediv <= do;
		    20000:prediv <= so;
		    20500:prediv <= la;
		    21000:prediv <= so;
		    21500:prediv <= fa;
		    22000:prediv <= mi;
		    23000:prediv <= do;
		    
		    24000:prediv <= ri;
		    25000:prediv <= dso;
		    26000:prediv <= do;
		    28000:prediv <= ri;
		    29000:prediv <= dso;
		    30000:prediv <= do;
		    32000:prediv <= 0;
			endcase
	end
	end
	else if (key == 1'b1&&select==1)begin
	cnt <= cnt + 1'b1;
	if (cnt == prediv) begin
		beep <= ~beep;
		cnt <= 0;
		delay <= delay +1'b1;
		case(delay)
			0000:prediv <= dfa;
			0500:prediv <= do;
			1300:prediv <= la;
			2300:prediv <= so;
			3300:prediv <= la;
			4300:prediv <= do;
			5100:prediv <= la;
		    6100:prediv <= do;
			7000:prediv  <= dfa;
			7500:prediv  <= do;
			8400:prediv <= la; 
			9500:prediv <= so;
			10500:prediv <= la;
			11500:prediv <= do;
			12300:prediv <= la;
		    13300:prediv <= do;
		    
		    14100:prediv <= dfa;	
		    14600:prediv <= ri ;
		    15400:prediv <= bxi;
		    16400:prediv <= la ;
		    17400:prediv <= bxi;
		    18400:prediv <= ri ;
		    19200:prediv <= bxi;
		    20200:prediv <= ri ;
		    21000:prediv <= dfa;
		    21500:prediv <= ri ;
		    22300:prediv <= bxi;
		    23300:prediv <= la ;
		    24300:prediv <= bxi;
		    25300:prediv <= ri ;
		    26100:prediv <= bxi;
		    27100:prediv <= ri ;
		    
		    28000:prediv <= dfa;
		    28500:prediv <= mi ;
		    29300:prediv <= bxi;
		    30300:prediv <= la ;
		    31300:prediv <= bxi;
		    32300:prediv <= mi ;
		    33100:prediv <= bxi;
		    34100:prediv <= mi ;
		    34900:prediv <= dfa;
		    35400:prediv <= mi ;
		    36200:prediv <= bxi;
		    37200:prediv <= la ;
		    38200:prediv <= bxi;
		    39200:prediv <= mi ;
		    40000:prediv <= bxi;
			41000:prediv <= mi ;
			
			41800:prediv <= dfa;
			42300:prediv <= fa ;
			43300:prediv <= la ;
			44300:prediv <= so ;
			45300:prediv <= la ;
			46300:prediv <= fa ;
			47300:prediv <= la ;
			48300:prediv <= fa ;
			49300:prediv <= dfa;
			49800:prediv <= fa ;
			50800:prediv <= la ;
			51800:prediv <= so ;
			52800:prediv <= la ;
			53800:prediv <= fa ;
			54800:prediv <= la ;
			55800:prediv <= mi ;
			
			56800:prediv <= 0 ;
			endcase
		end
	end 
end
endmodule

