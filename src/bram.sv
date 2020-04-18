module bram #(
	DATA_WIDTH,
	ADDR_WIDTH,
	RAM_SIZE=1<<ADDR_WIDTH
)(
   input[DATA_WIDTH-1:0] i_data_a,
	input[DATA_WIDTH-1:0] i_data_b,

   input[ADDR_WIDTH-1:0] i_addr_a,
	input[ADDR_WIDTH-1:0] i_addr_b,

   input i_write_a,
	input i_write_b,

	input i_clk_a,
	input i_clk_b,

   output reg[DATA_WIDTH-1:0] o_data_a,
	output reg[DATA_WIDTH-1:0] o_data_b
);
   reg[DATA_WIDTH-1:0] memory[0:RAM_SIZE-1];

	// Port A
	always @(posedge i_clk_a) begin
      if (i_write_a) begin
         memory[i_addr_a] <= i_data_a;
         o_data_a <= i_data_a;
      end else
         o_data_a <= memory[i_addr_a];
	end
			
	// Port B
	always @(posedge i_clk_b) begin
      if (i_write_b) begin
         memory[i_addr_b] <= i_data_b;
         o_data_b <= i_data_b;
      end else
         o_data_b <= memory[i_addr_b];	
	end
endmodule