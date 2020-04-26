module fetch #(
	parameter ADDR_WIDTH,
	parameter WORD_WIDTH
)(
	input i_clk,
	input i_flush,
	input i_stall,
	
	output reg o_ready,
	
	// Program Counter
	input[ADDR_WIDTH-1:0]  i_pc,
	
	// Memory interface
	input[WORD_WIDTH-1:0]  i_mem_data,
	output[ADDR_WIDTH-1:0] o_mem_addr,
	output                 o_mem_write,
	
	// PC interface
	output[ADDR_WIDTH-1:0] o_next_pc,
	output[WORD_WIDTH-1:0] o_inst
);
	// Instruction buffer and rediness state
	reg[WORD_WIDTH-1:0] inst = 0;		
	assign o_inst            = inst;
	
	// Memory signals
	assign o_mem_addr  = i_pc;
	assign o_mem_write = 0;
	
	// Next PC as seen by fetch stage. Might differ if JMP instruction in decode.
	assign o_next_pc = i_pc + WORD_WIDTH/8;
	
	always @(posedge i_clk) begin
		o_ready <= 0;
		if(i_flush) begin
			inst <= 0;
		end
		else if (!i_stall) begin
			o_ready <= 1;
			inst <= i_mem_data;
		end
	end
endmodule