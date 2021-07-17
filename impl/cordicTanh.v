module cordicTanh(z0, clk, rst, out, flag);	
	input wire clk, rst;
	input wire signed [15:0] z0;
	output wire signed [15:0] out;
	output reg flag;
	
	reg [3:0] itr;
	reg signed [15:0] zj;
	wire signed [15:0] zn, zi, zval;
	reg signed [1:0] zsel;
	wire di;
	reg m;
	wire signed [15:0] tmpOut;
	reg [1:0] extreme;
	wire signed [15:0] extremeCheckN, extremeCheckP;
	reg signed [15:0] yj, xj;
	wire signed [15:0] yn, yi, yval, xn, xi, xval; 
	reg ysel, xsel;

	reg hold, clear;
	// states:
	parameter [2:0] RST = 3'b000,
					TANH = 3'b001,
					REPEAT = 3'b010,
					DIVIDE = 3'b011,
					EXTR = 3'b100;
	reg [2:0] CS, NS;

	// inverse tanh values:
	reg signed [15:0] ROM;
	always@(itr)
		case(itr)
			4'b0001: ROM = 16'h08CA;
			4'b0010: ROM = 16'h0416;
			4'b0011: ROM = 16'h0203;
			4'b0100: ROM = 16'h0100;
			4'b0101: ROM = 16'h0080;
			4'b0110: ROM = 16'h0040;
			4'b0111: ROM = 16'h0020;
			4'b1000: ROM = 16'h0010;
			4'b1001: ROM = 16'h0008;
			4'b1010: ROM = 16'h0004;
			4'b1011: ROM = 16'h0002;
			4'b1100: ROM = 16'h0001;
			4'b1101: ROM = 16'h0001;
			default: ROM = 16'h0001;
		endcase

	//------------------------------DATAPATH--------------------------------//
	// z section:

	assign zval = (zsel == 2'b00) ? z0 : // zj multiplexer
				  (zsel == 2'b01) ? 16'h0000:
				  (zsel == 2'b10) ? zn : 16'h0000;

	always @(posedge clk) 
		if(rst)
			zj <= 16'h0000;
		else
			zj <= zval;

	assign di = (m == 1'b0) ? zj[15] : (~yj[15]); // decision sign
	assign zi = (m == 1'b0) ? ROM : (16'h1000 >>> itr); // select between ROM or 2^(-i)
	assign zn = (di == 1'b0) ? zj - zi : zi + zj;

	// y and x section:

	assign yval = (ysel == 1'b0) ? 16'h0000 : yn;

	always @(posedge clk) 
		if(rst)
			yj <= 16'h0000;
		else
			yj <= yval;

	assign yi = xj >>> itr;
	assign yn = (di == 1'b0) ? yj + yi : yj - yi;

	assign xval = (xsel == 1'b0) ? 16'h1000 : xn; // 1 or xn
	
	always @(posedge clk) 
		if(rst)
			xj <= 16'h1000;
		else
			xj <= xval;

	assign xi = yj >>> itr;
	assign xn = ({di, m} == 2'b00) ? xj + xi : 
				({di, m} == 2'b10) ? xj - xi : xj;


	// itr counter:
	always@(posedge clk)
		if(clear || rst)
			itr <= 5'b0_0001;
		else if(~hold)
			itr <= itr + 5'b0_0001;
	
	// check extreme situation:
	assign extremeCheckP = z0 - 16'h4000;
	assign extremeCheckN = z0 - 16'hC000;

	//-------------------------------------CONTROLLER------------------------------------//

	always @(CS, itr)
	case(CS)
		RST:
		begin // extreme case:
		if (extremeCheckP[15] == 1'b0 || extremeCheckN[15] == 1'b1) 
			begin
			extreme = 2'b00;
			m = 1'b0;
			ysel = 1'b0;
			xsel = 1'b0;
			zsel = 2'b00;
			hold = 1'b1;
			clear = 1'b1;
			flag = 1'b0;
			NS = EXTR;				
			end
		else 
			begin
			extreme = 2'b00;
			m = 1'b0; // tanh mode		
			ysel = 1'b0;
			xsel = 1'b0;
			zsel = 2'b00;
			hold = 1'b1;
			clear = 1'b1;
			flag = 1'b0;
			NS = TANH;
			end
		end
		EXTR:
			if(extremeCheckP[15] == 1'b0 && z0[15] == 1'b0) // number is greater than 4
				begin
				extreme = 2'b01;
				m = 1'b0;		
				ysel = 1'b0;
				xsel = 1'b0;
				zsel = 2'b00;
				hold = 1'b1;
				clear = 1'b1;
				flag = 1'b1;
				NS = RST;
				end
			else if(extremeCheckN[15] == 1'b1 && z0[15] == 1'b1) // number is less than 4
				begin
				extreme = 2'b10;
				m = 1'b0;		
				ysel = 1'b0;
				xsel = 1'b0;
				zsel = 2'b00;
				hold = 1'b1;
				clear = 1'b1;
				flag = 1'b1;
				NS = RST;
				end
		TANH:
			if(itr == 5'b0_1110) // 13 times iteration has been done
				begin
				extreme = 2'b00;	
				m = 1'b1;
				ysel = 1'b1;
				xsel = 1'b1;
				zsel = 2'b01;
				hold = 1'b1;
				clear = 1'b1;
				NS = DIVIDE;
				flag = 1'b0;
				end
			else
				begin
				extreme = 2'b00; // continue iteration
				m = 1'b0;
				ysel = 1'b1;
				xsel = 1'b1;
				zsel = 2'b10;
				hold = 1'b1;
				clear = 1'b0;
				NS = REPEAT;
				flag = 1'b0;
				end
		REPEAT: // repeat current tanh itereation once more
			begin
			extreme = 2'b00;	
			m = 1'b0;
			ysel = 1'b1;
			xsel = 1'b1;
			zsel = 2'b10;
			hold = 1'b0;
			clear = 1'b0;
			NS = TANH;
			flag = 1'b0;
			end
		DIVIDE: 
		if (itr == 5'b0_1110) // 13 times of division itereation has been done
			begin             // so just reset the circuit and get new value
			extreme = 2'b00;
			m = 1'b0;
			ysel = 1'b0;
			xsel = 1'b0;
			zsel = 2'b00;
			hold = 1'b1;
			clear = 1'b1;
			NS = RST;
			flag = 1'b1;
			end
		else
			begin // continue division
			extreme = 2'b00;
			m = 1'b1;
			ysel = 1'b1;
			xsel = 1'b1;
			zsel = 2'b10;
			hold = 1'b0;
			clear = 1'b0;
			flag = 1'b0;
			NS = DIVIDE;
			end
	endcase 
	
	always@(posedge clk) // CS assignment
		if(rst)
			CS <= RST;
		else
			CS <= NS;
	
	// extreme condition check
	assign tmpOut = (extreme == 2'b00) ? zn : 
					(extreme == 2'b01) ? 16'h1000 :
					(extreme == 2'b10) ? 16'hF000 : zn;
	
	// output assignment:				
	assign out = (flag) ? tmpOut : 16'hzzzz;
endmodule

