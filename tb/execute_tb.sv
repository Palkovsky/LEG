`include "vunit_defines.svh"
`include "funcs.svh"

module execute_tb;
   localparam integer clk_period = 10;
   reg                clk = 0;
   reg                rst = 0;

   wire               wr;
   wire [31:0]        addr;
   reg [`DATA_WIDTH-1:0] data_sim;
   reg [`DATA_WIDTH-1:0] data;
   wire [`DATA_WIDTH-1:0] wr_data;

   reg [31:0]  inst;

   reg [31:0]  pc;
   wire        pc_change;
   wire [31:0] pc_new;
   wire        ready;
   wire        invalid_inst;

   // Simulate memory.
   always_comb begin
      case (addr)
        0: data_sim = 'hAA;
        1: data_sim = 'hBB;
        2: data_sim = 'hCC;
        3: data_sim = 'hDD;
        4: data_sim = 'h44;
        5: data_sim = 'h55;
        default: data_sim = 0;
      endcase
   end

   always @(posedge clk) begin
      data <= data_sim;
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
         `CHECK_EQUAL(ready, 1);
      end
      `TEST_CASE("SETREG_TASK") begin
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
         `CHECK_EQUAL(execute.X[1], pc+4);
         `CHECK_EQUAL(pc_change, 1);
         `CHECK_EQUAL(pc_new, pc + (2<<1));
         `CHECK_EQUAL(ready, 1);
         pc <= pc_new;

         // JAL x2, -1MB
         inst <= J(`JAL, 2, {1'b1, 19'b0});
         next_cycle();
         `CHECK_EQUAL(execute.X[2], pc+4);
         `CHECK_EQUAL(pc_change, 1);
         `CHECK_EQUAL(pc_new, pc + { 12'hFFF, 20'b0});
         `CHECK_EQUAL(ready, 1);
         pc <= pc_new;

         // JAL x3, +200
         inst <= J(`JAL, 3, 100);
         next_cycle();
         `CHECK_EQUAL(execute.X[3], pc+4);
         `CHECK_EQUAL(pc_change, 1);
         `CHECK_EQUAL(pc_new, pc + 200);
         `CHECK_EQUAL(ready, 1);
      end
      `TEST_CASE("JALR") begin
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
         // SB [x0+0xABC], x15
         SETREG(15, 'h11223344);
         inst <= S(`STORE, `SB, 0, 'h7BC, 15);
         `CHECK_EQUAL(wr, 0);
         next_cycle();
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(wr, 1);
         `CHECK_EQUAL(addr, 'h7BC);
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
         inst <= S(`STORE, `SH, 0, 'h7BC, 15);
         `CHECK_EQUAL(wr, 0);
         #1
         `CHECK_EQUAL(wr, 1);
         `CHECK_EQUAL(addr, 'h7BC);
         `CHECK_EQUAL(wr_data, 'h33);
         next_cycle(); // <- On this edge BRAM should write 1st byte
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(wr, 1);
         `CHECK_EQUAL(addr, 'h7BD);
         `CHECK_EQUAL(wr_data, 'h44);

         // Prepare next instruction
         inst <= 0;
         next_cycle(); // <- On this edge BRAM should write 2nd byte
         `CHECK_EQUAL(wr, 0);
         `CHECK_EQUAL(ready, 1);
      end
      `TEST_CASE("SW") begin
         // SW [x0+0xABC], x15
         SETREG(15, 'h11223344);
         inst <= S(`STORE, `SW, 0, 'h7BC, 15);
         `CHECK_EQUAL(wr, 0);
         #1
         `CHECK_EQUAL(wr, 1);
         `CHECK_EQUAL(addr, 'h7BC);
         `CHECK_EQUAL(wr_data, 'h11);
         next_cycle(); // <- On this edge BRAM should write 1st byte
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(wr, 1);
         `CHECK_EQUAL(addr, 'h7BD);
         `CHECK_EQUAL(wr_data, 'h22);
         next_cycle(); // <- On this edge BRAM should write 2nd byte
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(wr, 1);
         `CHECK_EQUAL(addr, 'h7BE);
         `CHECK_EQUAL(wr_data, 'h33);
         next_cycle(); // <- On this edge BRAM should write 3rd byte
         `CHECK_EQUAL(ready, 1); // This is the last cycle
         `CHECK_EQUAL(wr, 1);
         `CHECK_EQUAL(addr, 'h7BF);
         `CHECK_EQUAL(wr_data, 'h44);

         //  Becose ready==1, prepare next instruction
         inst <= 0;
         next_cycle(); // <- On this edge BRAM should write 4th byte
         `CHECK_EQUAL(execute.i_inst, 0);
         `CHECK_EQUAL(execute.r_cycle, 0);
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(wr, 0);
      end // always
      `TEST_CASE("LB positive") begin
         // LB x8, [x0 + 4]
         inst <= I(`LOAD, `LB, 8, 0, 4);
         #1;
         `CHECK_EQUAL(wr_data, 0);
         `CHECK_EQUAL(addr, 4);
         `CHECK_EQUAL(execute.X[8], 'h00);
         next_cycle();
         `CHECK_EQUAL(wr_data, 0);
         `CHECK_EQUAL(addr, 5);
         `CHECK_EQUAL(execute.X[8], 0);
         `CHECK_EQUAL(ready, 1);
         next_cycle();
         `CHECK_EQUAL(execute.X[8], 'h00000044);
      end
      `TEST_CASE("LB negative") begin
         // LB x8, [x0 + 2]
         inst = I(`LOAD, `LB, 8, 0, 2);
         `CHECK_EQUAL(wr_data, 0);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(execute.X[8], 'h00);
         #1
         `CHECK_EQUAL(addr, 2);
         next_cycle();
         `CHECK_EQUAL(addr, 3);
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(wr_data, 0);
         `CHECK_EQUAL(execute.X[8], 0);
         next_cycle();
         `CHECK_EQUAL(execute.X[8], 'hFFFFFFCC);
      end
      `TEST_CASE("LBU") begin
         // LBU x1, [x0 + 1]
         inst <= I(`LOAD, `LBU, 1, 0, 1);
         `CHECK_EQUAL(wr_data, 0);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(execute.X[1], 'h00);
         #1
         `CHECK_EQUAL(addr, 1);
         next_cycle();
         `CHECK_EQUAL(addr, 2);
         `CHECK_EQUAL(wr_data, 0);
         next_cycle();
         `CHECK_EQUAL(execute.X[1], 'hBB);
      end
      `TEST_CASE("LH positive") begin
         // LH x2, [x0 + 4]
         inst <= I(`LOAD, `LH, 2, 0, 4);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(execute.X[2], 'h00);
         #1
         `CHECK_EQUAL(addr, 4);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], '0);
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(addr, 5);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 32'h00004400);
         `CHECK_EQUAL(addr, 6);
         `CHECK_EQUAL(ready, 1);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 32'h00004455);
         `CHECK_EQUAL(ready, 0);
      end
      `TEST_CASE("LH negative") begin
         // LH x2, [x0 + 0]
         inst <= I(`LOAD, `LH, 2, 0, 0);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(execute.X[2], 'h00);
         #1
         `CHECK_EQUAL(addr, 0);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 'h0000);
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(addr, 1);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 'hAA00);
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(addr, 2);
         next_cycle();
         `CHECK_EQUAL(execute.X[2], 'hFFFFAABB);
         `CHECK_EQUAL(ready, 0);
      end
      `TEST_CASE("LHU") begin
         // LHU x1, [x0 + 3]
         inst <= I(`LOAD, `LHU, 1, 0, 3);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(execute.X[1], 'h00);
         #1
         `CHECK_EQUAL(addr, 3);
         next_cycle();
         `CHECK_EQUAL(execute.X[1], 0);
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(addr, 4);
         next_cycle();
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(addr, 5);
         `CHECK_EQUAL(execute.X[1], 'hDD00);
         next_cycle();
         `CHECK_EQUAL(execute.X[1], 'hDD44);
         `CHECK_EQUAL(ready, 0);
      end
      `TEST_CASE("LW") begin
         // LW x15, [x0+1]
         inst <= I(`LOAD, `LW, 15, 0, 1);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(execute.X[15], 'h00);
         #1
         `CHECK_EQUAL(addr, 1);
         next_cycle();
         `CHECK_EQUAL(execute.X[15], 'h00000000);
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(addr, 2);
         next_cycle();
         `CHECK_EQUAL(execute.X[15], 'hBB000000);
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(addr, 3);
         next_cycle();
         `CHECK_EQUAL(execute.X[15], 'hBBCC0000);
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(addr, 4);
         next_cycle();
         `CHECK_EQUAL(execute.X[15], 'hBBCCDD00);
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(addr, 5);
         next_cycle();
         `CHECK_EQUAL(execute.X[15], 'hBBCCDD44);
         `CHECK_EQUAL(ready, 0);
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

      .i_mem_data(data),
      .o_mem_addr(addr),
      .o_mem_write(wr),
      .o_mem_data(wr_data),

      .i_pc(pc),
      .o_pc_change(pc_change),
      .o_new_pc(pc_new),
      .o_ready(ready),
      .o_invalid_inst(invalid_inst)
     );
endmodule
