module LEG(
	input i_clk,
	output o_led
);
	
	reg r_output = 0;
	reg[25:0] r_counter = '0;

	assign o_led = r_output;
	
	always@(posedge i_clk) begin
		r_counter <= r_counter + 1;
		if (r_counter == 50000000) begin
			r_counter <= '0;
			r_output <= !r_output;
		end
	end
	
endmodule