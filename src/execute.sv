module execute #(
	parameter WORD_WIDTH=32,
	parameter INST_WIDTH=16
)(
	input                      i_clk,
	input[INST_WIDTH-1:0]      i_inst,
	input                      i_inst_ready,
	
	output                     o_inst_ack,
	output                     o_executing,
	output reg[WORD_WIDTH-1:0] o_test
);
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
	
	reg executing            = 0;
	reg inst_ack             = 0;
	reg[INST_WIDTH-1:0] inst = 0;
	assign o_inst_ack  = inst_ack;
	assign o_executing = executing;
	
	wire[3:0] opcode;
	wire[5:0] operand1, operand2;
	assign opcode     = inst[INST_WIDTH-1 -: 4];
	assign operand1   = inst[INST_WIDTH-5 -: 6];
	assign operand2   = inst[INST_WIDTH-11 -: 6];
	
	wire fetch_next;
	assign fetch_next = (i_inst_ready && !executing);
	
	always @(posedge i_clk) begin
		// Latch new instruction if possible
		inst_ack <= 0;
		if(fetch_next) begin
			inst      <= i_inst;
			executing <= 1;
			inst_ack  <= 1;
		end
		
		// Execute latched instruction
		regbank_write_trig <= 0;
		if(executing) begin
			executing <= 0;
			case(opcode)
				'hF: begin
					regbank_addr <= operand1;
					regbank_write_val <= operand2;
					regbank_write_trig <= 1;
				end
				'hD: begin 
					regbank_addr <= operand1;
					regbank_write_val <= regbank_value[operand1] + regbank_value[operand2];
					regbank_write_trig <= 1;
				end
				'hB: o_test <= regbank_value[operand1];
			endcase
		end
	end
endmodule