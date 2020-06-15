`include "common.svh"

module alu
  (
   input [31:0]     i_operand_1,
   input [31:0]     i_operand_2,
   input [31:0]     i_operand_3,
   input [3:0]      i_operation,
   output reg [31:0] o_result
  );

   always_comb begin
      case(i_operation)
        `ALU_ADD:  o_result = i_operand_1 + i_operand_2 + i_operand_3;
        `ALU_SUB:  o_result = i_operand_1 - i_operand_2;
        `ALU_SLT:  o_result =  ($signed(i_operand_1) < $signed(i_operand_2)) ? 1 : 0;
        `ALU_SLTU: o_result =  (i_operand_1 < i_operand_2) ? 1 : 0;
        `ALU_OR:   o_result = i_operand_1 | i_operand_2;
        `ALU_XOR:  o_result = i_operand_1 ^ i_operand_2;
        `ALU_AND:  o_result = i_operand_1 & i_operand_2;
        `ALU_SLL:  o_result = i_operand_1 << i_operand_2;
        `ALU_SRL:  o_result = i_operand_1 >> i_operand_2;
        `ALU_SRA:  o_result = $signed(i_operand_1) >>> i_operand_2;
        default: o_result = 0;
      endcase
   end
endmodule
