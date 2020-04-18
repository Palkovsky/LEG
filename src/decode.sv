module decode #(
	parameter ADDR_WIDTH,
	parameter INST_WIDTH
)(
	input  i_clk,
	input  i_flush,
	output o_flush,
	
	// Interface to fetch stage
	input[INST_WIDTH-1:0] i_inst,
	input                 i_inst_ready,
	output                o_inst_ack,
	
	// Interface to execute stage
	output[3:0]  o_opcode,
	output[11:0] o_operand_full,
	output[5:0]  o_operand1,
	output[5:0]  o_operand2,
	
	// PC update in case of JMP instruction
	output                 o_new_pc_trig,
	output[ADDR_WIDTH-1:0] o_new_pc,
	
	output o_inst_ready,
	input  i_inst_ack
);
	reg busy = 0;
	assign o_inst_ready = busy;
	assign o_inst_ack   = busy;
	
	// Decoding
	reg[INST_WIDTH-1:0] inst = 0;
	assign o_opcode         = inst[INST_WIDTH-1 -: 4];
	assign o_operand_full   = inst[INST_WIDTH-5 -: 12];
	assign o_operand1       = inst[INST_WIDTH-5 -: 6];
	assign o_operand2       = inst[INST_WIDTH-11 -: 6];
	
	wire is_jmp;
	reg  flush = 0;
	assign is_jmp        = (o_opcode == 'h9);
	assign o_flush       = (i_flush || flush);
	assign o_new_pc_trig = is_jmp;
	assign o_new_pc      = o_operand_full;
	
	always @(posedge i_clk) begin
		if(i_flush) begin
			busy <= 0;
			inst <= 0;
		end
		else begin
			// Flush pulse on jump instruction
			flush <= 0;
			if(is_jmp) begin
				flush <= 1;
				inst <= 0;
				busy <= 0;
			end
			// If idle and new data available.
			if(i_inst_ready && !busy) begin
				busy <= 1;
				inst <= i_inst;
			end
			// If busy and got ACK.
			if(busy && i_inst_ack) begin
				busy <= 0;
				if(i_inst_ready) begin
					busy <= 1;
					inst <= i_inst;
				end
			end
		end
	end
endmodule