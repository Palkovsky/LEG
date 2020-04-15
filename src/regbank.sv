module regbank #(
 parameter ADDR_SIZE=12,
 parameter WORD_SIZE=32,
 parameter SIZE=1<<ADDR_SIZE
)(
  input                  i_clk,
  input                  i_write,
  input [ADDR_SIZE-1:0]  i_addr,
  input [WORD_SIZE-1:0]  i_value,
  output [WORD_SIZE-1:0] o_value[SIZE-1:0]
);
   reg[31:0] r_value[SIZE-1:0] = '{'{0}};

   assign o_value = r_value;

   always_ff @(posedge i_clk) begin
      if (i_write) begin
         r_value[i_addr] <= i_value;
      end
   end
endmodule
