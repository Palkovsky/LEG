`timescale 1ns/1ns
module fetch_tb;
	parameter DATA_WIDTH=8;
	parameter ADDR_WIDTH=12;
	parameter INST_BYTES=2;
	parameter WORD_WIDTH=32;
	parameter INST_WIDTH=INST_BYTES*DATA_WIDTH;
	
	reg clk = 0;
	reg[ADDR_WIDTH-1:0] pc = 0;
	reg[DATA_WIDTH-1:0] memin = 0;
	wire inst_ack;
	wire inst_ready;
	wire running;
	wire[ADDR_WIDTH-1:0] addr;
	wire[INST_WIDTH-1:0] inst;
	wire[WORD_WIDTH-1:0] out;
	
fetch #(
	.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .INST_BYTES(INST_BYTES), .INST_WIDTH(INST_WIDTH)
) inst_fetch (
	.i_clk(clk), .i_inst_ack(inst_ack), .i_pc(pc),
	.i_mem_data(memin), .o_mem_addr(addr),
	.o_inst_ready(inst_ready), .o_inst(inst)
);

execute #(
	.WORD_WIDTH(WORD_WIDTH), .INST_WIDTH(INST_WIDTH)
) inst_execute (
	.i_clk(clk), .i_inst(inst), .i_inst_ready(inst_ready),
	.o_inst_ack(inst_ack), .o_executing(running), .o_test(out)
);
	
	always_comb begin
		case(addr)
			0:  memin  = 'hF0;
			1:  memin  = 'h88;
			2:  memin  = 'hF1;
			3:  memin  = 'h42;
			4:  memin  = 'hD1;
			5:  memin  = 'h42;
			6:  memin  = 'hB1;
			7:  memin  = 'h40;
			default: memin = 'h00;
		endcase
	end

	always @(posedge inst_ready) begin
		pc <= pc+INST_BYTES;
	end
	
	initial begin
		#100 $finish;
	end

	always #2 clk <= ~clk;
endmodule
