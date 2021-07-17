`timescale 1ns / 1ns
module testTanh();
	parameter number = 3;
    reg clk, rst;
	reg [15:0] z0;
	wire [15:0] out;
	wire flag;
	integer f, index;
	reg [15:0] data [0:number-1];
	
	cordicTanh DUT(.clk(clk),
						.flag(flag),
						.rst(rst),
						.out(out),
                        .z0(z0) );
	
	initial
	begin
		index = 0;
		f = $fopen("outputValue.txt", "w");
		$readmemh("data.txt", data);
		clk = 1'b0;
		rst = 1'b1;
		z0 = data[index];
		$display("value: %h", z0);
		index = index + 1;
		#50 rst = 1'b0;
	end
	
	always #5 clk = ~clk; 

	always@(posedge flag)
	begin
		$fdisplay(f, "tanh of %h is: %h", z0, out);
		z0 = data[index];
		index = index + 1;
		if (index == number + 1)
		begin
			$fclose(f); 
			$finish;
		end
	end
	
endmodule
