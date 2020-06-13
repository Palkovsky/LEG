`ifndef FUNCS
`define FUNCS

`include "../src/common.svh"

/*
 * Instruction formats functions
 */
function [31:0] R;
   input [6:0] opcode;
   input [2:0] funct3;
   input [6:0] funct7;
   input [4:0] rd;
   input [4:0] rs1;
   input [4:0] rs2;
   R = { funct7, rs2, rs1, funct3, rd, opcode };
endfunction
function [31:0] I;
   input [6:0] opcode;
   input [2:0] funct3;
   input [4:0] rd;
   input [4:0] rs1;
   input [11:0] imm;
   I = { imm, rs1, funct3, rd, opcode };
endfunction
function [31:0] S;
   input [6:0]  opcode;
   input [2:0]  funct3;
   input [4:0]  rs1;
   input [11:0] imm;
   input [4:0]  rs2;
   S = { imm[11:5], rs2, rs1, funct3, imm[4:0], opcode };
endfunction
function [31:0] B;
   input [6:0]  opcode;
   input [2:0]  funct3;
   input [4:0]  rs1;
   input [4:0]  rs2;
   input [11:0] imm;
   B = { imm[11], imm[9:4], rs2, rs1, funct3, imm[3:0], imm[10], opcode };
endfunction
function [31:0] U;
   input [6:0]  opcode;
   input [4:0]  rd;
   input [19:0] imm;
   U = { imm, rd, opcode };
endfunction
function [31:0] J;
   input [6:0]  opcode;
   input [4:0]  rd;
   input [19:0] imm;
   J = { imm[19], imm[9:0], imm[10], imm[18:11], rd, opcode };
endfunction

/*
 * Specific instructions functions
 */
function [31:0] LUI;
   input [4:0]  rd;
   input [19:0] imm;
   LUI = U(`LUI, rd, imm);
endfunction
function [31:0] BRANCH;
   input [4:0]  rs1;
   input string ty;
   input [4:0]  rs2;
   input [11:0] imm;
   case (ty)
     "==": BRANCH = B(`BRANCH, `BEQ, rs1, rs2, imm);
     "!=": BRANCH = B(`BRANCH, `BNE, rs1, rs2, imm);
     "<<": BRANCH = B(`BRANCH, `BLT, rs1, rs2, imm);
     "<":  BRANCH = B(`BRANCH, `BLTU, rs1, rs2, imm);
     ">>": BRANCH = B(`BRANCH, `BGE, rs1, rs2, imm);
     ">":  BRANCH = B(`BRANCH, `BGEU, rs1, rs2, imm);
   endcase
endfunction
function [31:0] IMM_OP;
   input [4:0]  rd;
   input [4:0]  rs1;
   input string ty;
   input [11:0] imm;
   case (ty)
     "+":     IMM_OP = I(`OP_IMM, `ADDI, rd, rs1, imm);
     "SLTI":  IMM_OP = I(`OP_IMM, `SLTI, rd, rs1, imm);
     "SLTIU": IMM_OP = I(`OP_IMM, `SLTIU,  rd, rs1, imm);
     "&":     IMM_OP = I(`OP_IMM, `ANDI, rd, rs1, imm);
     "|":     IMM_OP = I(`OP_IMM, `ORI, rd, rs1, imm);
     "^":     IMM_OP = I(`OP_IMM, `XORI, rd, rs1, imm);
     "<<":    IMM_OP = I(`OP_IMM, `SLLI, rd, rs1, {7'b0, imm[4:0]});
     ">>":    IMM_OP = I(`OP_IMM, `SRLI, rd, rs1, {7'b0, imm[4:0]});
     ">>>":   IMM_OP = I(`OP_IMM, `SRAI, rd, rs1, {2'b01, 5'b0, imm[4:0]});
   endcase
endfunction
function [31:0] REG_OP;
   input [4:0]  rd;
   input [4:0]  rs1;
   input string ty;
   input [4:0]  rs2;
   case (ty)
     "+": REG_OP    = R(`OP_REG, `ADD, 0, rd, rs1, rs2);
     "-": REG_OP    = R(`OP_REG, `SUB, {2'b01, 5'b0}, rd, rs1, rs2);
     "|": REG_OP    = R(`OP_REG, `OR, 0, rd, rs1, rs2);
     "^": REG_OP    = R(`OP_REG, `XOR, 0, rd, rs1, rs2);
     "&": REG_OP    = R(`OP_REG, `AND, 0, rd, rs1, rs2);
     "SLT": REG_OP  = R(`OP_REG, `SLT, 0, rd, rs1, rs2);
     "SLTU": REG_OP = R(`OP_REG, `SLTU, 0, rd, rs1, rs2);
     "<<": REG_OP   = R(`OP_REG, `SLL, 0, rd, rs1, rs2);
     ">>": REG_OP   = R(`OP_REG, `SRL, 0, rd, rs1, rs2);
     ">>>": REG_OP  = R(`OP_REG, `SRA, {2'b01, 5'b0}, rd, rs1, rs2);
   endcase
endfunction
`endif
