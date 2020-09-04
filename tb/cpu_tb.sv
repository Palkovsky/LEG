`include "vunit_defines.svh"
`include "funcs.svh"

`timescale 1ns/1ns

module cpu_tb;
   localparam integer clk_period = 10;

   reg                clk = 0;
   reg                rst = 0;

   reg                rx = 0;
   wire               tx;

   wire               invalid_inst;
   wire               invalid_addr;

   task next_cycle();
      @(posedge clk);
      #1;
   endtask

   `TEST_SUITE begin
      `TEST_CASE("top") begin
         // vunit: .top
         // CMD: python test.py --with-attribute .top --gui
         for (int i=0; i<100000; i++) begin
            next_cycle();
         end
      end
   end;

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
      .rx(rx),
      .tx(tx),
      // Error signals
      .o_invalid_inst(invalid_inst),
      .o_invalid_addr(invalid_addr)
     );
endmodule
