`include "vunit_defines.svh"
`include "funcs.svh"

`timescale 1ns/1ns

module uartwriter_tb;
   localparam integer clk_period = 15;
   reg                clk = 0;
   reg                rst = 0;

   reg                rx, tx;

   reg [`DATA_WIDTH-1:0] fifo_data = 0;
   reg                   fifo_empty = 1;
   reg                   fifo_read_enabled;

   task next_cycle();
      @(posedge clk);
      #1;
   endtask

   `TEST_SUITE begin
      `TEST_SUITE_SETUP begin
         rst = 1;
         next_cycle();
         rst = 0;
         `CHECK_EQUAL(writer.state, writer.IDLE);
         `CHECK_EQUAL(writer.transmitting, 0);
      end
      `TEST_CASE("idling") begin
         fifo_data = 0;
         fifo_empty = 1;
         `CHECK_EQUAL(fifo_read_enabled, 0);
         next_cycle();
         `CHECK_EQUAL(fifo_read_enabled, 0);
         `CHECK_EQUAL(writer.state, writer.IDLE);
         `CHECK_EQUAL(writer.transmitting, 0);
         next_cycle();
         `CHECK_EQUAL(fifo_read_enabled, 0);
         `CHECK_EQUAL(writer.state, writer.IDLE);
         `CHECK_EQUAL(writer.transmitting, 0);
      end
      `TEST_CASE("byte transmit") begin
         fifo_data = 'hAA;
         fifo_empty = 0;

         `CHECK_EQUAL(fifo_read_enabled, 0);
         `CHECK_EQUAL(writer.state, writer.IDLE);
         `CHECK_EQUAL(writer.transmitting, 0);

         next_cycle();
         fifo_empty = 1;

         `CHECK_EQUAL(fifo_read_enabled, 1);
         `CHECK_EQUAL(writer.state, writer.FETCHING);
         `CHECK_EQUAL(writer.transmit_byte, 0);
         `CHECK_EQUAL(writer.transmit, 0);
         `CHECK_EQUAL(writer.transmitting, 0);

         next_cycle();

         `CHECK_EQUAL(fifo_read_enabled, 0);
         `CHECK_EQUAL(writer.state, writer.SEND_START_WAIT);
         `CHECK_EQUAL(writer.transmit_byte, 'hAA);
         `CHECK_EQUAL(writer.transmit, 1);
         `CHECK_EQUAL(writer.transmitting, 0);

         wait(writer.transmitting == 1);
         next_cycle();
         `CHECK_EQUAL(fifo_read_enabled, 0);
         `CHECK_EQUAL(writer.state, writer.SENDING);
         `CHECK_EQUAL(writer.transmit_byte, 'hAA);
         `CHECK_EQUAL(writer.transmit, 0);
         `CHECK_EQUAL(writer.transmitting, 1);

         wait(writer.transmitting == 0);
         next_cycle();
         `CHECK_EQUAL(fifo_read_enabled, 0);
         `CHECK_EQUAL(writer.state, writer.IDLE);
         `CHECK_EQUAL(writer.transmit_byte, 0);
         `CHECK_EQUAL(writer.transmit, 0);
         `CHECK_EQUAL(writer.transmitting, 0);
      end
   end;
   `WATCHDOG(10ms);

   always begin
      #(clk_period/2 * 1ns);
      clk = !clk;
   end

   uartwriter writer
     (
      .clk(clk),
      .rst(rst),
      .rx(rx),
      .tx(tx),
      .fifo_empty(fifo_empty),
      .fifo_data(fifo_data),
      .fifo_read_en(fifo_read_enabled)
    );
endmodule
