`include "../tb/funcs.svh"

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

	initial begin
		 for (int i=0; i<RAM_SIZE; i++) begin
			  memory[i] = 0;
		 end
		 // ADDI x1, x0, 65 | 32'h04100093
		 { memory[0], memory[1], memory[2], memory[3] } = IMM_OP(1, 0, "+", 65);
		 // ADDI x2, x0, -1 | 32'hfff00113
		 { memory[4], memory[5], memory[6], memory[7] } = IMM_OP(2, 0, "+", 'hFFF);
		 // SB x1, 0(x2) | 32'h00110023
		 { memory[8], memory[9], memory[10], memory[11] } = S(`STORE, `SB, 2, 0, 1);
		 // JAL x0, -4 | 32'hffdff06f
		 { memory[12], memory[13], memory[14], memory[15] } =  32'hffdff06f;
	end

	 always @(posedge i_clk) begin
      if (i_write)
        memory[i_addr] <= i_data;
      else
        o_data <= memory[i_addr];
	 end
endmodule
