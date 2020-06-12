`include "common.svh"

module core(
	input i_clk,
	input i_rst
);
	 wire [`DATA_WIDTH-1:0] bram_input_a;
   wire [`DATA_WIDTH-1:0] bram_input_b;
	 wire [`ADDR_WIDTH-1:0] bram_addr_a;
	 wire [`ADDR_WIDTH-1:0] bram_addr_b;
	 wire                   bram_write_a;
	 wire                   bram_write_b;
	 wire [`DATA_WIDTH-1:0] bram_output_a;
	 wire [`DATA_WIDTH-1:0] bram_output_b;

	bram #(
    .DATA_WIDTH(`DATA_WIDTH),
    .ADDR_WIDTH(`ADDR_WIDTH)
  ) bram (
		.i_clk_a(i_clk),
		.i_data_a(bram_input_a),
    .i_addr_a(bram_addr_a),
    .i_write_a(bram_write_a),
    .o_data_a(bram_output_a),
    .i_clk_b(bram_clk_b),
    .i_data_b(bram_input_b),
    .i_addr_b(bram_addr_b),
    .i_write_b(bram_write_b),
    .o_data_b(bram_output_b)
	);

/*
  fetch (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_pc(_)
    .i_mem_data(..),
    .o_mem_addr(..),
    .o_mem_write(..),
    .o_inst(..),
    .o_ready(..)
  );
*/
endmodule
