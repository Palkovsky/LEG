`include "vunit_defines.svh"
`include "funcs.svh"

`timescale 1ns/1ns

module memmap_tb;
   localparam integer clk_period = 10;
   reg                clk = 0;
   reg                rst = 0;

   // CPU bus
   reg [31:0]        cpu_addr = 0;
   // Writing
   reg [`DATA_WIDTH-1:0] cpu_data_out = 0;
   reg                   cpu_wr_valid = 0;
   wire                  cpu_wr_ready;
   logic [2:0]           cpu_wr_width = 0;
   // Reading
   wire [`DATA_WIDTH-1:0]  cpu_data_in;
   wire                    cpu_rd_valid;
   reg                     cpu_rd_ready = 0;

   // MMIO
   wire [31:0]        mmio_addr;
   // Writing
   wire [`DATA_WIDTH-1:0] mmio_data_out;
   wire                   mmio_wr_valid;
   reg                    mmio_wr_ready = 0;
   // Reading
   reg [`DATA_WIDTH-1:0]  mmio_data_in = 0;
   reg                    mmio_rd_valid = 0;
   wire                   mmio_rd_ready;

   // Control
   wire                   invalid_addr;

   task next_cycle();
      @(posedge clk);
      #1;
   endtask // next_cycle

   `TEST_SUITE begin
      `TEST_SUITE_SETUP begin
         #1;
      end
      `TEST_CASE("bram write bytes") begin
         cpu_addr = 'h10;
         cpu_data_out = 'hFFFFFF44;
         cpu_wr_width = 1;
         cpu_wr_valid = 1;
         wait(cpu_wr_ready);
         next_cycle();

         cpu_addr = 'h11;
         cpu_data_out = 'hFFFFFF33;
         wait(cpu_wr_ready);
         next_cycle();

         cpu_addr = 'h12;
         cpu_data_out = 'hFFFFFF22;
         wait(cpu_wr_ready);
         next_cycle();

         cpu_addr = 'h13;
         cpu_data_out = 'hFFFFFF11;
         wait(cpu_wr_ready);
         next_cycle();

         cpu_wr_valid = 0;
         cpu_rd_ready = 1;
         cpu_addr = 'h10;
         wait (cpu_rd_valid);
         #1;
         `CHECK_EQUAL(cpu_data_in, 32'h11223344);
      end
      `TEST_CASE("bram read bytes") begin
         cpu_addr = 'h10;
         cpu_data_out = 'h12345678;
         cpu_wr_width = 4;
         cpu_wr_valid = 1;
         wait(cpu_wr_ready);
         next_cycle();

         cpu_wr_valid = 0;
         cpu_rd_ready = 1;

         wait(cpu_rd_valid);
         `CHECK_EQUAL(cpu_data_in[7:0], 8'h78);

         cpu_addr = 'h11;
         next_cycle();
         wait(cpu_rd_valid);
         `CHECK_EQUAL(cpu_data_in[7:0], 8'h56);

         cpu_addr = 'h12;
         next_cycle();
         wait(cpu_rd_valid);
         `CHECK_EQUAL(cpu_data_in[7:0], 8'h34);

         cpu_addr = 'h13;
         next_cycle();
         wait(cpu_rd_valid);
         `CHECK_EQUAL(cpu_data_in[7:0], 8'h12);
      end
      `TEST_CASE("bram write halfwords") begin
         cpu_addr = 'h10;
         cpu_data_out = 'hFFFF3344;
         cpu_wr_width = 2;
         cpu_wr_valid = 1;
         wait(cpu_wr_ready);
         next_cycle();

         cpu_addr = 'h12;
         cpu_data_out = 'hFFFF1122;
         wait(cpu_wr_ready);
         next_cycle();

         cpu_wr_valid = 0;
         cpu_rd_ready = 1;
         cpu_addr = 'h10;
         wait (cpu_rd_valid);
         #1;
         `CHECK_EQUAL(cpu_data_in, 32'h11223344);
      end
      `TEST_CASE("bram read halfwords") begin
         cpu_addr = 'h10;
         cpu_data_out = 'h12345678;
         cpu_wr_width = 4;
         cpu_wr_valid = 1;
         wait(cpu_wr_ready);
         next_cycle();

         cpu_wr_valid = 0;
         cpu_rd_ready = 1;

         wait(cpu_rd_valid);
         `CHECK_EQUAL(cpu_data_in[15:0], 16'h5678);

         cpu_addr = 'h12;
         next_cycle();
         wait(cpu_rd_valid);
         `CHECK_EQUAL(cpu_data_in[15:0], 16'h1234);
      end
      `TEST_CASE("write and read MMIO") begin
         // vunit: .memmap
         `CHECK_EQUAL(mmio_addr, 0);
         `CHECK_EQUAL(mmio_data_out, 0);
         `CHECK_EQUAL(mmio_wr_ready, 0);
         `CHECK_EQUAL(cpu_wr_ready, 0);
         `CHECK_EQUAL(invalid_addr, 0);

         { cpu_addr, cpu_data_out, cpu_wr_valid } = { 32'hFFFFFFFF, 32'h21, 1'b1 };
         #1;
         `CHECK_EQUAL(mmio_addr, cpu_addr);
         `CHECK_EQUAL(mmio_data_out, cpu_data_out);
         `CHECK_EQUAL(mmio_wr_valid, 1);
         `CHECK_EQUAL(mmio_wr_ready, 1);
         `CHECK_EQUAL(cpu_wr_ready, 1);
         `CHECK_EQUAL(invalid_addr, 0);

         { cpu_addr, cpu_data_out, cpu_wr_valid } = 0;
         #1;
         `CHECK_EQUAL(mmio_addr, 0);
         `CHECK_EQUAL(mmio_data_out, 0);
         `CHECK_EQUAL(mmio_wr_ready, 0);
         `CHECK_EQUAL(cpu_wr_ready, 0);
         `CHECK_EQUAL(invalid_addr, 0);

         { cpu_addr, cpu_rd_ready } <= { 32'hFFFFFFFF, 1'b1 };
         #1;
         `CHECK_EQUAL(mmio_addr, cpu_addr);
         `CHECK_EQUAL(mmio_data_out, 0);
         `CHECK_EQUAL(mmio_wr_valid, 0);
         `CHECK_EQUAL(mmio_wr_ready, 0);
         `CHECK_EQUAL(cpu_wr_ready, 0);
         `CHECK_EQUAL(cpu_data_in, 32'h41);
         `CHECK_EQUAL(cpu_rd_valid, 1);
         `CHECK_EQUAL(invalid_addr, 0);
      end
      `TEST_CASE("write invalid addr") begin
         // vunit: .memmap
         `CHECK_EQUAL(invalid_addr, 0);

         { cpu_addr, cpu_data_out, cpu_wr_valid } = { 32'h88888888, 21, 1'b1 };
         #1;

         `CHECK_EQUAL(invalid_addr, 1);
         `CHECK_EQUAL(mmio_addr, 0);
         `CHECK_EQUAL(mmio_data_out, 0);
      end
   end;
   `WATCHDOG(10ms);

   always begin
      #(clk_period/2 * 1ns);
      clk = !clk;
   end

   memmap memmap
     (
      .i_clk(clk),
      .i_rst(rst),

      // CPU
      .i_cpu_addr(cpu_addr),
      .i_cpu_data(cpu_data_out),
      .i_wr_valid(cpu_wr_valid),
      .o_wr_ready(cpu_wr_ready),
      .i_wr_width(cpu_wr_width),
      .o_cpu_data(cpu_data_in),
      .o_rd_valid(cpu_rd_valid),
      .i_rd_ready(cpu_rd_ready),

      // MMIO
      .o_mmio_addr(mmio_addr),
      .i_mmio_data(mmio_data_in),
      .i_mmio_rd_valid(mmio_rd_valid),
      .o_mmio_rd_ready(mmio_rd_ready),
      .o_mmio_data(mmio_data_out),
      .o_mmio_wr_valid(mmio_wr_valid),
      .i_mmio_wr_ready(mmio_wr_ready),

      // Control
      .o_invalid_addr(invalid_addr)
      );

   // Mock MMIO interface
   always_comb begin
      { mmio_data_in, mmio_rd_valid, mmio_wr_ready } <= 0;

      case (mmio_addr[15:0])
        'hFFFF: begin
           if (mmio_wr_valid)
             mmio_wr_ready <= 1;
           if (mmio_rd_ready)
             { mmio_rd_valid, mmio_data_in } <= { 1'b1, 32'h41 };
        end
      endcase
   end
endmodule
