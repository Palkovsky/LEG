`include "vunit_defines.svh"
`include "funcs.svh"

module bram_tb;
   localparam integer clk_a_period = 20; // ns
   localparam integer clk_b_period = 10; // ns

   reg                clk_a = 1'b0;
   reg                wr_a = 1'b0;
   reg [31:0]         addr_a = 1'b0;
   reg [`DATA_WIDTH-1:0] data_a_in = 1'b0;
   wire [`DATA_WIDTH-1:0] data_a_out;
   wire [11:0]            addr_a_low12 = addr_a[11:0];

   reg                    clk_b = 1'b0;
   reg                    wr_b = 1'b0;
   reg [31:0]             addr_b = 1'b0;
   reg [`DATA_WIDTH-1:0]  data_b_in = 1'b0;
   wire [`DATA_WIDTH-1:0] data_b_out;
   wire [11:0]            addr_b_low12 = addr_b[11:0];

   task automatic write
     (
      input string            port,
      input [31:0]            addr,
      input [`DATA_WIDTH-1:0] data
     );
      if (port == "A") begin
         wr_a <= 1;
         addr_a <= addr;
         data_a_in <= data;
         wait(wr_a == 1 && addr_a == addr && data_a_in == data);
         @(posedge clk_a);
         wr_a <= 0;
         wait(wr_a == 0);
      end
      else if (port == "B") begin
         wr_b <= 1;
         addr_b <= addr;
         data_b_in <= data;
         wait(wr_b == 1 && addr_b == addr && data_b_in == data);
         @(posedge clk_b);
         wr_b <= 0;
         wait(wr_b == 0);
      end
      $info("Sent word ", data, " to the address ", addr);
   endtask // write

   task automatic assert_read
     (
      input string            port,
      input [31:0]            addr,
      input [`DATA_WIDTH-1:0] expected
     );
      if (port == "A") begin
         wr_a <= 0;
         addr_a <= addr;
         wait(wr_a == 0 && addr_a == addr);
         @(posedge clk_a);
         #1
         `CHECK_EQUAL(expected, data_a_out);
      end
      else if (port == "B") begin
         wr_b <= 0;
         addr_b <= addr;
         wait(wr_b == 0 && addr_b == addr);
         @(posedge clk_b);
         #1
         `CHECK_EQUAL(expected, data_b_out);
      end
   endtask // assert_read

   `TEST_SUITE begin
      `TEST_CASE("test_write_one_byte") begin
         write("A", 0, 'hAA);
         assert_read("A", 0, 'hAA);
      end
      `TEST_CASE("test_write_multiple_bytes") begin
         write("A", 0, 'hAA);
         write("B", 1, 'hBB);
         assert_read("A", 0, 'hAA);
         assert_read("B", 1, 'hBB);
         assert_read("B", 1, 'hBB);
      end
      `TEST_CASE("test_write_multiple_same_port") begin
         write("A", 0, 'hAA);
         write("A", 1, 'hBB);
         assert_read("A", 0, 'hAA);
         assert_read("A", 1, 'hBB);
      end
      `TEST_CASE("test_write_loop") begin
         for (int i=0; i<2; i++) begin
            write("A", 2*i, i);
            write("B", 2*i+1, i+1);
         end
         for (int i=0; i<2; i++) begin
            assert_read("A", 2*i, i);
            assert_read("B", 2*i+1, i+1);
         end
       end
   end;
   `WATCHDOG(10ms);

   // Clocks generators
   always begin
      #(clk_a_period/2 * 1ns);
      clk_a = !clk_a;
   end

   always begin
      #(clk_b_period/2 * 1ns);
      clk_b = !clk_b;
   end

   // Init module
   bram
   #(
     .DATA_WIDTH(`DATA_WIDTH),
     .ADDR_WIDTH(12)
   ) bram_mod
   (
    .i_clk_a(clk_a),
    .i_clk_b(clk_b),
    .i_write_a(wr_a),
    .i_write_b(wr_b),
    .i_addr_a(addr_a_low12),
    .i_addr_b(addr_b_low12),
    .i_data_a(data_a_in),
    .i_data_b(data_b_in),
    .o_data_a(data_a_out),
    .o_data_b(data_b_out)
   );
endmodule
