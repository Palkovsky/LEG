`include "vunit_defines.svh"
`include "funcs.svh"

module execute_tb;
   localparam integer clk_period = 10;
   reg                clk = 0;
   reg                rst = 0;

   wire               wr;
   wire [31:0]        addr;
   reg [`DATA_WIDTH-1:0] data_sim;

   reg [`DATA_WIDTH-1:0] rd_data;
   reg                   rd_valid = 0;
   wire                  rd_ready;

   wire [`DATA_WIDTH-1:0] wr_data;
   wire                   wr_valid;
   reg                    wr_ready;
   wire [2:0]             wr_width;

   reg [31:0]  inst;

   reg [31:0]  pc;
   wire        pc_change;
   wire [31:0] pc_new;
   wire        finished;
   wire        invalid_inst;

   // Simulate memory.
   always_comb begin
      static logic [`DATA_WIDTH-1:0] temp = 0;
      case (addr[31:2])
        0: temp = 32'hDDCCBBAA;
        1: temp = 32'hFFEE5544;
        2: temp = 32'hFFEEDDCC;
        4: temp = 32'h44332211;
        default: temp = 0;
      endcase
      data_sim = temp >> (addr[1:0] * 8);
   end
   assign wr_ready = 1;
   always @(posedge clk) begin
      // Read
      rd_valid <= 0;
      if (rd_ready) begin
         rd_data <= data_sim;
         rd_valid <= 1;
      end
   end

   task next_cycle();
      @(posedge clk);
      #1;
   endtask

   // Sets register value
   task SETREG(input [4:0] rd, input [31:0] value);
      if (value[11]) begin
         value[31:12] = value[31:12] + 1;
      end
      inst <= LUI(rd, value[31:12]);
      next_cycle();
      inst <= IMM_OP(rd, rd, "+", value[11:0]);
      next_cycle();
   endtask

   `TEST_SUITE begin
      `TEST_SUITE_SETUP begin
         rst <= 1;
         next_cycle();
         rst <= 0;
         `CHECK_EQUAL(finished, 1);
      end
      `TEST_CASE("SETREG_TASK") begin
         // vunit: .execute
         SETREG(2, 'hFFFFFFFF);
         SETREG(6, 7);
         SETREG(7, 'h11223344);
         `CHECK_EQUAL(execute.X[7] & 'hFFF, 'h344);
         `CHECK_EQUAL(execute.X[7] & 'hFFFFF000, 'h11223000);
         `CHECK_EQUAL(execute.X[7], 'h11223344);
         `CHECK_EQUAL(execute.X[2], 'hFFFFFFFF);
         `CHECK_EQUAL(execute.X[6], 7);
      end
      `TEST_CASE("Invalid instruction") begin
         // vunit: .execute
         `CHECK_EQUAL(invalid_inst, 1);
         inst <= { 25'b0, 7'b1};
         next_cycle();
         `CHECK_EQUAL(invalid_inst, 1);

         inst <= IMM_OP(1, 0, "+", 1);
         #1
         `CHECK_EQUAL(invalid_inst, 0);
         next_cycle();
         `CHECK_EQUAL(invalid_inst, 0);
      end
      `TEST_CASE("ADDI") begin
         // vunit: .execute
         // ADDI x1, x0, -500
         inst <= IMM_OP(1, 0, "+", -500);
         next_cycle();
         `CHECK_EQUAL(execute.X[1], 'hFFFFFE0C);

         inst <= IMM_OP(1, 0, "+", 10);
         next_cycle();
         `CHECK_EQUAL(execute.X[1], 10);

         SETREG(1, 'hFFFFFFFF);
         inst <= IMM_OP(2, 1, "+", 1);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 0);
      end
      `TEST_CASE("SLTI") begin
         // vunit: .execute
         SETREG(1, 22);
         inst <= IMM_OP(2, 1, "SLTI", 33);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 1);

         inst <= IMM_OP(2, 1, "SLTI", 11);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 0);

         // Signed boundary
         SETREG(1, 'h7FF);
         inst <= IMM_OP(2, 1, "SLTI", 'h800);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 0);
      end
      `TEST_CASE("SLTIU") begin
         // vunit: .execute
         SETREG(1, 22);
         inst <= IMM_OP(2, 1, "SLTIU", 33);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 1);

         inst <= IMM_OP(2, 1, "SLTIU", 11);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 0);

         // Signed boundary
         SETREG(1, 'h7FF);
         inst <= IMM_OP(2, 1, "SLTIU", 'h800);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 1);
      end
      `TEST_CASE("SLLI") begin
         // vunit: .execute
         SETREG(1, 'hFFFFFFFF);
         inst <= IMM_OP(2, 1, "<<", 4);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 'hFFFFFFF0);

         inst <= IMM_OP(2, 2, "<<", 4);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 'hFFFFFF00);

         inst <= IMM_OP(2, 2, "<<", 20);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 'hF0000000);
      end
      `TEST_CASE("SRLI") begin
         // vunit: .execute
         SETREG(1, 'hFFFFFFFF);
         inst <= IMM_OP(2, 1, ">>", 4);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 'hFFFFFFF);

         inst <= IMM_OP(2, 2, ">>", 4);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 'hFFFFFF);

         inst <= IMM_OP(2, 2, ">>", 20);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 'hF);
      end
      `TEST_CASE("SRAI") begin
         // vunit: .execuet
         SETREG(1, 'hFFFFFFFF);
         inst <= IMM_OP(2, 1, ">>>", 4);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 'hFFFFFFFF);

         SETREG(1, 'h0FFFFFFF);
         inst <= IMM_OP(2, 1, ">>>", 4);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 'h00FFFFFF);
      end
      `TEST_CASE("AUIPC") begin
         pc <= 'h2222;
         inst <= U(`AUIPC, 10, 'h80000);
         next_cycle();
         `CHECK_EQUAL(execute.X[10], { 20'h80002, 12'h222 });
      end
      `TEST_CASE("ADD") begin
         // vunit: .execute
         // ADD x3, x1, x2
         SETREG(1, 500);
         SETREG(2, 300);
         inst <= REG_OP(3, 1, "+", 2);
         next_cycle();
         `CHECK_EQUAL(execute.X[3], 800);
         // Test overflow
         SETREG(1, 'hFFFFFFFE);
         SETREG(2, 2);
         inst <= REG_OP(3, 1, "+", 2);
         next_cycle();
         `CHECK_EQUAL(execute.X[3], 0);
      end
      `TEST_CASE("SUB") begin
         // vunit: .execute
         // SUB x3, x1, x2
         SETREG(1, 500);
         SETREG(2, 300);
         inst <= REG_OP(3, 1, "-", 2);
         next_cycle();
         `CHECK_EQUAL(execute.X[3], 200);
         // Test overflow
         SETREG(1, 0);
         SETREG(2, 2);
         inst <= REG_OP(3, 1, "-", 2);
         next_cycle();
         `CHECK_EQUAL(execute.X[3], 'hFFFFFFFE);
      end
      `TEST_CASE("SLT") begin
         // vunit: .execute
         SETREG(1, 3);
         SETREG(2, 4);
         inst <= REG_OP(3, 1, "SLT", 2);
         next_cycle();
         `CHECK_EQUAL(execute.X[3], 1);

         next_cycle();
         inst <= REG_OP(3, 2, "SLT", 1);
         `CHECK_EQUAL(execute.X[3], 1);

         // Signed boundary
         SETREG(1, 'h80000000);
         SETREG(2, 'h7FFFFFFF);
         inst <= REG_OP(3, 1, "SLT", 2);
         next_cycle();
         `CHECK_EQUAL(execute.X[3], 1);
      end
      `TEST_CASE("SLTU") begin
         // vunit: .execute
         SETREG(1, 3);
         SETREG(2, 4);
         inst <= REG_OP(3, 1, "SLTU", 2);
         next_cycle();
         `CHECK_EQUAL(execute.X[3], 1);

         next_cycle();
         inst <= REG_OP(3, 2, "SLTU", 1);
         `CHECK_EQUAL(execute.X[3], 1);

         // Signed boundary
         SETREG(1, 'h80000000);
         SETREG(2, 'h7FFFFFFF);
         inst <= REG_OP(3, 1, "SLTU", 2);
         next_cycle();
         `CHECK_EQUAL(execute.X[3], 0);
      end
      `TEST_CASE("SLL") begin
         // vunit: .execute
         SETREG(1, 'hFFFFFFFF);
         SETREG(2, 4);
         inst <= REG_OP(3, 1, "<<", 2);
         next_cycle();
         `CHECK_EQUAL(execute.X[3], 'hFFFFFFF0);

         inst <= REG_OP(3, 3, "<<", 2);
         next_cycle();
         `CHECK_EQUAL(execute.X[3], 'hFFFFFF00);
      end
      `TEST_CASE("SRL") begin
         // vunit: .execute
         SETREG(1, 'hFFFFFFFF);
         SETREG(2, 4);
         inst <= REG_OP(3, 1, ">>", 2);
         next_cycle();
         `CHECK_EQUAL(execute.X[3], 'h0FFFFFFF);

         inst <= REG_OP(3, 3, ">>", 2);
         next_cycle();
         `CHECK_EQUAL(execute.X[3], 'h00FFFFFF);
      end
      `TEST_CASE("SRA") begin
         // vunit: .execute
         SETREG(1, 'hFFFFFFFF);
         SETREG(2, 4);
         inst <= REG_OP(3, 1, ">>>", 2);
         next_cycle();
         `CHECK_EQUAL(execute.X[3], 'hFFFFFFFF);

         SETREG(1, 'h0FFFFFFF);
         SETREG(2, 4);
         inst <= REG_OP(3, 1, ">>>", 2);
         next_cycle();
         `CHECK_EQUAL(execute.X[3], 'h00FFFFFF);
      end
      `TEST_CASE("BEQ") begin
         // vunit: .execute
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
         // vunit: .execute
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
         // vunit: .execute
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
         // vunit: .execute
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
         // vunit: .execute
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
         // vunit: .execute
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
         // vunit: .execute
         // JAL x1, +4
         pc <= 1234;
         inst <= J(`JAL, 1, 2);
         `CHECK_EQUAL(pc_change, 0);
         next_cycle();
         `CHECK_EQUAL(execute.X[1], pc+4);
         `CHECK_EQUAL(pc_change, 1);
         `CHECK_EQUAL(pc_new, pc + (2<<1));
         `CHECK_EQUAL(finished, 1);
         pc <= pc_new;

         // JAL x2, -1MB
         inst <= J(`JAL, 2, {1'b1, 19'b0});
         next_cycle();
         `CHECK_EQUAL(execute.X[2], pc+4);
         `CHECK_EQUAL(pc_change, 1);
         `CHECK_EQUAL(pc_new, pc + { 12'hFFF, 20'b0});
         `CHECK_EQUAL(finished, 1);
         pc <= pc_new;

         // JAL x3, +200
         inst <= J(`JAL, 3, 100);
         next_cycle();
         `CHECK_EQUAL(execute.X[3], pc+4);
         `CHECK_EQUAL(pc_change, 1);
         `CHECK_EQUAL(pc_new, pc + 200);
         `CHECK_EQUAL(finished, 1);
      end
      `TEST_CASE("JALR") begin
         // vunit: .execute
         SETREG(15, 'h100);
         inst <= I(`JALR, 0, 1, 15, 'h80);
         next_cycle();
         `CHECK_EQUAL(pc_change, 1);
         `CHECK_EQUAL(pc_new, 'h180);

         inst <= I(`JALR, 0, 1, 15, 'h81);
         next_cycle();
         `CHECK_EQUAL(pc_change, 1);
         `CHECK_EQUAL(pc_new, 'h180);
      end
      `TEST_CASE("SB") begin
         // vunit: .execute
         // vunit: .sb
         // SB [x0+0x7BC], x15
         SETREG(15, 'h11223344);
         inst <= S(`STORE, `SB, 0, 'h7BC, 15);
         `CHECK_EQUAL(wr_valid, 0);
         next_cycle();
         `CHECK_EQUAL(wr_valid, 1);
         `CHECK_EQUAL(wr_width, 1);
         `CHECK_EQUAL(addr, 'h7BC);
         `CHECK_EQUAL(wr_data, 'h11223344);
         `CHECK_EQUAL(finished, 1);

         // SB [x1+0x100], x14
         SETREG(1, 'h800);
         SETREG(14, 'h44332211);
         inst <= S(`STORE, `SB, 1, 'h100, 14);
         next_cycle();
         `CHECK_EQUAL(finished, 1);
         `CHECK_EQUAL(wr_width, 1);
         `CHECK_EQUAL(wr_valid, 1);
         `CHECK_EQUAL(addr, 'h900);
         `CHECK_EQUAL(wr_data, 'h44332211);
      end
      `TEST_CASE("SH") begin
         // vunit: .execute
         // vunit: .sh
         // SH [x0+0x7BC], x15
         SETREG(15, 'h11223344);
         inst <= S(`STORE, `SH, 0, 'h7BC, 15);
         `CHECK_EQUAL(wr_valid, 0);
         #1
         `CHECK_EQUAL(wr_valid, 1);
         `CHECK_EQUAL(wr_width, 2);
         `CHECK_EQUAL(addr, 'h7BC);
         `CHECK_EQUAL(wr_data, 32'h11223344);
         next_cycle();
         `CHECK_EQUAL(wr_valid, 1);
         `CHECK_EQUAL(finished, 1);
         `CHECK_EQUAL(addr, 'h7BC);
         `CHECK_EQUAL(wr_data, 32'h11223344);
         `CHECK_EQUAL(finished, 1);

         // Prepare next instruction
         inst <= 0;
         next_cycle(); // <- On this edge BRAM should write 2nd byte
         `CHECK_EQUAL(wr_valid, 0);
         `CHECK_EQUAL(finished, 1);
      end
      `TEST_CASE("SW") begin
         // vunit: .execute
         // vunit: .sw
         // SW [x0+0xABC], x15
         SETREG(15, 'h11223344);
         inst <= S(`STORE, `SW, 0, 'h7BC, 15);
         `CHECK_EQUAL(wr_valid, 0);
         #1
         `CHECK_EQUAL(wr_valid, 1);
         `CHECK_EQUAL(wr_width, 4);
         `CHECK_EQUAL(addr, 'h7BC);
         `CHECK_EQUAL(wr_data, 'h11223344);
         next_cycle();
         `CHECK_EQUAL(finished, 1);
         `CHECK_EQUAL(wr_valid, 1);
         `CHECK_EQUAL(wr_width, 4);
         `CHECK_EQUAL(addr, 'h7BC);
         `CHECK_EQUAL(wr_data, 'h11223344);

         //  Coz finished==1, prepare next instruction
         inst <= 0;
         next_cycle(); // <- On this edge BRAM should write 4th byte
         `CHECK_EQUAL(execute.i_inst, 0);
         `CHECK_EQUAL(execute.r_cycle, 0);
         `CHECK_EQUAL(finished, 1);
         `CHECK_EQUAL(wr_valid, 0);
      end // always
      `TEST_CASE("LB positive") begin
         // vunit: .execute
         // vunit: .lbpos
         // LB x8, [x0 + 4]
         inst <= I(`LOAD, `LB, 8, 0, 4);
         #1;
         `CHECK_EQUAL(wr_valid, 0);
         `CHECK_EQUAL(rd_ready, 1);
         `CHECK_EQUAL(rd_valid, 0);
         `CHECK_EQUAL(addr, 4);
         `CHECK_EQUAL(execute.X[8], 'h00);
         next_cycle(); // Data goes to BRAM buffer
         `CHECK_EQUAL(rd_ready, 1);
         `CHECK_EQUAL(rd_valid, 1);
         `CHECK_EQUAL(rd_data, 'hFFEE5544);
         `CHECK_EQUAL(addr, 4);
         `CHECK_EQUAL(finished, 1);
         `CHECK_EQUAL(execute.X[8], 'h00);
         next_cycle(); // Data goes from BRAM buffer to register
         `CHECK_EQUAL(rd_data, 32'hFFEE5544);
         `CHECK_EQUAL(rd_ready, 1);
         `CHECK_EQUAL(addr, 4);
         `CHECK_EQUAL(finished, 1);
         `CHECK_EQUAL(execute.X[8], 'h44);
      end
      `TEST_CASE("LB negative") begin
         // vunit: .execute
         // LB x8, [x0 + 0]
         // vunit: .lbneg
         inst = I(`LOAD, `LB, 8, 0, 0);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(execute.X[8], 'h00);
         #1
         `CHECK_EQUAL(rd_ready, 1);
         `CHECK_EQUAL(rd_valid, 0);
         `CHECK_EQUAL(addr, 0);
         next_cycle();
         `CHECK_EQUAL(rd_ready, 1);
         `CHECK_EQUAL(rd_valid, 1);
         `CHECK_EQUAL(execute.X[8], 0);
         next_cycle();
         `CHECK_EQUAL(execute.X[8], 'hFFFFFFAA);
      end
      `TEST_CASE("LB offset 1") begin
         // vunit: .execute
         // LB x8, [x0 + 1]
         // vunit: .lb1
         inst = I(`LOAD, `LB, 8, 0, 1);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(execute.X[8], 'h00);
         #1
         `CHECK_EQUAL(rd_ready, 1);
         `CHECK_EQUAL(rd_valid, 0);
         `CHECK_EQUAL(addr, 1);
         next_cycle();
         `CHECK_EQUAL(rd_ready, 1);
         `CHECK_EQUAL(rd_valid, 1);
         `CHECK_EQUAL(execute.X[8], 0);
         next_cycle();
         `CHECK_EQUAL(execute.X[8], 'hFFFFFFBB);
      end
      `TEST_CASE("LB offset 2") begin
         // vunit: .execute
         // LB x8, [x0 + 2]
         // vunit: .lb2
         inst = I(`LOAD, `LB, 8, 0, 2);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(execute.X[8], 'h00);
         #1
         `CHECK_EQUAL(rd_ready, 1);
         `CHECK_EQUAL(rd_valid, 0);
         `CHECK_EQUAL(addr, 2);
         next_cycle();
         `CHECK_EQUAL(rd_ready, 1);
         `CHECK_EQUAL(rd_valid, 1);
         `CHECK_EQUAL(execute.X[8], 0);
         next_cycle();
         `CHECK_EQUAL(execute.X[8], 'hFFFFFFCC);
      end
      `TEST_CASE("LB offset 3") begin
         // vunit: .execute
         // LB x8, [x0 + 3]
         // vunit: .lb3
         inst = I(`LOAD, `LB, 8, 0, 3);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(execute.X[8], 'h00);
         #1
         `CHECK_EQUAL(rd_ready, 1);
         `CHECK_EQUAL(rd_valid, 0);
         `CHECK_EQUAL(addr, 3);
         next_cycle();
         `CHECK_EQUAL(rd_ready, 1);
         `CHECK_EQUAL(rd_valid, 1);
         `CHECK_EQUAL(execute.X[8], 0);
         next_cycle();
         `CHECK_EQUAL(execute.X[8], 'hFFFFFFDD);
      end
      `TEST_CASE("LBU") begin
         // vunit: .execute
         // vunit: .lbu
         // LBU x1, [x0 + 0]
         inst <= I(`LOAD, `LBU, 1, 0, 0);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(execute.X[1], 'h00);
         #1
         `CHECK_EQUAL(addr, 0);
         next_cycle();
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(rd_data, 'hDDCCBBAA);
         `CHECK_EQUAL(execute.X[1], 'h00);
         next_cycle();
         `CHECK_EQUAL(execute.X[1], 'hAA);
      end
      `TEST_CASE("LBU offset 1") begin
         // vunit: .execute
         // LBU x8, [x0 + 1]
         // vunit: .lbu1
         inst = I(`LOAD, `LBU, 8, 0, 1);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(execute.X[8], 'h00);
         #1
         `CHECK_EQUAL(rd_ready, 1);
         `CHECK_EQUAL(rd_valid, 0);
         `CHECK_EQUAL(addr, 1);
         next_cycle();
         `CHECK_EQUAL(rd_ready, 1);
         `CHECK_EQUAL(rd_valid, 1);
         `CHECK_EQUAL(execute.X[8], 0);
         next_cycle();
         `CHECK_EQUAL(execute.X[8], 'h000000BB);
      end
      `TEST_CASE("LBU offset 2") begin
         // vunit: .execute
         // LBU x8, [x0 + 2]
         // vunit: .lbu2
         inst = I(`LOAD, `LBU, 8, 0, 2);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(execute.X[8], 'h00);
         #1
         `CHECK_EQUAL(rd_ready, 1);
         `CHECK_EQUAL(rd_valid, 0);
         `CHECK_EQUAL(addr, 2);
         next_cycle();
         `CHECK_EQUAL(rd_ready, 1);
         `CHECK_EQUAL(rd_valid, 1);
         `CHECK_EQUAL(execute.X[8], 0);
         next_cycle();
         `CHECK_EQUAL(execute.X[8], 'h000000CC);
      end
      `TEST_CASE("LBU offset 3") begin
         // vunit: .execute
         // LBU x8, [x0 + 3]
         // vunit: .lbu3
         inst = I(`LOAD, `LBU, 8, 0, 3);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(execute.X[8], 'h00);
         #1
         `CHECK_EQUAL(rd_ready, 1);
         `CHECK_EQUAL(rd_valid, 0);
         `CHECK_EQUAL(addr, 3);
         next_cycle();
         `CHECK_EQUAL(rd_ready, 1);
         `CHECK_EQUAL(rd_valid, 1);
         `CHECK_EQUAL(execute.X[8], 0);
         next_cycle();
         `CHECK_EQUAL(execute.X[8], 'h000000DD);
      end
      `TEST_CASE("LH positive") begin
         // vunit: .execute
         // vunit: .lhpos
         // LH x2, [x0 + 4]
         inst <= I(`LOAD, `LH, 2, 0, 4);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(execute.X[2], 'h00);
         #1
         `CHECK_EQUAL(addr, 4);
         next_cycle();
         `CHECK_EQUAL(rd_data, 'hFFEE5544);
         `CHECK_EQUAL(execute.X[2], 32'h0);
         `CHECK_EQUAL(finished, 1);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 32'h00005544);
         `CHECK_EQUAL(finished, 1);
      end
      `TEST_CASE("LH negative") begin
         // vunit: .execute
         // vunit: .lhneg
         // LH x2, [x0 + 8]
         inst <= I(`LOAD, `LH, 2, 0, 8);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(execute.X[2], 'h00);
         `CHECK_EQUAL(finished, 1);
         #1
         `CHECK_EQUAL(addr, 8);
         `CHECK_EQUAL(finished, 0);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 'h0000);
         `CHECK_EQUAL(rd_data, 32'hFFEEDDCC);
         `CHECK_EQUAL(finished, 1);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 32'hFFFFDDCC);
         `CHECK_EQUAL(finished, 1);
      end
      `TEST_CASE("LHU") begin
         // vunit: .execute
         // vunit: .lhu
         // LHU x1, [x0 + 8]
         inst <= I(`LOAD, `LHU, 1, 0, 8);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(execute.X[1], 'h00);
         #1
         `CHECK_EQUAL(addr, 8);
         next_cycle();
         `CHECK_EQUAL(execute.X[1], 0);
         `CHECK_EQUAL(finished, 1);
         next_cycle();
         `CHECK_EQUAL(finished, 1);
         `CHECK_EQUAL(execute.X[1], 32'h0000DDCC);
      end
      `TEST_CASE("LW") begin
         // vunit: .execute
         // vunit: .lw
         // LW x15, [x0+1]
         inst <= I(`LOAD, `LW, 15, 0, 16);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(execute.X[15], 'h00);
         #1
         `CHECK_EQUAL(addr, 16);
         next_cycle();
         `CHECK_EQUAL(rd_data, 'h44332211);
         `CHECK_EQUAL(execute.X[15], 'h00000000);
         `CHECK_EQUAL(addr, 16);
         `CHECK_EQUAL(finished, 1);
         next_cycle();
         `CHECK_EQUAL(rd_data, 'h44332211);
         `CHECK_EQUAL(execute.X[15], 'h44332211);
         `CHECK_EQUAL(finished, 1);
      end

      `TEST_CASE("DOTV") begin
         // vunit: .execute
         // vunit: .vec
         // DOTV x1, v0, v1
         inst <= R(`OP_VEC_R, 0, `VECR_DOTV, 1, 0, 1);
         // v0 = [1.0, ..., 1.0]
         execute.vec_ram.mem[0] <= 256'h0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800;
         // v1 = [0.0, 0.125, ..., 1.875]
         execute.vec_ram.mem[1] <= 256'h0000_0100_0200_0300_0400_0500_0600_0700_0800_0900_0a00_0b00_0c00_0d00_0e00_0f00;
         `CHECK_EQUAL(execute.X[1], 'h0000);
         next_cycle();
         `CHECK_EQUAL(execute.X[1], 15 * 2048);
         `CHECK_EQUAL(finished, 1);
      end

      `TEST_CASE("MULV") begin
         // vunit: .execute
         // vunit: .vec
         // MULV v0, v0, v1
         inst <= R(`OP_VEC_R, 0, `VECR_MULV, 0, 0, 1);
         // v0 = [1.0, ..., 1.0]
         execute.vec_ram.mem[0] <= 256'h0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800;
         // v1 = [0.0, 0.125, ..., 1.875]
         execute.vec_ram.mem[1] <= 256'h0000_0100_0200_0300_0400_0500_0600_0700_0800_0900_0a00_0b00_0c00_0d00_0e00_0f00;
         next_cycle();
         `CHECK_EQUAL(execute.vec_ram.mem[0], execute.vec_ram.mem[1]);
         `CHECK_EQUAL(finished, 1);
      end

      `TEST_CASE("EQV") begin
         // vunit: .execute
         // vunit: .vec
         // EQV vX, v0, v1
         inst <= R(`OP_VEC_R, `VEC_EQ, `VECR_CMPV, 0, 0, 1);
         // v0 = [1.0, ..., 1.0]
         execute.vec_ram.mem[0] <= 256'h0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800;
         // v1 = [0.0, 0.125, ..., 1.875]
         execute.vec_ram.mem[1] <= 256'h0000_0100_0200_0300_0400_0500_0600_0700_0800_0900_0a00_0b00_0c00_0d00_0e00_0f00;
         next_cycle();
         `CHECK_EQUAL(execute.r_vcmp_mask, 16'b0000000010000000);
         `CHECK_EQUAL(finished, 1);
      end

      `TEST_CASE("EQMV") begin
         // vunit: .execute
         // vunit: .vec
         // EQMV vX, v0, v1
         inst <= R(`OP_VEC_R, `VEC_EQ, `VECR_CMPMV, 0, 0, 1);
         // v0 = [1.0, ..., 1.0]
         execute.vec_ram.mem[0] <= 256'h0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800;
         // v1 = [0.0, 0.125, ..., 1.875]
         execute.vec_ram.mem[1] <= 256'h0000_0100_0200_0300_0400_0500_0600_0700_0800_0900_0a00_0b00_0c00_0d00_0e00_0f00;
         execute.r_vcmp_mask <= 16'b1011100010001001;

         next_cycle();
         `CHECK_EQUAL(execute.r_vcmp_mask, 16'b0000000010000000);
         `CHECK_EQUAL(finished, 1);

         execute.r_vcmp_mask <= 16'b1011100101101001;
         next_cycle();
         `CHECK_EQUAL(execute.r_vcmp_mask, 0);
         `CHECK_EQUAL(finished, 1);
      end

      `TEST_CASE("LTV") begin
         // vunit: .execute
         // vunit: .vec
         // LTV vX, v0, v1
         inst <= R(`OP_VEC_R, `VEC_LT, `VECR_CMPV, 0, 1, 0);
         // v0 = [1.0, ..., 1.0]
         execute.vec_ram.mem[0] <= 256'h0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800;
         // v1 = [0.0, 0.125, ..., 1.875]
         execute.vec_ram.mem[1] <= 256'h0000_0100_0200_0300_0400_0500_0600_0700_0800_0900_0a00_0b00_0c00_0d00_0e00_0f00;
         next_cycle();
         `CHECK_EQUAL(execute.r_vcmp_mask, 16'b1111111100000000);
         `CHECK_EQUAL(finished, 1);
      end

      `TEST_CASE("LEMV + GEMV") begin
         // vunit: .execute
         // vunit: .vec
         // LEMV vX, v0, v1
         // GEMV vX, v0, v1
         inst <= R(`OP_VEC_R, `VEC_LE, `VECR_CMPMV, 0, 1, 0);
         // v0 = [1.0, ..., 1.0]
         execute.vec_ram.mem[0] <= 256'h0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800;
         // v1 = [0.0, 0.125, ..., 1.875]
         execute.vec_ram.mem[1] <= 256'h0000_0100_0200_0300_0400_0500_0600_0700_0800_0900_0a00_0b00_0c00_0d00_0e00_0f00;
         execute.r_vcmp_mask <= 16'b1011100110101001;
         next_cycle();
         `CHECK_EQUAL(execute.r_vcmp_mask, 16'b1011100110000000);
         `CHECK_EQUAL(finished, 1);

         inst <= R(`OP_VEC_R, `VEC_GE, `VECR_CMPMV, 0, 1, 0);
         next_cycle();
         `CHECK_EQUAL(execute.r_vcmp_mask, 16'b0000000010000000);
         `CHECK_EQUAL(finished, 1);
      end

      `TEST_CASE("MOVV") begin
         // vunit: .execute
         // vunit: .vec
         // MOVV v1, v0, vX
         inst <= R(`OP_VEC_R, 0, `VECR_MOVV, 1, 0, 0);
         // v0 = [0.0, 0.125, ..., 1.875]
         execute.vec_ram.mem[0] <= 256'h0000_0100_0200_0300_0400_0500_0600_0700_0800_0900_0a00_0b00_0c00_0d00_0e00_0f00;
         execute.vec_ram.mem[1] <= 0;
         execute.vec_ram.mem[15] <= 0;

         next_cycle();
         `CHECK_EQUAL(execute.vec_ram.mem[1], execute.vec_ram.mem[0]);
         `CHECK_EQUAL(finished, 1);

         // MOVV v15, v1, vX
         inst <= R(`OP_VEC_R, 0, `VECR_MOVV, 15, 1, 0);
         next_cycle();
         `CHECK_EQUAL(execute.vec_ram.mem[15], execute.vec_ram.mem[0]);
         `CHECK_EQUAL(finished, 1);
      end

      `TEST_CASE("MOVMV") begin
         // vunit: .execute
         // vunit: .vec
         // MOVMV v2, v0, vX
         inst <= R(`OP_VEC_R, 0, `VECR_MOVMV, 2, 0, 0);
         // v0 = [0.0, 0.125, ..., 1.875]
         execute.vec_ram.mem[0] <= 256'h0000_0100_0200_0300_0400_0500_0600_0700_0800_0900_0a00_0b00_0c00_0d00_0e00_0f00;
         execute.vec_ram.mem[1] <= 256'h0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800_0800;
         execute.r_vcmp_mask <= 16'b1011100110101001;

         next_cycle();
         `CHECK_EQUAL(execute.vec_ram.mem[2], 256'h0000_0000_0200_0300_0400_0000_0000_0700_0800_0000_0a00_0000_0c00_0000_0000_0f00);

         inst <= R(`OP_VEC_R, 0, `VECR_MOVMV, 1, 2, 0);
         execute.r_vcmp_mask <= 16'b1000000110101000;

         next_cycle();
         `CHECK_EQUAL(execute.vec_ram.mem[1], 256'h0000_0800_0800_0800_0800_0800_0800_0700_0800_0800_0a00_0800_0c00_0800_0800_0800);
      end
   end;
   `WATCHDOG(10ms);

   always begin
      #(clk_period/2 * 1ns);
      clk = !clk;
   end

   execute execute
     (
      .i_clk(clk),
      .i_rst(rst),

      .i_inst(inst),

      .o_addr(addr),

      .o_data(wr_data),
      .o_wr_valid(wr_valid),
      .i_wr_ready(wr_ready),
      .o_wr_width(wr_width),

      .i_data(rd_data),
      .i_rd_valid(rd_valid),
      .o_rd_ready(rd_ready),

      .i_pc(pc),
      .o_pc_change(pc_change),
      .o_new_pc(pc_new),
      .o_finished(finished),
      .o_invalid_inst(invalid_inst)
     );
endmodule
