module bram #(
	DATA_WIDTH,
	ADDR_WIDTH
)(
	input                       i_clk,
  input [DATA_WIDTH-1:0]      i_data,
  input [ADDR_WIDTH-1:0]      i_addr,
  input                       i_write,
  output reg [DATA_WIDTH-1:0] o_data
);
	 localparam RAM_SIZE=1<<ADDR_WIDTH;

   reg [DATA_WIDTH-1:0]       memory[0:RAM_SIZE-1];

	 always @(posedge i_clk) begin
      if (i_write)
        memory[i_addr] <= i_data;
      else
        o_data <= memory[i_addr];
	 end
endmodule
