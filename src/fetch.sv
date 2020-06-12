`include "common.svh"

`define INST_BYTES `INST_WIDTH/8

module fetch (
	input                        i_clk,
  input                        i_rst,
  input [`WORD_WIDTH-1:0]      i_pc,

  input [`DATA_WIDTH-1:0]      i_mem_data,
  output reg [`ADDR_WIDTH-1:0] o_mem_addr,
  output reg                   o_mem_write = 0,

  output reg [`INST_WIDTH-1:0] o_inst = 0,
	output reg                   o_ready = 0
);
   reg [5:0]                   counter = 0;
   assign o_mem_addr = i_pc[`ADDR_WIDTH-1:0] + counter;

   always @(posedge i_clk) begin
      o_ready <= 0;
      counter <= counter+1;

      if (i_rst) begin
         o_inst <= 0;
         counter <= 0;
      end
      else begin
         o_inst[((`INST_BYTES-counter)*8-1) -: 8] <= i_mem_data;
         // When instruction is ready.
         if (counter+1 == `INST_BYTES) begin
            o_ready <= 1;
            counter <= 0;
         end
      end
   end
endmodule
