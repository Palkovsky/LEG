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
   reg [3:0]              counter = 0;
   wire [3:0]             counter_next = counter+1;
   wire [5:0]             chunk = (`INST_BYTES-counter)*8-1;

   assign o_mem_addr = i_pc + counter;
   assign o_ready = counter_next == `INST_BYTES;

   always @(posedge i_clk) begin
      if (i_rst) begin
         counter <= 0;
         o_started <= 0;
      end
      else begin
         o_started <= 1;
         o_inst[chunk -: 8] <= i_mem_data;
         counter <= counter_next;

          if (counter_next == `INST_BYTES)
            counter <= 0;
      end
   end
endmodule
