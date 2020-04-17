`timescale 1ns/1ns
module fetch_tb;
	parameter DATA_WIDTH=8;
	parameter ADDR_WIDTH=12;
	parameter INST_BYTES=2;
	parameter INST_SIZE=INST_BYTES*DATA_WIDTH;
	
	reg clk = 0;
	reg[ADDR_WIDTH-1:0] pc = 0;
	reg[DATA_WIDTH-1:0] memin = 0;
	wire[ADDR_WIDTH-1:0] addr;
	wire inst_ready;
	wire[INST_SIZE-1:0] inst;
	
fetch #(
	.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .INST_BYTES(INST_BYTES)
) inst_fetch (
	.i_clk(clk), .i_pc(pc),
	.i_mem_data(memin), .o_mem_addr(addr),
	.o_inst_ready(inst_ready), .o_inst(inst)
);
	
	always_comb begin
		case(addr)
			0: memin  = 'hFF;
			1: memin  = 'hEE;
			2: memin  = 'hDD;
			3: memin  = 'hCC;
			4: memin  = 'hBB;
			5: memin  = 'hAA;
			6: memin  = 'h99;
			7: memin  = 'h88;
			8: memin  = 'h77;
			9: memin  = 'h55;
			10: memin = 'h44;
			11: memin = 'h33;
			12: memin = 'h22;
			13: memin = 'h11;
			default: memin = 'h00;
		endcase
	end

	always @(posedge inst_ready) begin
		pc <= pc+INST_BYTES;
	end

	initial begin
		#100 $finish;
	end

	always #1 clk <= ~clk;
endmodule
