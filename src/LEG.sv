module LEG(
  input        i_clk,
  input        i_rst,

  // UART
  input        rx,
  output       tx,

  // 7-segment displays
  output [6:0] o_d1,
  output [6:0] o_d2,
  output [6:0] o_d3,
  output [6:0] o_d4,
  output [6:0] o_d5,
  output [6:0] o_d6,

  // Error signals
  output       o_invalid_inst,
  output       o_invalid_addr
);

   wire        pll_clk;
   pll pll (.areset(i_rst), .inclk0(i_clk), .c0(pll_clk), .locked());

   cpu cpu
     (
      .i_clk(pll_clk),
      .i_rst(i_rst),
      // UART
      .rx(rx),
      .tx(tx),
      // 7-segment displays
      .o_d1(o_d1),
      .o_d2(o_d2),
      .o_d3(o_d3),
      .o_d4(o_d4),
      .o_d5(o_d5),
      .o_d6(o_d6),
      // Error signals
      .o_invalid_inst(o_invalid_inst),
      .o_invalid_addr(o_invalid_addr)
     );
endmodule
