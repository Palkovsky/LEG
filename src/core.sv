module core(
	input i_clk,
	input i_rst
);
	parameter DATA_WIDTH=8;
	parameter ADDR_WIDTH=12;
	parameter INST_BYTES=4;
	parameter WORD_WIDTH=32;
	parameter INST_WIDTH=INST_BYTES*DATA_WIDTH;

	wire[DATA_WIDTH-1:0] bram_data_a;
	wire[ADDR_WIDTH-1:0] bram_addr_a;
	wire                 bram_write_a;
	wire[DATA_WIDTH-1:0] bram_data_out_a;
	
	wire bram_clk_b;
	assign bram_clk_b = 0;
	
	bram #(
		.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)
	) bram (
		.i_clk_a(i_clk), .i_clk_b(bram_clk_b),
		// Port A of BRAM
		.i_data_a(bram_data_a), .i_addr_a(bram_addr_a), .i_write_a(bram_write_a), .o_data_a(bram_data_out_a)
	);

endmodule