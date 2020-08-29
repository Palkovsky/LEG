`include "fixpoint.svh"

module vec_mul #(
  VEC_SIZE = 16
) (
  input logic [VEC_SIZE - 1:0][`FIXPOINT_WIDTH - 1:0]   i_vec_a,
  input logic [VEC_SIZE - 1:0][`FIXPOINT_WIDTH - 1:0]   i_vec_b,

  output logic [VEC_SIZE - 1:0][`FIXPOINT_WIDTH - 1:0]  o_vec_mul,
  output logic [VEC_SIZE - 1:0] [`FIXPOINT_WIDTH - 1:0] o_vec_add,
  output logic [`FIXPOINT_WIDTH - 1:0]                  o_dot
);

   // Elementwise multiplication
   always_comb begin
      for (int i = 0; i < VEC_SIZE; i++) begin
         o_vec_mul[i] <= fixpoint_mul(i_vec_a[i], i_vec_b[i]);
      end
   end

   // Elementwise addition
   always_comb begin
      for (int i = 0; i < VEC_SIZE; i++) begin
         o_vec_add[i] <= fixpoint_add(i_vec_a[i], i_vec_b[i]);
      end
   end

   // DOT product
   always_comb begin
      automatic logic[`FIXPOINT_WIDTH - 1:0] res = 0;
      for (int i = 0; i < VEC_SIZE; i++) begin
         res = fixpoint_add(res, o_vec_mul[i]);
      end
      o_dot <= res;
   end

endmodule
