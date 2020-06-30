`include "vunit_defines.svh"
`include "funcs.svh"

`timescale 1ns/1ns
module uartwriter_tb;
   localparam integer clk_period = 15;
   reg                clk = 0;
   reg                rst = 0;

   reg                rx = 1, tx;

   reg [7:0]             uart_in;
   reg                   uart_wr_valid;
   wire                  uart_wr_ready;
   wire [`TX_FIFO_DEPTH:0] uart_tx_free;

   wire                    uart_rx_present;
   wire [7:0]              uart_out;
   wire                    uart_rd_valid;
   reg                     uart_rd_ready;

   task next_cycle();
      @(posedge clk);
      #1;
   endtask

   `TEST_SUITE begin
      `TEST_CASE("uart top") begin
         // vunit: .uart
         for (int i=0; i<100; i++) begin
            next_cycle();
         end
      end
   end;
   `WATCHDOG(10ms);

   always begin
      #(clk_period/2 * 1ns);
      clk = !clk;
   end

   uartwriter #(.TX_FIFO_DEPTH(`TX_FIFO_DEPTH))
   writer
     (
      .i_clk(clk),
      .i_rst(rst),

      .i_rx(rx),
      .o_tx(tx),

      .i_data_in(uart_in),
      .i_wr_valid(uart_wr_valid),
      .o_wr_ready(uart_wr_ready),
      .o_tx_free(uart_tx_free),

      .o_rx_present(uart_rx_present),
      .o_data_out(uart_out),
      .o_rd_valid(uart_rd_valid),
      .i_rd_ready(uart_rd_ready)
    );
endmodule
