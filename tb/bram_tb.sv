`include "vunit_defines.svh"
`include "funcs.svh"

module bram_tb;
   localparam integer clk_period = 20; // ns

   reg                clk = 0;
   reg                wr = 0;
   reg [31:0]         addr = 0;
   reg [31:0]         data_in = 0;
   wire [31:0]        data_out;
   wire [11:0]        addr_low12 = addr[11:0];

   task write
     (
      input [31:0] arg_addr,
      input [31:0] arg_data
     );
      wr = 1;
      addr = arg_addr;
      data_in = arg_data;
      @(posedge clk);
      #1;
      wr = 0;
      $info("Sent word ", arg_data, " to the address ", arg_addr);
   endtask

   task assert_read
     (
      input [31:0]            arg_addr,
      input [31:0] arg_expected
     );
      wr = 0;
      addr = arg_addr;
      @(posedge clk);
      #1
      `CHECK_EQUAL(arg_expected, data_out);
   endtask

   `TEST_SUITE begin
      `TEST_CASE("test_write_one_byte") begin
         write(0, 'hAA);
         assert_read(0, 'hAA);
      end
      `TEST_CASE("test_write_multiple_bytes") begin
         write(0, 'hAA);
         write(1, 'hAABBCCDD);
         assert_read(0, 'hAA);
         assert_read(1, 'hAABBCCDD);
      end
      `TEST_CASE("test_write_loop") begin
         for (int i=0; i<32; i++) begin
            write(2*i+1, i+1);
         end
         for (int i=0; i<32; i++) begin
            assert_read(2*i+1, i+1);
         end
       end
   end;
   `WATCHDOG(10ms);

   // Clocks generator
   always begin
      #(clk_period/2 * 1ns);
      clk = !clk;
   end

   // Init module
   bram
   #(
     .DATA_WIDTH(32),
     .ADDR_WIDTH(10)
   ) bram_mod
   (
    .i_clk(clk),
    .i_write(wr),
    .i_addr(addr_low12),
    .i_data(data_in),
    .o_data(data_out)
   );
endmodule
