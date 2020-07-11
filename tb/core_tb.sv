`include "vunit_defines.svh"
`include "funcs.svh"

module core_tb;
   localparam integer clk_period = 10;
   reg                clk = 1'b0;
   reg                rst = 1'b0;

   // Memory interface
   wire [31:0]            addr;
   // Writes
   wire [`DATA_WIDTH-1:0] wr_data;
   wire                   wr_valid;
   reg                    wr_ready = 0;
   // Reads
   reg [`DATA_WIDTH-1:0]  rd_data = 0;
   reg                    rd_valid = 0;
   wire                   rd_ready;

   localparam
     FETCH_STATE = 3'b000,
     EXEC_STATE = 3'b001;

   wire                   invalid_inst;

   task next_cycle();
      @(posedge clk);
      #1;
   endtask

   task FETCH(input [31:0] inst);
      `CHECK_EQUAL(core.state, FETCH_STATE);
      `CHECK_EQUAL(addr, core.pc);
      `CHECK_EQUAL(rd_valid, 0);
      `CHECK_EQUAL(rd_ready, 1);
      next_cycle();
      `CHECK_EQUAL(core.state, FETCH_STATE);

      rd_valid = 1;
      rd_data  = inst;
      `CHECK_EQUAL(rd_ready, 1);
      #1;
      `CHECK_EQUAL(core.fetch_finished, 1);
      next_cycle();
      rd_valid = 0;
      `CHECK_EQUAL(core.fetch_finished, 0);
      `CHECK_EQUAL(core.inst, inst);
      `CHECK_EQUAL(core.state, EXEC_STATE);
   endtask

   `TEST_SUITE begin
      `TEST_SUITE_SETUP begin
         rst = 1;
         next_cycle();
         rst = 0;
         #1;
         `CHECK_EQUAL(core.state, FETCH_STATE);
         `CHECK_EQUAL(addr, 0);
      end
      `TEST_CASE("SH") begin
         // vunit: .core
         // It tests multi-cycle instruction behavior.
         FETCH(LUI(5, 20'hAABBC));
         `CHECK_EQUAL(core.execute.X[5], 0);
         `CHECK_EQUAL(core.pc, 0);
         next_cycle();
         `CHECK_EQUAL(core.execute.X[5], 32'hAABBC000);
         `CHECK_EQUAL(core.state, FETCH_STATE);
         `CHECK_EQUAL(core.pc, 4);

         FETCH(S(`STORE, `SH, 0, 'h7BC, 5));
         #1;
         `CHECK_EQUAL(wr_valid, 1);
         `CHECK_EQUAL(wr_ready, 0);
         `CHECK_EQUAL(addr, 'h7BC);
         `CHECK_EQUAL(wr_data[15:0], 16'hC000);
         `CHECK_EQUAL(core.state, EXEC_STATE);
         `CHECK_EQUAL(core.exec_finished, 0);
         `CHECK_EQUAL(core.execute.mem_transfer_done, 0);
         next_cycle();

         // Still in EXEC, cuz wr_ready==0
         `CHECK_EQUAL(core.state, EXEC_STATE);
         `CHECK_EQUAL(core.exec_finished, 0);
         `CHECK_EQUAL(wr_valid, 1);
         `CHECK_EQUAL(wr_ready, 0);

         next_cycle();
         // Still in EXEC, cuz wr_ready==0
         `CHECK_EQUAL(core.state, EXEC_STATE);
         `CHECK_EQUAL(core.exec_finished, 0);
         `CHECK_EQUAL(wr_valid, 1);
         `CHECK_EQUAL(wr_ready, 0);

         wr_ready = 1;
         #1;
         `CHECK_EQUAL(core.exec_finished, 1);

         next_cycle();
         `CHECK_EQUAL(core.state, FETCH_STATE);
         `CHECK_EQUAL(core.pc, 8);
      end
      `TEST_CASE("JUMPING INSTRUCTIONS") begin
         // vunit: .core
         // x1 = 11
         FETCH(IMM_OP(1, 0, "+", 11));
         `CHECK_EQUAL(core.execute.X[1], 0);
         `CHECK_EQUAL(core.pc, 0);
         next_cycle();
         `CHECK_EQUAL(core.execute.X[1], 11);
         `CHECK_EQUAL(core.state, FETCH_STATE);
         `CHECK_EQUAL(core.pc, 4);

         // x2 = 55
         FETCH(IMM_OP(2, 0, "+", 55));
         `CHECK_EQUAL(core.execute.X[2], 0);
         next_cycle();
         `CHECK_EQUAL(core.execute.X[2], 55);
         `CHECK_EQUAL(core.state, FETCH_STATE);
         `CHECK_EQUAL(core.pc, 8);

         // BRANCH if x1 > x2 -> PC shouldn't change
         FETCH(BRANCH(1, ">", 2, 'h7FF));
         next_cycle();
         `CHECK_EQUAL(core.state, FETCH_STATE);
         `CHECK_EQUAL(core.pc, 12);

         // BRANCH if x1 < x2 -> PC should change
         FETCH(BRANCH(1, "<", 2, 'h7FF));
         next_cycle();
         `CHECK_EQUAL(core.state, FETCH_STATE);
         // 12 + 'h7FF*2 = 0x100A
         `CHECK_EQUAL(core.pc, 'h100A);

         // JAL -> Jump back to 0
         `CHECK_EQUAL(core.execute.X[8], 0);
         FETCH(J(`JAL, 8, ~(core.pc>>1)+1));
         next_cycle();
         `CHECK_EQUAL(core.execute.X[8], 'h100A + 4);
         `CHECK_EQUAL(core.pc, 0);
      end
   end;
   `WATCHDOG(10ms);

   always begin
      #(clk_period/2 * 1ns);
      clk = !clk;
   end

   core core
     (
	    .i_clk(clk),
	    .i_rst(rst),

      // Memory interface
      .o_addr(addr),
      // Writes
      .o_data(wr_data),
      .o_wr_valid(wr_valid),
      .i_wr_ready(wr_ready),
      // Reads
      .i_data(rd_data),
      .i_rd_valid(rd_valid),
      .o_rd_ready(rd_ready),

      .o_invalid_inst(invalid_inst)
     );
endmodule
