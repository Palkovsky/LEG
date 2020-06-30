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
      `TEST_CASE("write and read BRAM") begin
         // vunit: .memmap
         { cpu_addr, cpu_data_out, cpu_wr_valid } = { 32'h500, 32'h21, 1'b1 };
         wait (cpu_wr_ready);
         next_cycle();
         { cpu_wr_valid, cpu_rd_ready } = { 1'b0, 1'b1 };
         wait (cpu_rd_valid);
         #1;
         `CHECK_EQUAL(cpu_data_in, 32'h21);
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
