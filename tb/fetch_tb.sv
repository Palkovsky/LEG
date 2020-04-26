`timescale 1ns/1ns
module fetch_tb;
	parameter ADDR_WIDTH=12;
	parameter WORD_WIDTH=32;
	
	reg clk = 0;
	reg[WORD_WIDTH-1:0] memin = 0;
	wire[ADDR_WIDTH-1:0] addr;
	wire[WORD_WIDTH-1:0] inst;
	wire[WORD_WIDTH-1:0] out;
			
	// PC update logic
	reg[ADDR_WIDTH-1:0]  pc = 0;
	wire                 decode_is_jmp;
	wire[ADDR_WIDTH-1:0] fetch_next_pc;
	wire[ADDR_WIDTH-1:0] decode_next_pc;
	
	always @(posedge clk) begin
		pc <= (decode_is_jmp) ? decode_next_pc : fetch_next_pc;
	end
	
	wire fetch_stall, decode_stall, execute_stall;
	assign fetch_stall = 0;
	assign decode_stall = 0;
	assign execute_stall = 0;
	
	wire fetch_flush, decode_flush, execute_flush;
	assign fetch_flush = decode_is_jmp;
	assign decode_flush = decode_is_jmp;
	assign execute_flush = 0;
	
	wire fetch_ready, decode_ready;
	
fetch #(
	.ADDR_WIDTH(ADDR_WIDTH), .WORD_WIDTH(WORD_WIDTH)
) inst_fetch (
	.i_clk(clk),
	.i_flush(fetch_flush),
	.i_stall(fetch_stall),
	
	.o_ready(fetch_ready),
	
	.i_pc(pc),
	.i_mem_data(memin),
	.o_mem_addr(addr),
	.o_mem_write(),
	
	.o_next_pc(fetch_next_pc),
	.o_inst(inst)
);

wire[3:0]  opcode;
wire[11:0] operand_full;
wire[5:0]  operand1;
wire[5:0]  operand2;

decode #(
	.ADDR_WIDTH(ADDR_WIDTH), .WORD_WIDTH(WORD_WIDTH)
) inst_decode (
	.i_clk(clk), 
	.i_flush(decode_flush),
	.i_stall(decode_stall),
	
	.i_ready(fetch_ready),
	.o_ready(decode_ready),
	
	// Interface to fetch stage
	.i_inst(inst),
	
	// Interface to execute stage
	.o_opcode(opcode),
	.o_operand_full(operand_full),
	.o_operand1(operand1),
	.o_operand2(operand2),
	
	// Jumping logic
	.o_is_jmp(decode_is_jmp),
	.o_next_pc(decode_next_pc)
);

wire[3:0]  e_opcode;
wire[5:0]  e_operand1;
wire[5:0]  e_operand2;
wire[WORD_WIDTH-1:0]  e_r2;
wire[WORD_WIDTH-1:0]  e_r5;

execute #(
	.WORD_WIDTH(WORD_WIDTH)
) inst_execute (
	.i_clk(clk),
	.i_flush(execute_flush),
	.i_stall(execute_stall),
	
	.i_ready(decode_ready),
	
	.i_opcode(opcode),
	.i_operand1(operand1),
	.i_operand2(operand2),
	
	.o_opcode(e_opcode),
	.o_operand1(e_operand1),
	.o_operand2(e_operand2),
	.o_r2(e_r2),
	.o_r5(e_r5),
	
	.o_test(out)
);
	
	// Simulate memory
	always_comb begin
		case(addr)
			// LD r5, 2
			0:  memin  = 'hF1420000;
			// LD r2, 8
			4:  memin  = 'hF0880000;
			// ADD r5, r2
			8:  memin  = 'hD1420000;
			// OUT r5
			12: memin  = 'hB1400000;
			// JMP 0x008
			16: memin  = 'h90080000;
			// LD r5, 2 <- This shouldn't execute.
			20: memin  = 'hF1420000;
			default: memin = 'h00000000;
		endcase
	end
	
	initial begin
		#190 $finish;
	end

	always #2 clk <= ~clk;
endmodule
