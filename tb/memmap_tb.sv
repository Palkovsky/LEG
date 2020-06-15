`include "vunit_defines.svh"
`include "funcs.svh"

`timescale 1ns/1ns

module memmap_tb;
   localparam integer clk_period = 10;
   reg                clk = 0;
   reg                rst = 0;

   reg [31:0]         cpu_addr = 0;
   reg [`DATA_WIDTH-1:0] cpu_data_out = 0;
   reg [`DATA_WIDTH-1:0]  cpu_data_in;
   reg                    cpu_write = 0;

   reg [`DATA_WIDTH-1:0]  bram_data_in;
   reg                    bram_write;
   reg [`DATA_WIDTH-1:0]  bram_data_out;
   reg [31:0]             bram_addr;

   reg [`DATA_WIDTH-1:0]  fifo_data_out;
   reg                    fifo_empty;
   reg                    fifo_read_enabled = 0;

   reg [`DATA_WIDTH-1:0]  fifo_data_in;
   reg                    fifo_full;
   reg                    fifo_write_enabled;

   wire                   invalid_addr;

   wire [`BRAM_WIDTH-1:0] bram_addr_low = bram_addr[`BRAM_WIDTH-1:0];

   task next_cycle();
      @(posedge clk);
      #1;
   endtask

   `TEST_SUITE begin
      `TEST_SUITE_SETUP begin
         rst = 1;
         next_cycle();
         rst = 0;
      end
      `TEST_CASE("write and read BRAM") begin
         cpu_addr = 'h100;
         cpu_data_out = 44;
         cpu_write = 1;

         #1;
         `CHECK_EQUAL(bram_addr, cpu_addr);
         `CHECK_EQUAL(bram_write, cpu_write);
         `CHECK_EQUAL(bram_data_in, cpu_data_out);
         `CHECK_EQUAL(fifo_write_enabled, 0);
         `CHECK_EQUAL(fifo_data_in, 0);
         `CHECK_EQUAL(invalid_addr, 0);
         `CHECK_EQUAL(cpu_data_in, 0);
         next_cycle();
         `CHECK_EQUAL(cpu_data_in, 0);

         // Read data
         cpu_write = 0;

         #1;
         `CHECK_EQUAL(bram_addr, cpu_addr);
         `CHECK_EQUAL(bram_write, cpu_write);
         `CHECK_EQUAL(bram_data_in, cpu_data_out);
         `CHECK_EQUAL(fifo_write_enabled, 0);
         `CHECK_EQUAL(fifo_data_in, 0);
         `CHECK_EQUAL(invalid_addr, 0);

         next_cycle();
         `CHECK_EQUAL(cpu_data_in, 44);
      end
      `TEST_CASE("write and read FIFO") begin
         cpu_addr = 32'hFFFFFFFF;
         cpu_data_out = 44;
         cpu_write = 1;

         #1
         `CHECK_EQUAL(bram_addr, 0);
         `CHECK_EQUAL(bram_write, 0);
         `CHECK_EQUAL(bram_data_in, 0);
         `CHECK_EQUAL(fifo_write_enabled, 1);
         `CHECK_EQUAL(fifo_data_in, 44);
         `CHECK_EQUAL(invalid_addr, 0);
         `CHECK_EQUAL(fifo_empty, 1);
         next_cycle();
         `CHECK_EQUAL(fifo_full, 0);
         cpu_write = 0;

         #1
         `CHECK_EQUAL(bram_addr, 0);
         `CHECK_EQUAL(bram_write, 0);
         `CHECK_EQUAL(bram_data_in, 0);
         `CHECK_EQUAL(fifo_write_enabled, 0);
         `CHECK_EQUAL(fifo_data_in, 0);
         `CHECK_EQUAL(invalid_addr, 0);

         // Try reading from FIFO
         fifo_read_enabled = 1;
         next_cycle();
         `CHECK_EQUAL(fifo_data_out, 44);
         `CHECK_EQUAL(fifo_empty, 1);
      end
      `TEST_CASE("write invalid addr") begin
         cpu_addr = 32'h7FFFFFFF;
         cpu_data_out = 68;
         cpu_write = 1;
         `CHECK_EQUAL(invalid_addr, 0);
         #1
         `CHECK_EQUAL(invalid_addr, 1);
      end
   end;
   `WATCHDOG(10ms);

   always begin
      #(clk_period/2 * 1ns);
      clk = !clk;
   end

   bram
     #(
       .DATA_WIDTH(`DATA_WIDTH),
       .ADDR_WIDTH(`BRAM_WIDTH)
     ) bram
     (
      .i_clk(clk),
      .i_data(bram_data_in),
      .i_addr(bram_addr_low),
      .i_write(bram_write),
      .o_data(bram_data_out)
     );

   fifo
     #(
       .DATA_WIDTH(`DATA_WIDTH),
       .ADDR_WIDTH(4)
       ) fifo
       (
        .clk(clk),
        .rst(rst),

        // Read port
        .data_out(fifo_data_out),
        .empty_out(fifo_empty),
        .read_en_in(fifo_read_enabled),

        // Write port
        .data_in(fifo_data_in),
        .full_out(fifo_full),
        .write_en_in(fifo_write_enabled)
       );

   memmap memmap
     (
      // CPU interface
      .cpu_addr(cpu_addr),
      .cpu_write(cpu_write),
      .cpu_data_in(cpu_data_in),
      .cpu_data_out(cpu_data_out),

      // BRAM interface
      .bram_addr(bram_addr),
      .bram_write(bram_write),
      .bram_data_in(bram_data_in),
      .bram_data_out(bram_data_out),

      // FIFO write
      .fifo_data_in(fifo_data_in),
      .fifo_full(fifo_full),
      .fifo_write_enabled(fifo_write_enabled),

      // Control signals
      .invalid_addr(invalid_addr)
     );
endmodule
