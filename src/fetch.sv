`include "common.svh"

`define INST_BYTES 4

module fetch (
	input                   i_clk,
  input                   i_rst,
  input [31:0]            i_pc,

  input [`DATA_WIDTH-1:0] i_mem_data,
  output reg [31:0]       o_mem_addr,

  output reg [31:0]       o_inst = 0,
	output reg              o_ready,
  output reg              o_started = 0
);
   reg [3:0]              byte_cnt = 0;
   wire [3:0]             byte_cnt_next = byte_cnt+1;

   reg [3:0]              chunk_cnt = 0;
   wire [3:0]             chunk_cnt_next = chunk_cnt+1;

   wire [5:0]             chunk = (`INST_BYTES-chunk_cnt)*8-1;

   assign o_mem_addr = i_pc + byte_cnt;
   assign o_ready = chunk_cnt_next == `INST_BYTES;

   always @(posedge i_clk) begin
      if (i_rst) begin
         byte_cnt <= 0;
         chunk_cnt <= 0;
         o_started <= 0;
      end
      else begin
         o_started <= 1;
         byte_cnt <= byte_cnt_next;
         if(o_started) begin
            chunk_cnt <= chunk_cnt_next;
            o_inst[chunk -: 8] <= i_mem_data;
            if (o_ready) begin
               byte_cnt <= 0;
               chunk_cnt <= 0;
            end
         end
      end
   end
endmodule
