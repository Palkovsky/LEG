module execute #(
	parameter WORD_WIDTH
)(
	input  i_clk,
	input  i_flush,
	input  i_stall,
	
	input  i_ready,
	
	input[3:0] i_opcode,
	input[5:0] i_operand1,
	input[5:0] i_operand2,
	
	output[3:0] o_opcode,
	output[5:0] o_operand1,
	output[5:0] o_operand2,
	output[WORD_WIDTH-1:0] o_r2,
	output[WORD_WIDTH-1:0] o_r5,
	
	output reg[WORD_WIDTH-1:0] o_test
);
	parameter REGBANK_ADDR_WIDTH = 10;
	parameter REGBANK_SIZE = 1<<REGBANK_ADDR_WIDTH;
	
	logic[REGBANK_ADDR_WIDTH-1:0] regbank_addr;
	logic[WORD_WIDTH-1:0]         regbank_write_val;
	logic[WORD_WIDTH-1:0]         regbank_value[REGBANK_SIZE-1:0];
	logic                         regbank_write_trig; 
	
	regbank #(
		.ADDR_WIDTH(REGBANK_ADDR_WIDTH), .WORD_WIDTH(WORD_WIDTH), .SIZE(REGBANK_SIZE)
	) regbank (
		.i_clk(i_clk), .i_addr(regbank_addr),
		.i_value(regbank_write_val), .i_write(regbank_write_trig),
		.o_value(regbank_value) 
	);
	
	reg[3:0] opcode   = 0;
	reg[5:0] operand1 = 0;
	reg[5:0] operand2 = 0;
	
	// For debugging
	assign o_opcode = opcode;
	assign o_operand1 = operand1;
	assign o_operand2 = operand2;
	assign o_r2 = regbank_value[2];
	assign o_r5 = regbank_value[5];
	
	// Write/read signals have to be set in comb block, to avoid two-clock delay.
	always_comb begin
		regbank_write_trig = (opcode == 'hF || opcode == 'hD);
		case(opcode)
			'hF: begin // LD rx, imm
				regbank_addr = operand1;
				regbank_write_val = operand2;
			 end
			 'hD: begin // ADD rx, ry
				regbank_addr = operand1;
				regbank_write_val = regbank_value[operand1] + regbank_value[operand2];
			 end
			 default: begin
				regbank_addr = 0;
				regbank_write_val = 0;
			 end
		endcase
	end
			
	always @(posedge i_clk) begin
		if(i_flush) begin
			{opcode, operand1, operand2} <= 0;
		end
		else if(!i_stall && i_ready) begin
			// Load next stage
			if(i_ready) begin
				{opcode, operand1, operand2} <= {i_opcode, i_operand1, i_operand2};
			end
			
			case(opcode)
				'hB: o_test <= regbank_value[operand1];
			endcase
		end
	end
endmodule