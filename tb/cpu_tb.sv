`include "vunit_defines.svh"
`include "funcs.svh"

`timescale 1ns/1ns

module cpu_tb;
   localparam integer clk_period = 40; // 25MHz

   reg                clk = 0;
   reg                rst = 0;

   reg                rx_cpu = 0;
   wire               tx_cpu;

   wire               invalid_inst;
   wire               invalid_addr;

   // Interface to UART inside the CPU
   reg [7:0]          tx_byte = 0;
   reg                tx_valid = 0;
   wire               tx_ack;
   wire               rx_received;
   wire [7:0]         rx_byte;

   task uart_send(input[7:0] b);
      tx_byte = b;
      tx_valid = 1;
      #1;
      wait(tx_ack == 1);
      tx_valid = 0;
      #1;
      wait(leg.uart.rx_received == 1); // wait for cpu to read
      #1;
   endtask

   task uart_recv(output int b);
      #1;
      wait(rx_received == 1);
      #1;
      b = rx_byte;
      #1;
   endtask


   task next_cycle();
      @(posedge clk);
      #1;
   endtask

   `TEST_SUITE begin
      `TEST_CASE("top") begin
         // vunit: .top
         // CMD: python test.py --with-attribute .top --gui
         for (int i=0; i<1000000; i++) begin
            next_cycle();
         end
      end
   end;



   // Simulate programmer
   int       recv;
   initial begin
      uart_send('h10); // CMD_LOAD
      uart_send(1);  // size=1
      uart_send(0);
      uart_send(0);
      uart_send(0);
      uart_send(0);  // addr=0x400
      uart_send(4);
      uart_send(0);
      uart_send(0);
      uart_send('hEF);  // checksum=(same as data for size=1)
      uart_send('hBE);
      uart_send('hAD);
      uart_send('hDE);
      uart_send('hEF);  // data=0xdeadbeef
      uart_send('hBE);
      uart_send('hAD);
      uart_send('hDE);
      uart_recv(recv);  // read status
      if (recv == 1) begin
         uart_send('h20); // CMD_START
         uart_send(0);  // addr=0x00000400
         uart_send(4);
         uart_send(0);
         uart_send(0);
      end
      wait(leg.core.pc > 'h400);
      rst = 1;
      @(posedge clk);
      #1;
      rst = 0;
   end

	 // Clock generator
   always begin
      #(clk_period/2 * 1ns);
      clk = !clk;
   end

   cpu leg
     (
      .i_clk(clk),
      .i_rst(rst),
      // UART
      .rx(rx_cpu),
      .tx(tx_cpu),
      // Error signals
      .o_invalid_inst(invalid_inst),
      .o_invalid_addr(invalid_addr)
     );

   // Simulate UART on the other side.
   uart uart
     (
      .clk(clk),
      .rst(rst),

      .txd(rx_cpu),
      .tx_data(tx_byte),
      .tx_data_valid(tx_valid),
      .tx_data_ack(tx_ack),

      .rxd(tx_cpu),
      .rx_data_fresh(rx_received),
      .rx_data(rx_byte)
    );
endmodule
