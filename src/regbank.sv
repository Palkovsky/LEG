module regbank #(
 parameter ADDR_WIDTH,
 parameter WORD_WIDTH,
 parameter SIZE=1<<ADDR_WIDTH
)(
  input                  i_clk,
  input                  i_write,
  input [ADDR_WIDTH-1:0]  i_addr,
  input [WORD_WIDTH-1:0]  i_value,
  output [WORD_WIDTH-1:0] o_value[SIZE-1:0]
);
   reg[WORD_WIDTH-1:0] r_value[SIZE-1:0];// = '{'{0}}; <-- this doesn't work in ModelSim

   assign o_value = r_value;

   always @(posedge i_clk) begin
      if (i_write) begin
         r_value[i_addr] <= i_value;
      end
   end
endmodule
