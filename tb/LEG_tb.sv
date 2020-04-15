module LEG_tb;
	
	reg r_clk;

	LEG l(
		.i_clk(r_clk)
	);
	
	// Initial register values
	initial begin 
		r_clk = 0;
		#50 $finish;
   end 
	
	
	// Clock generator
	always begin
		#1 r_clk = !r_clk; 
	end
endmodule