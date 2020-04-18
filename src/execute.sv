module execute #(
	parameter WORD_WIDTH,
	parameter INST_WIDTH
)(
	input  i_clk,
	input  i_flush,
	output o_flush,
	
	input[3:0] i_opcode,
	input[5:0] i_operand1,
	input[5:0] i_operand2,
	input      i_inst_ready,
	
	output                     o_inst_ack,
	output                     o_executing,
	output reg[WORD_WIDTH-1:0] o_test
);
	assign o_flush = i_flush;

	parameter REGBANK_ADDR_WIDTH = 10;
	parameter REGBANK_SIZE = 1<<REGBANK_ADDR_WIDTH;
	reg[REGBANK_ADDR_WIDTH-1:0] regbank_addr = 0;
	reg[WORD_WIDTH-1:0]         regbank_write_val = 0;
	reg                         regbank_write_trig = 0; 
	wire[WORD_WIDTH-1:0]        regbank_value[REGBANK_SIZE-1:0];
	regbank #(
		.ADDR_WIDTH(REGBANK_ADDR_WIDTH), .WORD_WIDTH(WORD_WIDTH), .SIZE(REGBANK_SIZE)
	) regbank (
		.i_clk(i_clk), .i_addr(regbank_addr),
		.i_value(regbank_write_val), .i_write(regbank_write_trig),
		.o_value(regbank_value) 
	);
		
	reg executing = 0;
	reg inst_ack  = 0;
	assign o_inst_ack  = inst_ack;
	assign o_executing = executing;
	
	always @(posedge i_clk) begin
		if(i_flush) begin
			executing <= 0;
			inst_ack  <= 0;
			regbank_write_trig <= 0;
		end
		else begin
			// Latch new instruction if possible
			inst_ack <= 0;
			if(i_inst_ready && !executing) begin
				executing <= 1;
				inst_ack  <= 1;
			end
			// Execute latched instruction
			regbank_write_trig <= 0;
			if(executing) begin
				executing <= 0;
				case(i_opcode)
					'hF: begin // LD rx, imm
						regbank_addr <= i_operand1;
						regbank_write_val <= i_operand2;
						regbank_write_trig <= 1;
					end
					'hD: begin // ADD rx, ry
						regbank_addr <= i_operand1;
						regbank_write_val <= regbank_value[i_operand1] + regbank_value[i_operand2];
						regbank_write_trig <= 1;
					end
					'hB: o_test <= regbank_value[i_operand1];
					'h9: begin // JMP [addr]
					end
				endcase
			end
		end
	end
endmodule