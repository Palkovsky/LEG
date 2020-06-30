`include "vunit_defines.svh"
`include "funcs.svh"

module bramrv_tb;
   localparam
     clk_period = 10,
     ADDR_WIDTH = 10,
     DATA_WIDTH = 32;

   reg                clk = 0;

   reg [ADDR_WIDTH-1:0] addr = 0;

   reg [DATA_WIDTH-1:0] data_in = 0;
   reg                  wr_valid = 0;
   wire                 wr_ready;


   wire [DATA_WIDTH-1:0] data_out;
   wire                  rd_valid;
   reg                  rd_ready = 0;

   task next_cycle();
      @(posedge clk);
      #1;
   endtask

   task write
     (
      input [ADDR_WIDTH-1:0] arg_addr,
      input [DATA_WIDTH-1:0] arg_data
     );
      { wr_valid, addr, data_in } = { 1'b1, arg_addr, arg_data };
      #1;
      `CHECK_EQUAL(wr_ready, 1);
      next_cycle();
      wr_valid = 0;
      #1;
      `CHECK_EQUAL(wr_ready, 0);
      `CHECK_EQUAL(bram.bram.mem[arg_addr], arg_data);
   endtask

   task assert_read
     (
      input [ADDR_WIDTH-1:0] arg_addr,
      input [DATA_WIDTH-1:0] arg_expected
     );
      addr = arg_addr;
      rd_ready = 1;
      `CHECK_EQUAL(bram.reading, 0);
      next_cycle();
      `CHECK_EQUAL(bram.reading, 1);
      `CHECK_EQUAL(data_out, arg_expected);
      rd_ready = 0;
      next_cycle();
      `CHECK_EQUAL(bram.reading, 0);
   endtask

   `TEST_SUITE begin
      `TEST_SUITE_SETUP begin
         #1;
         `CHECK_EQUAL(bram.reading, 0);
      end
      `TEST_CASE("bramrv one write") begin
         // vunit: .bramrv
         write(21, 32'hAA);
         assert_read(21, 32'hAA);
         write(21, 32'hAB);
         assert_read(21, 32'hAB);
      end
      `TEST_CASE("bramrv multiple writes") begin
         // vunit: .bramrv
         write(21, 32'hAA);
         write(22, 32'hBB);
         write(23, 32'hCC);
         assert_read(21, 32'hAA);
         assert_read(22, 32'hBB);
         assert_read(23, 32'hCC);
         write(23, 32'h2211FFEE);
         assert_read(23, 32'h2211FFEE);
         assert_read(22, 32'hBB);
      end
   end;
   `WATCHDOG(10ms);

   // Clocks generator
   always begin
      #(clk_period/2 * 1ns);
      clk = !clk;
   end

   // Init module
   bram_rv
   #(
     .DATA_WIDTH(DATA_WIDTH),
     .ADDR_WIDTH(ADDR_WIDTH)
   ) bram
   (
	  .i_clk(clk),
    .i_rst(1'b0),
    .i_addr(addr),

    .i_data(data_in),
    .i_wr_valid(wr_valid),
    .o_wr_ready(wr_ready),

    .o_data(data_out),
    .o_rd_valid(rd_valid),
    .i_rd_ready(rd_ready)
   );
endmodule
