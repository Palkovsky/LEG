
module vec_ram #(
  VEC_SIZE,
  VEC_INDEX_WIDTH
) (
  // Control signals
  input logic                       i_clk,
  input logic                       i_rst,

  // Read signals B
  input logic [VEC_INDEX_WIDTH-1:0] i_read_addr_a,
  output logic [15:0][VEC_SIZE-1:0] o_read_data_a,

  // Read signals A
  input logic [VEC_INDEX_WIDTH-1:0] i_read_addr_b,
  output logic [15:0][VEC_SIZE-1:0] o_read_data_b,

  // Write signals
  input logic                       i_write_enable,
  input logic [VEC_INDEX_WIDTH-1:0] i_write_addr,
  input logic [15:0][VEC_SIZE-1:0]  i_write_data
);

   /* (* romstyle = "logic" *) */logic [16 * VEC_SIZE - 1:0]      mem [0:(1<<VEC_INDEX_WIDTH)-1];

   logic [VEC_INDEX_WIDTH:0]        r_addr_a;
   logic [VEC_INDEX_WIDTH:0]        r_addr_b;

   initial begin
      for(int i = 0; i < (1<<VEC_INDEX_WIDTH); i++) begin
         mem[i] <= 0;
      end
   end

   always @(negedge i_clk) begin
      r_addr_a <= i_read_addr_a;
      r_addr_b <= i_read_addr_b;
   end

   assign o_read_data_a = mem[r_addr_a];
   assign o_read_data_b = mem[r_addr_b];

   always @(posedge i_clk) begin
      if (i_write_enable) begin
         mem[i_write_addr] <= i_write_data;
      end
   end
endmodule
