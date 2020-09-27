
module vec_ram #(
  VEC_SIZE,
  VEC_INDEX_WIDTH
) (
  // Control signals
  input logic                       i_clk,
  input logic                       i_rst,

  // Read signals A
  input logic [VEC_INDEX_WIDTH-1:0] i_read_index_a,
  input logic [3:0]                 i_read_row_a,
  input logic                       i_read_matrix_a,
  output logic [15:0][VEC_SIZE-1:0] o_read_data_a,

  // Read signals B
  input logic [VEC_INDEX_WIDTH-1:0] i_read_index_b,
  input logic [3:0]                 i_read_row_b,
  input logic                       i_read_matrix_b,
  output logic [15:0][VEC_SIZE-1:0] o_read_data_b,

  // Write signals
  input logic                       i_write_enable,
  input logic [VEC_INDEX_WIDTH-1:0] i_write_index,
  input logic [3:0]                 i_write_row,
  input logic                       i_write_matrix,
  input logic [15:0][VEC_SIZE-1:0]  i_write_data
);

   logic [16 * VEC_SIZE - 1:0]      mem [0:(32 + 32 * 16)-1] = '{(32 + 32 * 16) {16'h0}};

   logic [9:0]        r_addr_a;
   logic [9:0]        r_addr_b;
   logic [9:0]        w_write_addr;        

   initial begin
      for(int i = 0; i < (1<<VEC_INDEX_WIDTH); i++) begin
         mem[i] <= 0;
      end
   end

   always @(negedge i_clk) begin
      if (i_read_matrix_a) begin
         r_addr_a <= 32 + i_read_index_a * 16 + i_read_row_a;
      end else begin
         r_addr_a <= i_read_index_a;
      end
      if (i_read_matrix_b) begin
         r_addr_b <= 32 + i_read_index_b * 16 + i_read_row_b;
      end else begin
         r_addr_b <= i_read_index_b;
      end
   end

   always_comb begin
      if (i_write_matrix) begin
         w_write_addr <= 32 + i_write_index * 16 + i_write_row;
      end else begin
         w_write_addr <= i_write_index;
      end
   end

   assign o_read_data_a = mem[r_addr_a];
   assign o_read_data_b = mem[r_addr_b];

   always @(posedge i_clk) begin
      if (i_write_enable) begin
         mem[w_write_addr] <= i_write_data;
      end
   end
endmodule
