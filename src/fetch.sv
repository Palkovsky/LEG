`include "common.svh"

`define INST_BYTES 4

module fetch (
	input                   i_clk,
  input                   i_rst,
  input                   i_stall,
  input [31:0]            i_pc,

  // Memory read interface
  input [`DATA_WIDTH-1:0] i_data,
  output wire [31:0]      o_addr,
  input                   i_valid,
  output wire             o_ready,

  output reg [31:0]       o_inst = 0,
  output reg              o_finished
);
   assign o_addr = i_pc;
   assign o_ready = !i_rst;
   assign o_finished = (!i_stall && !i_rst && o_ready && i_valid);

   always @(posedge i_clk) begin
      if (i_rst)
         o_inst <= 0;
      else if (o_ready && i_valid && !i_stall)
         o_inst <= i_data[31:0];
   end
endmodule
