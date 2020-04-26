module decode #(
	parameter ADDR_WIDTH,
	parameter WORD_WIDTH
)(
	input  i_clk,
	input  i_flush,
	input  i_stall,
		
	// Interface to fetch stage
	input[WORD_WIDTH-1:0] i_inst,
	
	// Interface to execute stage
	output[3:0]  o_opcode,
	output[11:0] o_operand_full,
	output[5:0]  o_operand1,
	output[5:0]  o_operand2,
	
	// Some higher-level signals
	output o_is_jmp,
	
	// Next PC will be used if o_is_jmp is high.
	output[ADDR_WIDTH-1:0] o_next_pc
);		
	// Decoding
	reg[WORD_WIDTH-1:0] inst = 0;
	assign o_opcode         = inst[WORD_WIDTH-1 -: 4];
	assign o_operand_full   = inst[WORD_WIDTH-5 -: 12];
	assign o_operand1       = inst[WORD_WIDTH-5 -: 6];
	assign o_operand2       = inst[WORD_WIDTH-11 -: 6];
	
	// JMP detection
	assign o_is_jmp  = (o_opcode == 'h9);
	assign o_next_pc = o_operand_full;
		
	always @(posedge i_clk) begin
		if(i_flush) begin
			inst <= 0;
		end
		else if (!i_stall) begin
			inst <= i_inst;
		end
	end
endmodule