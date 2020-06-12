`include "vunit_defines.svh"
`include "../src/common.svh"

module execute_tb;
   localparam integer clk_period = 10;
   reg                clk = 0;
   reg                rst = 0;

   wire               wr;
   wire [31:0]        addr;
   reg [`DATA_WIDTH-1:0] data;
   wire [`DATA_WIDTH-1:0] wr_data;

   reg [31:0]  inst;

   reg [31:0]  pc;
   wire        pc_change;
   wire [31:0] pc_new;
   wire        ready;

   wire [31:0] X[0:31];

   // Simulate memory.
   always_comb begin
      case (addr)
        0: data = 'hAA;
        1: data = 'hBB;
        2: data = 'hCC;
        3: data = 'hDD;
        4: data = 'h44;
        5: data = 'h55;
        default: data = 0;
      endcase
   end

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
   function [31:0] ADDI;
      input [4:0]  rd;
      input [4:0]  rs1;
      input [19:0] imm;
      ADDI = I(`OP_IMM, `ADDI, rd, rs1, imm);
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
        "<<": REG_OP  = R(`OP_REG, `SLL, 0, rd, rs1, rs2);
        ">>": REG_OP  = R(`OP_REG, `SRL, 0, rd, rs1, rs2);
        ">>>": REG_OP  = R(`OP_REG, `SRA, {2'b01, 5'b0}, rd, rs1, rs2);
      endcase
   endfunction

   task next_cycle();
      @(posedge clk);
      #1;
   endtask

   // Sets register value
   task SETREG(input [4:0] rd, input [31:0] value);
      inst <= LUI(rd, value[31:12]);
      next_cycle();
      inst <= ADDI(rd, rd, value[11:0]);
      next_cycle();
   endtask

   `TEST_SUITE begin
      `TEST_SUITE_SETUP begin
         rst <= 1;
         next_cycle();
         rst <= 0;
         `CHECK_EQUAL(ready, 1);
      end
      `TEST_CASE("SETREG_TASK") begin
         SETREG(2, 'hFFFFFFFF);
         SETREG(6, 7);
         SETREG(7, 'h11223344);
         `CHECK_EQUAL(X[7], 'h11223344);
         `CHECK_EQUAL(X[2], 'hFFFFFFFF);
         `CHECK_EQUAL(X[6], 7);
      end
      `TEST_CASE("ADD") begin
         // ADD x3, x1, x2
         SETREG(1, 500);
         SETREG(2, 300);
         inst <= REG_OP(3, 1, "+", 2);
         next_cycle();
         `CHECK_EQUAL(X[3], 800);
         // Test overflow
         SETREG(1, 'hFFFFFFFE);
         SETREG(2, 2);
         inst <= REG_OP(3, 1, "+", 2);
         next_cycle();
         `CHECK_EQUAL(X[3], 0);
      end
      `TEST_CASE("SUB") begin
         // SUB x3, x1, x2
         SETREG(1, 500);
         SETREG(2, 300);
         inst <= REG_OP(3, 1, "-", 2);
         next_cycle();
         `CHECK_EQUAL(X[3], 200);
         // Test overflow
         SETREG(1, 0);
         SETREG(2, 2);
         inst <= REG_OP(3, 1, "-", 2);
         next_cycle();
         `CHECK_EQUAL(X[3], 'hFFFFFFFE);
      end
      `TEST_CASE("SLT") begin
         SETREG(1, 3);
         SETREG(2, 4);
         inst <= REG_OP(3, 1, "SLT", 2);
         next_cycle();
         `CHECK_EQUAL(X[3], 1);

         next_cycle();
         inst <= REG_OP(3, 2, "SLT", 1);
         `CHECK_EQUAL(X[3], 1);

         // Signed boundary
         SETREG(1, 'h80000000);
         SETREG(2, 'h7FFFFFFF);
         inst <= REG_OP(3, 1, "SLT", 2);
         next_cycle();
         `CHECK_EQUAL(X[3], 1);
      end
      `TEST_CASE("SLTU") begin
         SETREG(1, 3);
         SETREG(2, 4);
         inst <= REG_OP(3, 1, "SLTU", 2);
         next_cycle();
         `CHECK_EQUAL(X[3], 1);

         next_cycle();
         inst <= REG_OP(3, 2, "SLTU", 1);
         `CHECK_EQUAL(X[3], 1);

         // Signed boundary
         SETREG(1, 'h80000000);
         SETREG(2, 'h7FFFFFFF);
         inst <= REG_OP(3, 1, "SLTU", 2);
         next_cycle();
         `CHECK_EQUAL(X[3], 0);
      end
      `TEST_CASE("SLL") begin
         SETREG(1, 'hFFFFFFFF);
         SETREG(2, 4);
         inst <= REG_OP(3, 1, "<<", 2);
         next_cycle();
         `CHECK_EQUAL(X[3], 'hFFFFFFF0);

         inst <= REG_OP(3, 3, "<<", 2);
         next_cycle();
         `CHECK_EQUAL(X[3], 'hFFFFFF00);
      end
      `TEST_CASE("SRL") begin
         SETREG(1, 'hFFFFFFFF);
         SETREG(2, 4);
         inst <= REG_OP(3, 1, ">>", 2);
         next_cycle();
         `CHECK_EQUAL(X[3], 'h0FFFFFFF);

         inst <= REG_OP(3, 3, ">>", 2);
         next_cycle();
         `CHECK_EQUAL(X[3], 'h00FFFFFF);
      end
      `TEST_CASE("SRA") begin
         SETREG(1, 'hFFFFFFFF);
         SETREG(2, 4);
         inst <= REG_OP(3, 1, ">>>", 2);
         next_cycle();
         `CHECK_EQUAL(X[3], 'hFFFFFFFF);

         SETREG(1, 'h0FFFFFFF);
         SETREG(2, 4);
         inst <= REG_OP(3, 1, ">>>", 2);
         next_cycle();
         `CHECK_EQUAL(X[3], 'h00FFFFFF);
      end
      `TEST_CASE("ADDI") begin
         // ADDI x1, x0, -500
         inst <= I(`OP_IMM, `ADDI, 1, 0, -500);
         next_cycle();
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(X[1], 4096-500);
         inst <= I(`OP_IMM, `ADDI, 1, 0, 10);
         next_cycle();
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(X[1], 10);
      end
      `TEST_CASE("BEQ") begin
         SETREG(2, 1);
         SETREG(6, 1);
         inst <= BRANCH(2, "==", 6, 8);
         next_cycle();
         `CHECK_EQUAL(pc_change, 1);
         `CHECK_EQUAL(pc_new, pc + 16);

         SETREG(6, 2);
         inst <= BRANCH(2, "==", 6, 8);
         next_cycle();
         `CHECK_EQUAL(pc_change, 0);
      end
      `TEST_CASE("BNE") begin
         SETREG(2, 1);
         SETREG(6, 1);
         inst <= BRANCH(2, "!=", 6, 8);
         next_cycle();
         `CHECK_EQUAL(pc_change, 0);

         SETREG(6, 2);
         inst <= BRANCH(2, "!=", 6, 8);
         next_cycle();
         `CHECK_EQUAL(pc_change, 1);
         `CHECK_EQUAL(pc_new, pc + 16);
      end
      `TEST_CASE("BLT") begin
         SETREG(2, 1);
         SETREG(6, 1);
         inst <= BRANCH(2, "<<", 6, 8);
         next_cycle();
         `CHECK_EQUAL(pc_change, 0);

         SETREG(6, 2);
         inst <= BRANCH(2, "<<", 6, 8);
         next_cycle();
         `CHECK_EQUAL(pc_change, 1);
         `CHECK_EQUAL(pc_new, pc + 16);

         // Signed boundary
         SETREG(2, 'h80000000);
         SETREG(6, 'h7FFFFFFF);
         inst <= BRANCH(2, "<<", 6, 8);
         next_cycle();
         `CHECK_EQUAL(pc_change, 1);
         `CHECK_EQUAL(pc_new, pc + 16);
      end
      `TEST_CASE("BLTU") begin
         SETREG(2, 1);
         SETREG(6, 1);
         inst <= BRANCH(2, "<", 6, 8);
         next_cycle();
         `CHECK_EQUAL(pc_change, 0);

         SETREG(6, 2);
         inst <= BRANCH(2, "<", 6, 8);
         next_cycle();
         `CHECK_EQUAL(pc_change, 1);
         `CHECK_EQUAL(pc_new, pc + 16);

         // Signed boundary
         SETREG(2, 'h80000000);
         SETREG(6, 'h7FFFFFFF);
         inst <= BRANCH(2, "<", 6, 8);
         next_cycle();
         `CHECK_EQUAL(pc_change, 0);
      end
      `TEST_CASE("BGE") begin
         SETREG(2, 1);
         SETREG(6, 1);
         inst <= BRANCH(2, ">>", 6, 8);
         next_cycle();
         `CHECK_EQUAL(pc_change, 0);

         SETREG(2, 2);
         inst <= BRANCH(2, ">>", 6, 8);
         next_cycle();
         `CHECK_EQUAL(pc_change, 1);
         `CHECK_EQUAL(pc_new, pc + 16);

         // Signed boundary
         SETREG(2, 'h80000000);
         SETREG(6, 'h7FFFFFFF);
         inst <= BRANCH(2, ">>", 6, 8);
         next_cycle();
         `CHECK_EQUAL(pc_change, 0);
      end
      `TEST_CASE("BGEU") begin
         SETREG(2, 1);
         SETREG(6, 1);
         inst <= BRANCH(2, ">", 6, 8);
         next_cycle();
         `CHECK_EQUAL(pc_change, 0);

         SETREG(2, 2);
         inst <= BRANCH(2, ">", 6, 8);
         next_cycle();
         `CHECK_EQUAL(pc_change, 1);
         `CHECK_EQUAL(pc_new, pc + 16);

         // Signed boundary
         SETREG(2, 'h80000000);
         SETREG(6, 'h7FFFFFFF);
         inst <= BRANCH(2, ">", 6, 8);
         next_cycle();
         `CHECK_EQUAL(pc_change, 1);
         `CHECK_EQUAL(pc_new, pc + 16);
      end
      `TEST_CASE("JAL") begin
         // JAL x1, +4
         pc <= 1234;
         inst <= J(`JAL, 1, 2);
         `CHECK_EQUAL(pc_change, 0);
         next_cycle();
         `CHECK_EQUAL(X[1], pc+4);
         `CHECK_EQUAL(pc_change, 1);
         `CHECK_EQUAL(pc_new, pc + (2<<1));
         `CHECK_EQUAL(ready, 1);
         pc <= pc_new;

         // JAL x2, -1MB
         inst <= J(`JAL, 2, {1'b1, 19'b0});
         next_cycle();
         `CHECK_EQUAL(X[2], pc+4);
         `CHECK_EQUAL(pc_change, 1);
         `CHECK_EQUAL(pc_new, pc + {1'b1, 20'b0});
         `CHECK_EQUAL(ready, 1);
         pc <= pc_new;

         // JAL x3, +200
         inst <= J(`JAL, 3, 100);
         next_cycle();
         `CHECK_EQUAL(X[3], pc+4);
         `CHECK_EQUAL(pc_change, 1);
         `CHECK_EQUAL(pc_new, pc + 200);
         `CHECK_EQUAL(ready, 1);
      end
      `TEST_CASE("SB") begin
         // SB [x0+0xABC], x15
         SETREG(15, 'h11223344);
         inst <= S(`STORE, `SB, 0, 'hABC, 15);
         `CHECK_EQUAL(wr, 0);
         next_cycle();
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(wr, 1);
         `CHECK_EQUAL(addr, 'hABC);
         `CHECK_EQUAL(wr_data, 'h44);

         // SB [x1+0x100], x14
         SETREG(1, 'h800);
         SETREG(14, 'h44332211);
         `CHECK_EQUAL(wr, 0);
         inst <= S(`STORE, `SB, 1, 'h100, 14);
         next_cycle();
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(wr, 1);
         `CHECK_EQUAL(addr, 'h900);
         `CHECK_EQUAL(wr_data, 'h11);
      end
      `TEST_CASE("SH") begin
         // SH [x0+0xABC], x15
         SETREG(15, 'h11223344);
         inst <= S(`STORE, `SH, 0, 'hABC, 15);
         `CHECK_EQUAL(wr, 0);
         #1
         `CHECK_EQUAL(wr, 1);
         `CHECK_EQUAL(addr, 'hABC);
         `CHECK_EQUAL(wr_data, 'h33);
         next_cycle(); // <- On this edge BRAM should write 1st byte
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(wr, 1);
         `CHECK_EQUAL(addr, 'hABD);
         `CHECK_EQUAL(wr_data, 'h44);
         next_cycle(); // <- On this edge BRAM should write 2nd byte
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(wr, 1);
         inst <= 0;
         next_cycle();
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(wr, 0);
      end
      `TEST_CASE("SW") begin
         // SW [x0+0xABC], x15
         SETREG(15, 'h11223344);
         inst <= S(`STORE, `SW, 0, 'hABC, 15);
         `CHECK_EQUAL(wr, 0);
         #1
         `CHECK_EQUAL(wr, 1);
         `CHECK_EQUAL(addr, 'hABC);
         `CHECK_EQUAL(wr_data, 'h11);
         next_cycle(); // <- On this edge BRAM should write 1st byte
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(wr, 1);
         `CHECK_EQUAL(addr, 'hABD);
         `CHECK_EQUAL(wr_data, 'h22);
         next_cycle(); // <- On this edge BRAM should write 2nd byte
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(wr, 1);
         `CHECK_EQUAL(addr, 'hABE);
         `CHECK_EQUAL(wr_data, 'h33);
         next_cycle(); // <- On this edge BRAM should write 3rd byte
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(wr, 1);
         `CHECK_EQUAL(addr, 'hABF);
         `CHECK_EQUAL(wr_data, 'h44);
         next_cycle(); // <- On this edge BRAM should write 4th byte
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(wr, 1);
         inst <= 0;
         next_cycle();
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(wr, 0);
      end // always
      `TEST_CASE("LB positive") begin
         // LB x8, [x0 + 4]
         inst <= I(`LOAD, `LB, 8, 0, 4);
         `CHECK_EQUAL(wr_data, 0);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(X[8], 'h00);
         next_cycle();
         `CHECK_EQUAL(wr_data, 0);
         `CHECK_EQUAL(addr, 4);
         `CHECK_EQUAL(X[8], 'h00000044);
         `CHECK_EQUAL(ready, 1);
      end
      `TEST_CASE("LB negative") begin
         // LB x8, [x0 + 2]
         inst = I(`LOAD, `LB, 8, 0, 2);
         `CHECK_EQUAL(wr_data, 0);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(X[8], 'h00);
         #1
         `CHECK_EQUAL(addr, 2);
         next_cycle();
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(wr_data, 0);
         `CHECK_EQUAL(X[8], 'hFFFFFFCC);
      end
      `TEST_CASE("LBU") begin
         // LBU x1, [x0 + 1]
         inst <= I(`LOAD, `LBU, 1, 0, 1);
         `CHECK_EQUAL(wr_data, 0);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(X[1], 'h00);
         #1
         `CHECK_EQUAL(addr, 1);
         next_cycle();
         `CHECK_EQUAL(wr_data, 0);
         `CHECK_EQUAL(X[1], 'hBB);
      end
      `TEST_CASE("LH positive") begin
         // LH x2, [x0 + 4]
         inst <= I(`LOAD, `LH, 2, 0, 4);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(X[2], 'h00);
         #1
         `CHECK_EQUAL(addr, 4);
         next_cycle();
         `CHECK_EQUAL(X[2], 'h4400);
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(addr, 5);
         next_cycle();
         `CHECK_EQUAL(X[2], 'h00004455);
         `CHECK_EQUAL(ready, 1);
      end // always
      `TEST_CASE("LH negative") begin
         // LH x2, [x0 + 0]
         inst <= I(`LOAD, `LH, 2, 0, 0);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(X[2], 'h00);
         #1
         `CHECK_EQUAL(addr, 0);
         next_cycle();
         `CHECK_EQUAL(X[2], 'hAA00);
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(addr, 1);
         next_cycle();
         `CHECK_EQUAL(X[2], 'hFFFFAABB);
         `CHECK_EQUAL(ready, 1);
      end
      `TEST_CASE("LHU") begin
         // LHU x1, [x0 + 3]
         inst <= I(`LOAD, `LHU, 1, 0, 3);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(X[1], 'h00);
         #1
         `CHECK_EQUAL(addr, 3);
         next_cycle();
         `CHECK_EQUAL(X[1], 'hDD00);
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(addr, 4);
         next_cycle();
         `CHECK_EQUAL(X[1], 'hDD44);
         `CHECK_EQUAL(ready, 1);
      end
      `TEST_CASE("LW") begin
         // LW x15, [x0+1]
         inst <= I(`LOAD, `LW, 15, 0, 1);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(X[15], 'h00);
         #1
         `CHECK_EQUAL(addr, 1);
         next_cycle();
         `CHECK_EQUAL(X[15], 'hBB000000);
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(addr, 2);
         next_cycle();
         `CHECK_EQUAL(X[15], 'hBBCC0000);
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(addr, 3);
         next_cycle();
         `CHECK_EQUAL(X[15], 'hBBCCDD00);
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(addr, 4);
         next_cycle();
         `CHECK_EQUAL(X[15], 'hBBCCDD44);
         `CHECK_EQUAL(ready, 1);
      end
   end;
   `WATCHDOG(10ms);

   always begin
      #(clk_period/2 * 1ns);
      clk = !clk;
   end

   execute execute (
	              .i_clk(clk),
	              .i_rst(rst),

                .i_inst(inst),

                .i_mem_data(data),
                .o_mem_addr(addr),
                .o_mem_write(wr),
                .o_mem_data(wr_data),

                .i_pc(pc),
                .o_pc_change(pc_change),
                .o_new_pc(pc_new),
                .o_ready(ready),

                .o_X(X)
                );
endmodule
