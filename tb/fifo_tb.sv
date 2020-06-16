`include "vunit_defines.svh"

module fifo_tb;
   localparam DATA_WIDTH = 8, ADDR_WIDTH = 4, FIFO_SIZE = (1<<ADDR_WIDTH);
   localparam integer clk_period = 15;

   reg                clk = 0;
   reg                rst = 0;

   reg [DATA_WIDTH-1:0] data_out;
   reg                  is_empty;

   reg [DATA_WIDTH-1:0]  data_in;
   reg                   is_full;

   reg                  write_en = 0, read_en = 0;


   task next_cycle();
      @(posedge clk);
      #1;
   endtask

   task PUSH(input [DATA_WIDTH-1:0] arg_data);
      `CHECK_EQUAL(is_full, 0); // Make sure it's not full
      data_in = arg_data;
      write_en = 1;
      next_cycle();
      write_en = 0;
   endtask

   task ASSERT_POP(input [DATA_WIDTH-1:0] arg_expected);
      `CHECK_EQUAL(is_empty, 0); // Make sure it's not empty
      read_en = 1;
      next_cycle();
      read_en = 0;
      `CHECK_EQUAL(data_out, data_out);
   endtask

   `TEST_SUITE begin
      `TEST_SUITE_SETUP begin
         rst = 1;
         next_cycle();
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
      #(clk_period/2 * 1ns);
      clk = !clk;
   end

   // Init module
   fifo
     #(
       .DATA_WIDTH(DATA_WIDTH),
       .ADDR_WIDTH(ADDR_WIDTH)
     ) fifo (
      .clk(clk),
      .rst(rst),

       // Read port
       .data_out(data_out),
       .empty_out(is_empty),
       .read_en_in(read_en),

      // Write port
      .data_in(data_in),
      .full_out(is_full),
      .write_en_in(write_en),

      .free()
    );
endmodule
