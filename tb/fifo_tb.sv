`include "vunit_defines.svh"

module fifo_tb;
   localparam DATA_WIDTH = 8, ADDR_WIDTH = 4, FIFO_SIZE = (1<<ADDR_WIDTH);
   localparam integer clk_wr_period = 20;
   localparam integer clk_rd_period = 15;

   reg                clk_wr = 0, clk_rd = 0;
   reg                rst = 0;

   reg [DATA_WIDTH-1:0] data_out;
   reg                  is_empty;

   reg [DATA_WIDTH-1:0]  data_in;
   reg                   is_full;

   reg                  write_en = 0, read_en = 0;


   task next_rd_cycle();
      @(posedge clk_rd);
      #1;
   endtask

   task next_wr_cycle();
      @(posedge clk_wr);
      #1;
   endtask

   // Latches current values of is_full and is_empty
   task refresh();
      write_en = 0;
      read_en = 0;
      next_rd_cycle();
      next_wr_cycle();
   endtask

   task PUSH(input [DATA_WIDTH-1:0] arg_data);
      refresh();
      `CHECK_EQUAL(is_full, 0); // Make sure it's not full
      data_in = arg_data;
      write_en = 1;
      next_wr_cycle();
      write_en = 0;
      refresh();
   endtask

   task ASSERT_POP(input [DATA_WIDTH-1:0] arg_expected);
      refresh();
      `CHECK_EQUAL(is_empty, 0); // Make sure it's not empty
      read_en = 1;
      next_rd_cycle();
      read_en = 0;
      `CHECK_EQUAL(arg_expected, data_out);
      refresh();
   endtask

   `TEST_SUITE begin
      `TEST_SUITE_SETUP begin
         rst = 1;
         next_rd_cycle();
         next_wr_cycle();
         rst = 0;

         `CHECK_EQUAL(is_empty, 1);
         `CHECK_EQUAL(is_full, 0);
      end
      `TEST_CASE("simple write read") begin
         PUSH('hAA);
         `CHECK_EQUAL(is_empty, 0);
         ASSERT_POP('hAA);
         `CHECK_EQUAL(is_empty, 1);
      end
      `TEST_CASE("full fifo") begin
         for (int i=0; i<FIFO_SIZE; i=i+1) begin
            PUSH(i);
            `CHECK_EQUAL(is_empty, 0);
            `CHECK_EQUAL(is_full, i == FIFO_SIZE-1);
         end
         for (int i=0; i<FIFO_SIZE; i=i+1) begin
            ASSERT_POP(i);
            `CHECK_EQUAL(is_empty, i == FIFO_SIZE-1);
            `CHECK_EQUAL(is_full, 0);
         end
      end
   end;
   `WATCHDOG(10ms);

   always begin
      #(clk_wr_period/2 * 1ns);
      clk_wr = !clk_wr;
   end

   always begin
      #(clk_rd_period/2 * 1ns);
      clk_rd = !clk_rd;
   end

   // Init module
   fifo
     #(
       .DATA_WIDTH(DATA_WIDTH),
       .ADDR_WIDTH(ADDR_WIDTH)
     ) fifo (
       // Read port
       .data_out(data_out),
       .empty_out(is_empty),
       .read_en_in(read_en),
       .read_clk(clk_rd),

      // Write port
      .data_in(data_in),
      .full_out(is_full),
      .write_en_in(write_en),
      .write_clk(clk_wr),

      .rst(rst)
     );
endmodule
