module alu
  (
   input [31:0]     i_operand_1,
   input [31:0]     i_operand_2,
   input [31:0]     i_operand_3,
   input [3:0]      i_operation,
   output reg [31:0] o_result
  );

   parameter
     ADD  = 4'h1,
     SUB  = 4'h2,
     SLT  = 4'h3,
     SLTU = 4'h4,
     OR   = 4'h5,
     XOR  = 4'h6,
     AND  = 4'h7,
     SLL  = 4'h8,
     SRL  = 4'h9,
     SRA  = 4'hA;

   always_comb begin
      case(i_operation)
        ADD:  o_result = i_operand_1 + i_operand_2 + i_operand_3;
        SUB:  o_result = i_operand_1 - i_operand_2;
        SLT:  o_result =  ($signed(i_operand_1) < $signed(i_operand_2)) ? 1 : 0;
        SLTU: o_result =  (i_operand_1 < i_operand_2) ? 1 : 0;
        OR:   o_result = i_operand_1 | i_operand_2;
        XOR:  o_result = i_operand_1 ^ i_operand_2;
        AND:  o_result = i_operand_1 & i_operand_2;
        SLL:  o_result = i_operand_1 << i_operand_2;
        SRL:  o_result = i_operand_1 >> i_operand_2;
        SRA:  o_result = $signed(i_operand_1) >>> i_operand_2;
        default: o_result = 0;
      endcase
   end
endmodule
