`include "vunit_defines.svh"
`include "../src/common.svh"

module execute_tb;
   localparam integer clk_period = 10;
   reg                clk = 0;
   reg                rst = 0;

   reg [`DATA_WIDTH-1:0]  data;
   wire [`WORD_WIDTH-1:0] addr;
   wire                   wr;
   wire [`DATA_WIDTH-1:0] wr_data;

   reg [`INST_WIDTH-1:0]  inst;

   wire [`WORD_WIDTH-1:0] pc;
   wire                   pc_change;
   wire [`WORD_WIDTH-1:0] new_pc;
   wire                   ready;

   wire [`WORD_WIDTH-1:0] X[0:31];

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
   end // always_comb

   /*
    * Instruction formats functions
    */
   function [31:0] R;
      input [6:0] opcode;
      input [2:0] funct3;
      input [6:0] funct7;
      input [4:0] rd;
      input [4:0] rs2;
      input [4:0] rs1;
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
      input [4:0]  rs2;
      input [11:0] imm;
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
   endfunction // ADDI

   task next_cycle();
      @(posedge clk);
      #1;
   endtask

   // Sets register value
   task SET(input [4:0] rd, input [31:0] value);
      inst <= LUI(rd, value[31:12]);
      next_cycle();
      inst <= ADDI(rd, 0, value[11:0]);
      next_cycle();
   endtask

   `TEST_SUITE begin
      `TEST_SUITE_SETUP begin
         rst <= 1;
         next_cycle();
         rst <= 0;
         `CHECK_EQUAL(ready, 1);
      end
      `TEST_CASE("SET_TASK") begin
         SET(2, -1);
         SET(6, 7);
         `CHECK_EQUAL(X[2], -1);
         `CHECK_EQUAL(X[6], 7);
      end
      `TEST_CASE("ADDI") begin
         // 0xAAA = -1366
         // ADDI x1, x0, -1366
         inst <= I(`OP_IMM, `ADDI, 1, 0, -1366);
         next_cycle();
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(X[1], -1366);
         inst <= I(`OP_IMM, `ADDI, 1, 0, 10);
         next_cycle();
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(X[1], 10);
      end
      `TEST_CASE("SB") begin
         `CHECK_EQUAL(0, 1, "TODO");
      end
      `TEST_CASE("SH") begin
         `CHECK_EQUAL(0, 1, "TODO");
      end
      `TEST_CASE("SW") begin
         `CHECK_EQUAL(0, 1, "TODO");
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
                .o_new_pc(new_pc),
                .o_ready(ready),

                .o_X(X)
                );
endmodule
