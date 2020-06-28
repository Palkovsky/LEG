`include "vunit_defines.svh"
`include "funcs.svh"

module fetch_tb;
   localparam integer clk_period = 10;
   reg                clk = 0;
   reg                rst = 0;
   reg                stall = 0;

   reg [31:0]         pc = 0;

   reg [`DATA_WIDTH-1:0] data_sim;
   reg [`DATA_WIDTH-1:0] data;
   reg                   valid;
   wire [31:0]           addr;

   reg [31:0]           inst;
   reg                  ready;
   wire                 finished;

   // Simulate memory.
   always_comb begin
      case (addr)
        0: data_sim = 32'hAA;
        1: data_sim = 32'hBB;
        2: data_sim = 32'hCC;
        3: data_sim = 32'hDD;
        default: data_sim = 0;
      endcase
   end
   always @(posedge clk) begin
      valid <= 0;
      if (ready) begin
         valid <= 1;
         data <= data_sim;
      end
   end

   task next_cycle();
      @(posedge clk);
      #1;
   endtask

   `TEST_SUITE begin
      `TEST_SUITE_SETUP begin
         rst = 1;
         next_cycle();
         rst = 0;
         `CHECK_EQUAL(ready, 0);
         #1;
         `CHECK_EQUAL(inst, 0);
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(valid, 0);
         `CHECK_EQUAL(finished, 0);
      end
      `TEST_CASE("one_cycle") begin
         // vunit: .fetch
         next_cycle(); // BRAM buffer store
         `CHECK_EQUAL(finished, 1);
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(valid, 1);
         `CHECK_EQUAL(inst, 32'h00);
         next_cycle(); // Instruction load
         `CHECK_EQUAL(inst, 32'hAA);
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(valid, 1);
         `CHECK_EQUAL(finished, 1);
      end
      `TEST_CASE("two_cycles") begin
         // vunit: .fetch
         next_cycle(); // BRAM buff store
         `CHECK_EQUAL(inst, 32'h00);
         `CHECK_EQUAL(addr, pc);
         `CHECK_EQUAL(finished, 1);
         `CHECK_EQUAL(ready, 1);

         // The data is in buffer, increment PC.
         pc = pc+1;
         #1;
         `CHECK_EQUAL(pc, 1);
         `CHECK_EQUAL(addr, pc);

         next_cycle(); // BB to buffer, AA to inst
         `CHECK_EQUAL(inst, 32'hAA);
         `CHECK_EQUAL(finished, 1);
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(valid, 1);

         next_cycle(); // BB to buffer, BB to inst
         `CHECK_EQUAL(inst, 32'hBB);
         `CHECK_EQUAL(finished, 1);
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(valid, 1);
      end
      `TEST_CASE("reset") begin
         // vunit: .fetch
         next_cycle(); // AA to buffer, nothing to inst
         `CHECK_EQUAL(finished, 1);
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(valid, 1);
         `CHECK_EQUAL(inst, 32'h00);
         next_cycle(); // AA to buffer, AA to inst
         `CHECK_EQUAL(inst, 32'hAA);
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(valid, 1);
         `CHECK_EQUAL(finished, 1);

         // Perform reset
         rst = 1;
         next_cycle();
         `CHECK_EQUAL(ready, 0);
         rst = 0;
         pc = 2;
         #1;

         // After reset
         `CHECK_EQUAL(finished, 0);
         `CHECK_EQUAL(inst, 32'h00);
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(valid, 0);

         next_cycle(); // CC to buffer, nothing to inst
         `CHECK_EQUAL(valid, 1);
         `CHECK_EQUAL(finished, 1);
         `CHECK_EQUAL(inst, 32'h00);
         `CHECK_EQUAL(ready, 1);
         next_cycle(); // CC to buffer again, CC to inst
         `CHECK_EQUAL(valid, 1);
         `CHECK_EQUAL(finished, 1);
         `CHECK_EQUAL(inst, 32'hCC);
         `CHECK_EQUAL(ready, 1);
      end
   end;

   always begin
      #(clk_period/2 * 1ns);
      clk = !clk;
   end

   fetch fetch
     (
      .i_clk(clk),
      .i_rst(rst),
      .i_stall(stall),
      .i_pc(pc),

      .i_data(data),
      .o_addr(addr),
      .i_valid(valid),
      .o_ready(ready),

      .o_inst(inst),
      .o_finished(finished)
     );
endmodule
