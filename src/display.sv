module display_controller
  (
   input [7:0] i_regs [2:0],
   output [6:0] o_d1,
   output [6:0] o_d2,
   output [6:0] o_d3,
   output [6:0] o_d4,
   output [6:0] o_d5,
   output [6:0] o_d6
  );

   hex_to_7_segment d1
     (
      .i_nibble(i_regs[0][7:4]),
      .o_encoded(o_d6)
     );

   hex_to_7_segment d2
     (
      .i_nibble(i_regs[0][3:0]),
      .o_encoded(o_d5)
      );

   hex_to_7_segment d3
     (
      .i_nibble(i_regs[1][7:4]),
      .o_encoded(o_d4)
     );

   hex_to_7_segment d4
     (
      .i_nibble(i_regs[1][3:0]),
      .o_encoded(o_d3)
     );

   hex_to_7_segment d5
     (
      .i_nibble(i_regs[2][7:4]),
      .o_encoded(o_d2)
     );

   hex_to_7_segment d6
     (
      .i_nibble(i_regs[2][3:0]),
      .o_encoded(o_d1)
     );
endmodule

module hex_to_7_segment
  (
   input [3:0]  i_nibble,
   output [6:0] o_encoded
  );

   reg [6:0]    w_encoded;
   assign o_encoded = ~w_encoded;

   always_comb begin
      case (i_nibble)
        4'b0000:    // 0
          w_encoded <= 7'b0111111;
        4'b0001:    // 1
          w_encoded <= 7'b0110000;
        4'b0010:  	// 2
          w_encoded <= 7'b1011011;
        4'b0011: 		// 3
          w_encoded <= 7'b1001111;
        4'b0100:		// 4
          w_encoded <= 7'b1100110;
        4'b0101:		// 5
          w_encoded <= 7'b1101101;
        4'b0110:		// 6
          w_encoded <= 7'b1111101;
        4'b0111:		// 7
          w_encoded <= 7'b0000111;
        4'b1000:    // 8
          w_encoded <= 7'b1111111;
        4'b1001:    // 9
          w_encoded <= 7'b1101111;
        4'b1010:  	// A
          w_encoded <= 7'b1110111;
        4'b1011: 		// B
          w_encoded <= 7'b1111100;
        4'b1100:		// C
          w_encoded <= 7'b0111001;
        4'b1101:		// D
          w_encoded <= 7'b1011110;
        4'b1110:		// E
          w_encoded <= 7'b1111001;
        4'b1111:		// F
          w_encoded <= 7'b1110001;
      endcase
   end
endmodule
