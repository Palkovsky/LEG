module fetch #(
	// Address bus width
	parameter ADDR_WIDTH,
	// Memory bus width
	parameter DATA_WIDTH,
	// How many bytes per instruction
	parameter INST_BYTES,
	parameter INST_WIDTH=INST_BYTES*DATA_WIDTH
)(
	input i_clk,
	input i_flush,	
	
	// Program Counter
	input[ADDR_WIDTH-1:0]  i_pc,
	
	// Memory interface
	input[DATA_WIDTH-1:0]  i_mem_data,
	output[ADDR_WIDTH-1:0] o_mem_addr,
	output                 o_mem_write,
	
	// Next stage interface
	input                  i_inst_ack,
	output                 o_inst_ready, // pulse
   output[INST_WIDTH-1:0] o_inst
);
	
	reg[INST_WIDTH-1:0] inst_buff  = 0;
	reg[INST_BYTES-1:0] inst_count = 0;
	reg                 inst_ready = 0;
	
	wire[INST_WIDTH-1:0] buff_idx;
	assign buff_idx = (INST_BYTES-inst_count)*DATA_WIDTH-1;
	
	// Pulse when instruction ready
	assign o_inst_ready = inst_ready;
	assign o_inst       = (o_inst_ready) ? inst_buff : 0;
	
	// Memory signals
	assign o_mem_addr  = i_pc+inst_count;
	assign o_mem_write = 0;
	
	always @(posedge i_clk) begin
		if(i_flush) begin
			// Pipeline flush
			inst_ready <= 0;
			inst_count <= 0;
		end else
		begin
			if(inst_ready && !i_inst_ack) begin
				// Pipeline stall
				inst_ready <= 1;
			end
			else begin
				inst_buff[buff_idx-:DATA_WIDTH] <= i_mem_data;
				inst_count <= (inst_count+1 == INST_BYTES) ? 0 : inst_count+1;
				inst_ready <= (inst_count+1 == INST_BYTES);
			end
		end
	end
endmodule