`include "vunit_defines.svh"
`include "../src/common.svh"

module fetch_tb;
   localparam integer clk_period = 10;
   reg                clk = 0;
   reg                rst = 0;

   reg [31:0]         pc = 0;

   reg [`DATA_WIDTH-1:0] data;
   wire [31:0]           addr;
   wire                  wr;

   wire [31:0]           inst;
   wire ready;

   // Simulate memory.
   always_comb begin
      case (addr)
        0: data = 'hAA;
        1: data = 'hBB;
        2: data = 'hCC;
        3: data = 'hDD;
        default: data = 0;
      endcase
   end

   `TEST_SUITE begin
      `TEST_CASE("initial_state") begin
         #1
         `CHECK_EQUAL(wr, 0);
         `CHECK_EQUAL(inst, 0);
         `CHECK_EQUAL(ready, 0);
      end
      `TEST_CASE("one_cycle") begin
         @(posedge clk);
         #1
         `CHECK_EQUAL(inst, 'hAA000000);
         `CHECK_EQUAL(ready, 0);
      end
      `TEST_CASE("two_cycles") begin
         @(posedge clk);
         @(posedge clk);
         #1
         `CHECK_EQUAL(inst, 'hAABB0000);
         `CHECK_EQUAL(ready, 0);
      end
      `TEST_CASE("three_cycles") begin
         @(posedge clk);
         @(posedge clk);
         @(posedge clk);
         #1
         `CHECK_EQUAL(inst, 'hAABBCC00);
         `CHECK_EQUAL(ready, 0);
      end
      `TEST_CASE("three_cycles_rst") begin
         @(posedge clk);
         @(posedge clk);
         rst <= 1;
         @(posedge clk);
         #1
         `CHECK_EQUAL(inst, 'h00);
         `CHECK_EQUAL(ready, 0);
      end
      `TEST_CASE("four_cycles") begin
         @(posedge clk);
         @(posedge clk);
         @(posedge clk);
         @(posedge clk);
         #1
         `CHECK_EQUAL(inst, 'hAABBCCDD);
         `CHECK_EQUAL(ready, 1);
      end
      `TEST_CASE("five_cycles") begin
         @(posedge clk);
         @(posedge clk);
         @(posedge clk);
         @(posedge clk);
         pc <= pc + 4;
         @(posedge clk);
         #1
         `CHECK_EQUAL(inst, 'h00BBCCDD);
         `CHECK_EQUAL(ready, 0);
      end
   end;

   always begin
      #(clk_period/2 * 1ns);
      clk = !clk;
   end

   fetch fetch (
                .i_clk(clk),
                .i_rst(rst),
                .i_pc(pc),
                .i_mem_data(data),
                .o_mem_addr(addr),
                .o_mem_write(wr),
                .o_inst(inst),
                .o_ready(ready)
                );
endmodule
