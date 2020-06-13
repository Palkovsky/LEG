`include "vunit_defines.svh"
`include "funcs.svh"

module core_tb;
   localparam integer clk_period = 10;
   reg                clk = 1'b0;
   reg                rst = 1'b0;

   wire [31:0]        addr;
   wire               wr;
   wire [`DATA_WIDTH-1:0] data_out;
   reg [`DATA_WIDTH-1:0]  data_in;

   localparam FETCH_STATE = 3'b000, EXECUTE_STATE = 3'b001;

   reg [31:0]             inst_buff;

   task next_cycle();
      @(posedge clk);
      #1;
   endtask

   task FETCH(input [31:0] inst);
      `CHECK_EQUAL(core.state, FETCH_STATE);

      // 1st cycle of fetch
      data_in = inst[31:24];
      `CHECK_EQUAL(addr, core.pc);
      next_cycle();
      `CHECK_EQUAL(core.state, FETCH_STATE);
      `CHECK_EQUAL(core.inst[31:24], inst[31:24])

      // 2nd cycle of fetch
      data_in = inst[23:16];
      `CHECK_EQUAL(addr, core.pc+1);
      next_cycle();
      `CHECK_EQUAL(core.state, FETCH_STATE);
      `CHECK_EQUAL(core.inst[23:16], inst[23:16]);

      // 3rd cycle of fetch
      data_in = inst[15:8];
      `CHECK_EQUAL(addr, core.pc+2);
      next_cycle();
      `CHECK_EQUAL(core.state, FETCH_STATE);
      `CHECK_EQUAL(core.inst[15:8], inst[15:8]);

      // 4 bytes(full instruction) fetched
      data_in = inst[7:0];
      `CHECK_EQUAL(addr, core.pc+3);
      next_cycle();
      `CHECK_EQUAL(core.state, EXECUTE_STATE);
      `CHECK_EQUAL(core.inst[7:0], inst[7:0]);
      `CHECK_EQUAL(core.inst, inst);
   endtask

   `TEST_SUITE begin
      `TEST_SUITE_SETUP begin
         rst <= 1;
         next_cycle();
         rst <= 0;
         `CHECK_EQUAL(core.state, FETCH_STATE);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(wr, 0);
         `CHECK_EQUAL(data_out, 0);
         `CHECK_EQUAL(core.pc, 0);
      end
      `TEST_CASE("SH") begin
         // It tests multi-cycle instruction behavior.
         FETCH(LUI(5, 20'hAABBC));
         `CHECK_EQUAL(core.execute.X[5], 0);
         `CHECK_EQUAL(core.pc, 0);
         next_cycle();
         `CHECK_EQUAL(core.execute.X[5], 32'hAABBC000);
         `CHECK_EQUAL(core.state, FETCH_STATE);
         `CHECK_EQUAL(core.pc, 4);

         FETCH(S(`STORE, `SH, 0, 'hABC, 5));
         #1;
         `CHECK_EQUAL(wr, 1);
         `CHECK_EQUAL(addr, 'hABC);
         `CHECK_EQUAL(data_out, 'hC0);
         `CHECK_EQUAL(core.state, EXECUTE_STATE);
         next_cycle();

         `CHECK_EQUAL(wr, 1);
         `CHECK_EQUAL(addr, 'hABD);
         `CHECK_EQUAL(data_out, 'h00);
         `CHECK_EQUAL(core.state, EXECUTE_STATE);
         next_cycle();

         `CHECK_EQUAL(wr, 0);
         `CHECK_EQUAL(core.state, FETCH_STATE);
         `CHECK_EQUAL(core.pc, 8);
      end
      `TEST_CASE("JUMPING INSTRUCTIONS") begin
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
      `TEST_CASE("ADDI") begin
         inst_buff = IMM_OP(1, 1, "+", 21);
         // 1st cycle of fetch
         data_in = inst_buff[31:24];
         next_cycle();
         `CHECK_EQUAL(core.state, FETCH_STATE);
         `CHECK_EQUAL(addr, 1);
         `CHECK_EQUAL(core.pc, 0);
         `CHECK_EQUAL(core.inst, inst_buff & 32'hFF000000)

         // 2nd cycle of fetch
         data_in = inst_buff[23:16];
         next_cycle();
         `CHECK_EQUAL(core.state, FETCH_STATE);
         `CHECK_EQUAL(addr, 2);
         `CHECK_EQUAL(core.pc, 0);
         `CHECK_EQUAL(core.inst, inst_buff & 32'hFFFF0000);

         // 3rd cycle of fetch
         data_in = inst_buff[15:8];
         next_cycle();
         `CHECK_EQUAL(core.state, FETCH_STATE);
         `CHECK_EQUAL(addr, 3);
         `CHECK_EQUAL(core.pc, 0);
         `CHECK_EQUAL(core.inst, inst_buff & 32'hFFFFFF00);

         // 4 bytes(full instruction) fetched
         data_in = inst_buff[7:0];
         next_cycle();
         `CHECK_EQUAL(core.state, EXECUTE_STATE);
         `CHECK_EQUAL(core.pc, 0);
         `CHECK_EQUAL(addr, 0);
         `CHECK_EQUAL(core.inst, inst_buff);

         // Execute
         `CHECK_EQUAL(core.execute.X[1], 0);
         `CHECK_EQUAL(core.execute.w_I, 21);
         `CHECK_EQUAL(core.execute.w_rs1, 1);
         `CHECK_EQUAL(core.execute.w_rd, 1);
         `CHECK_EQUAL(core.execute.X[core.execute.w_rs1] + core.execute.w_I, 21);
         next_cycle();

         `CHECK_EQUAL(core.invalid_inst, 0);
         `CHECK_EQUAL(core.inst, inst_buff);
         `CHECK_EQUAL(core.state, FETCH_STATE);
         `CHECK_EQUAL(core.pc, 4);
         `CHECK_EQUAL(core.execute.X[1], 21);
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

      .o_mem_addr(addr),
      .o_mem_data(data_out),
      .i_mem_data(data_in),
      .o_mem_write(wr)
     );
endmodule
