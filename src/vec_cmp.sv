`include "fixpoint.svh"
`include "common.svh"

module vec_cmp #(
  VEC_SIZE = 16
) (
  input logic[2:0] i_op,
  input logic[VEC_SIZE - 1:0] i_mask,
  input logic[VEC_SIZE - 1:0][`FIXPOINT_WIDTH - 1:0] i_vec_a,
  input logic[VEC_SIZE - 1:0][`FIXPOINT_WIDTH - 1:0] i_vec_b,

  output logic[VEC_SIZE - 1:0] o_mask
);

  always_comb begin
    o_mask <= 0;
    case (i_op)
      `VEC_EQ: begin
        for (int i = 0; i < VEC_SIZE; i++) begin
          o_mask[i] <= (i_mask[i] && i_vec_a[i] == i_vec_b[i]);
        end
      end
      `VEC_NE: begin
        for (int i = 0; i < VEC_SIZE; i++) begin
          o_mask[i] <= (i_mask[i] && i_vec_a[i] != i_vec_b[i]);
        end
      end
      `VEC_LT: begin
        for (int i = 0; i < VEC_SIZE; i++) begin
          o_mask[i] <= (i_mask[i] && $signed(i_vec_a[i]) < $signed(i_vec_b[i]));
        end
      end
      `VEC_LE: begin
        for (int i = 0; i < VEC_SIZE; i++) begin
          o_mask[i] <= (i_mask[i] && $signed(i_vec_a[i]) <= $signed(i_vec_b[i]));
        end    
      end  
      `VEC_GT: begin
        for (int i = 0; i < VEC_SIZE; i++) begin
          o_mask[i] <= (i_mask[i] && $signed(i_vec_a[i]) > $signed(i_vec_b[i]));
        end
      end      
      `VEC_GE: begin
        for (int i = 0; i < VEC_SIZE; i++) begin
          o_mask[i] <= (i_mask[i] && $signed(i_vec_a[i]) >= $signed(i_vec_b[i]));
        end
      end
      default:
        o_mask <= 0;   
    endcase
  end

endmodule