`include "vunit_defines.svh"
`include "funcs.svh"

module fetch_tb;
   localparam integer clk_period = 10;
   reg                clk = 0;
   reg                rst = 0;

   reg [31:0]         pc = 0;

   reg [`DATA_WIDTH-1:0] data_sim;
   reg [`DATA_WIDTH-1:0] data;
   wire [31:0]           addr;

   reg [31:0]           inst;
   wire                 ready;
   wire                 started;

   // Simulate memory.
   always_comb begin
      case (addr)
        0: data_sim = 'hAA;
        1: data_sim = 'hBB;
        2: data_sim = 'hCC;
        3: data_sim = 'hDD;
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

   `TEST_SUITE begin
      `TEST_SUITE_SETUP begin
         rst <= 1;
         next_cycle();
         rst <= 0;
      end
      `TEST_CASE("initial_state") begin
         `CHECK_EQUAL(inst, 0);
         `CHECK_EQUAL(ready, 0);
      end
      `TEST_CASE("one_cycle") begin
         next_cycle();
         `CHECK_EQUAL(inst, 'h00000000);
         next_cycle();
         `CHECK_EQUAL(inst, 'hAA000000);
         `CHECK_EQUAL(ready, 0);
      end
      `TEST_CASE("two_cycles") begin
         next_cycle();
         `CHECK_EQUAL(inst, 'h00000000);
         next_cycle();
         `CHECK_EQUAL(inst, 'hAA000000);
         next_cycle();
         `CHECK_EQUAL(inst, 'hAABB0000);
         `CHECK_EQUAL(ready, 0);
      end
      `TEST_CASE("three_cycles") begin
         next_cycle();
         `CHECK_EQUAL(inst, 'h00000000);
         next_cycle();
         `CHECK_EQUAL(inst, 'hAA000000);
         next_cycle();
         `CHECK_EQUAL(inst, 'hAABB0000);
         next_cycle();
         `CHECK_EQUAL(inst, 'hAABBCC00);
         `CHECK_EQUAL(ready, 1);
      end
      `TEST_CASE("three_cycles_rst") begin
         next_cycle();
         `CHECK_EQUAL(inst, 'h00000000);
         next_cycle();
         `CHECK_EQUAL(inst, 'hAA000000);
         next_cycle();
         `CHECK_EQUAL(inst, 'hAABB0000);
         rst <= 1;
         next_cycle();
         rst <= 0;
         `CHECK_EQUAL(inst, 'hAABB0000);
         `CHECK_EQUAL(ready, 0);
         next_cycle();
         `CHECK_EQUAL(inst, 'hAABB0000);
         `CHECK_EQUAL(ready, 0);
         next_cycle();
         `CHECK_EQUAL(inst, 'hAABB0000);
         `CHECK_EQUAL(ready, 0);
         next_cycle();
         `CHECK_EQUAL(inst, 'hAABB0000);
         `CHECK_EQUAL(ready, 0);
         next_cycle();
         `CHECK_EQUAL(inst, 'hAABBCC00);
         `CHECK_EQUAL(ready, 1);
         next_cycle();
         `CHECK_EQUAL(inst, 'hAABBCCDD);
         `CHECK_EQUAL(ready, 0);
      end
      `TEST_CASE("four_cycles") begin
         `CHECK_EQUAL(started, 0);
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(inst, 'h00000000);
         next_cycle();
         `CHECK_EQUAL(started, 1);
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(inst, 'h00000000);
         next_cycle();
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(inst, 'hAA000000);
         next_cycle();
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(inst, 'hAABB0000);
         next_cycle();
         `CHECK_EQUAL(ready, 1);
         `CHECK_EQUAL(inst, 'hAABBCC00);
         next_cycle();
         `CHECK_EQUAL(inst, 'hAABBCCDD);
         `CHECK_EQUAL(ready, 0);
      end
      `TEST_CASE("five_cycles") begin
         `CHECK_EQUAL(started, 0);
         `CHECK_EQUAL(ready, 0);
         `CHECK_EQUAL(inst, 'h00000000);
         next_cycle();
         `CHECK_EQUAL(started, 1);
         `CHECK_EQUAL(inst, 'h00000000);
         next_cycle();
         `CHECK_EQUAL(inst, 'hAA000000);
         next_cycle();
         `CHECK_EQUAL(inst, 'hAABB0000);
         next_cycle();
         `CHECK_EQUAL(inst, 'hAABBCC00);
         `CHECK_EQUAL(ready, 1);
         pc = pc+4;
         next_cycle();
         `CHECK_EQUAL(inst, 'hAABBCCDD);
         `CHECK_EQUAL(ready, 0);
         next_cycle();
         `CHECK_EQUAL(inst, 'h00BBCCDD);
         `CHECK_EQUAL(ready, 0);
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
      .i_pc(pc),
      .i_mem_data(data),
      .o_mem_addr(addr),
      .o_inst(inst),
      .o_ready(ready),
      .o_started(started)
     );
endmodule
