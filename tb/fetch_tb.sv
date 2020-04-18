`timescale 1ns/1ns
module fetch_tb;
	parameter DATA_WIDTH=8;
	parameter ADDR_WIDTH=12;
	parameter INST_BYTES=4;
	parameter WORD_WIDTH=32;
	parameter INST_WIDTH=INST_BYTES*DATA_WIDTH;
	
	reg clk = 0;
	reg[ADDR_WIDTH-1:0] pc = 0;
	reg[DATA_WIDTH-1:0] memin = 0;
	wire executing;
	wire[ADDR_WIDTH-1:0] addr;
	wire[INST_WIDTH-1:0] inst;
	wire[WORD_WIDTH-1:0] out;
	
	wire glob_flush, execute_flush, decode_flush;
	assign glob_flush = 0;
	
	wire execute_ack, decode_ack;
	wire fetch_ready, decode_ready;
	
fetch #(
	.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .INST_BYTES(INST_BYTES), .INST_WIDTH(INST_WIDTH)
) inst_fetch (
	.i_clk(clk),
	.i_flush(decode_flush), 
	
	.i_pc(pc),
	.i_mem_data(memin),
	.o_mem_addr(addr),
	.o_mem_write(),
	
	.i_inst_ack(decode_ack), 
	.o_inst_ready(fetch_ready), 
	.o_inst(inst)
);

wire[3:0]  opcode;
wire[11:0] operand_full;
wire[5:0]  operand1;
wire[5:0]  operand2;

wire                 new_pc_trig;
wire[ADDR_WIDTH-1:0] new_pc;

decode #(
	.ADDR_WIDTH(ADDR_WIDTH), .INST_WIDTH(INST_WIDTH)
) inst_decode (
	.i_clk(clk), 
	.i_flush(execute_flush),
	.o_flush(decode_flush),
	
	// Interface to fetch stage
	.i_inst(inst),
	.i_inst_ready(fetch_ready),
	.o_inst_ack(decode_ack),
	
	// Interface to execute stage
	.o_opcode(opcode),
	.o_operand_full(operand_full),
	.o_operand1(operand1),
	.o_operand2(operand2),
	
	// Early detection on jump
	.o_new_pc_trig(new_pc_trig),
	.o_new_pc(new_pc),
	
	.o_inst_ready(decode_ready),
	.i_inst_ack(execute_ack)
);

execute #(
	.WORD_WIDTH(WORD_WIDTH), .INST_WIDTH(INST_WIDTH)
) inst_execute (
	.i_clk(clk),
	.i_flush(glob_flush),
	.o_flush(execute_flush),
	
	.i_inst_ready(decode_ready),
	.o_inst_ack(execute_ack),
	
	.i_opcode(opcode),
	.i_operand1(operand1),
	.i_operand2(operand2),
	
	.o_executing(executing), 
	.o_test(out)
);
	
	always_comb begin
		case(addr)
			// LD r5, 2
			0:  memin  = 'hF1;
			1:  memin  = 'h42;
			// LD r2, 8
			4:  memin  = 'hF0;
			5:  memin  = 'h88;
			// ADD r5, r2
			8:  memin  = 'hD1;
			9:  memin  = 'h42;
			// OUT r5
			12: memin  = 'hB1;
			13: memin  = 'h40;
			// JMP 0x008
			16: memin  = 'h90;
			17: memin  = 'h08;
			default: memin = 'h00;
		endcase
	end

	always @(posedge fetch_ready) begin
		pc <= pc+INST_BYTES;
	end
	
	always @(posedge new_pc_trig) begin
		pc <= new_pc;
	end
	
	initial begin
		#190 $finish;
	end

	always #2 clk <= ~clk;
endmodule
