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
      //o_vec_mul <= i_vec_a[0];
      for (int i = 0; i < VEC_SIZE; i++) begin
         o_vec_mul[i] <= fixpoint_mul(i_vec_a[i], i_vec_b[i]);
      end
   end

   // Elementwise addition
   always_comb begin
      //o_vec_add <= i_vec_a[0];
      for (int i = 0; i < VEC_SIZE; i++) begin
         o_vec_add[i] <= fixpoint_add(i_vec_a[i], i_vec_b[i]);
      end
   end

   // DOT product
   always_comb begin
      automatic logic[`FIXPOINT_WIDTH - 1:0] res[0:VEC_SIZE - 1];
      for (int i = 0; i < VEC_SIZE; i++) begin
         res[i] = o_vec_mul[i];
      end
      for (int l = 1; l < VEC_SIZE; l *= 2) begin
         for (int i = 0; i < VEC_SIZE; i += 2 * l) begin
            res[i] = fixpoint_add(res[i], res[i + l]);
         end
      end
      o_dot <= res[0];
   end

endmodule
