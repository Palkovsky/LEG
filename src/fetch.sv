module fetch #(
	// Address bus width
	parameter ADDR_WIDTH=12,
	// Memory bus width
	parameter DATA_WIDTH=8,
	// How many bytes per instruction
	parameter INST_BYTES=2,
	parameter INST_WIDTH=INST_BYTES*DATA_WIDTH
)(
	input i_clk,
	// Program Counter
	input[ADDR_WIDTH-1:0] i_pc,
	// Memory interface
	input[7:0]             i_mem_data,
	output[ADDR_WIDTH-1:0] o_mem_addr,
	output                 o_mem_write,
	// Output instructions
	output                 o_inst_ready, // pulse
   output[INST_WIDTH-1:0] o_inst
);
	
	reg[INST_WIDTH-1:0] inst_buff = '0;
	reg[INST_BYTES-1:0] inst_count = '0;
	reg                 inst_ready = 0;
	
	wire[INST_WIDTH-1:0] buff_idx;
	assign buff_idx = (INST_BYTES-inst_count)*DATA_WIDTH-1;
	
	// Pulse when instruction ready
	assign o_inst_ready = inst_ready;
	assign o_inst = (o_inst_ready) ? inst_buff : 0;
	
	// Read-only
	assign o_mem_addr  = i_pc+inst_count;
	assign o_mem_write = 0;
	
	always @(posedge i_clk) begin
		inst_buff[buff_idx-:DATA_WIDTH] <= i_mem_data;
		if (inst_count+1 == INST_BYTES) begin
			inst_count <= 0;
			inst_ready <= 1;
		end 
		else begin
			inst_count <= inst_count+1;
			inst_ready <= 0;
		end
	end
endmodule