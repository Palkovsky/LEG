module LEG_tb;
	
	reg r_clk;
	wire w_led;

	LEG l(
		.i_clk(r_clk),
		.o_led(w_led)
	);
	
	// Initial register values
	initial begin 
		r_clk = 0;
		#500000000 $finish;
   end 
	
	
	// Clock generator
	always begin
		#1 r_clk = !r_clk; 
	end
endmodule