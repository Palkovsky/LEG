`include "../tb/funcs.svh"

module bram #(
	DATA_WIDTH,
	ADDR_WIDTH
)(
	input                       i_clk,
  input [DATA_WIDTH-1:0]      i_data,
  input [ADDR_WIDTH-1:0]      i_addr,
  input                       i_write,
  output reg [DATA_WIDTH-1:0] o_data
);
	localparam RAM_SIZE=1<<ADDR_WIDTH;

   reg [DATA_WIDTH-1:0]       mem[0:RAM_SIZE-1];

	initial begin
     // TODO: Macro for BRAM initialization
		 for (int i=0; i<RAM_SIZE; i++) begin
			  mem[i] = 0;
		 end
		 // ADDI x1, x0, 65 | 32'h04100093
		 // { mem[0], mem[1], mem[2], mem[3] } = IMM_OP(1, 0, "+", 65);
		 // ADDI x2, x0, -1 | 32'hfff00113
		 // { mem[4], mem[5], mem[6], mem[7] } = IMM_OP(2, 0, "+", 'hFFF);
		 // SB x1, 0(x2) | 32'h00110023
		 // { mem[8], mem[9], mem[10], mem[11] } = S(`STORE, `SB, 2, 0, 1);
		 // JAL x0, -4 | 32'hffdff06f
		 //{ mem[12], mem[13], mem[14], mem[15] } =  32'hffdff06f;

     // ADDI x1, x0, 256
     { mem[0], mem[1], mem[2], mem[3] }     = 32'h10000093;
     // LB x2, 0(x1)
		 { mem[4], mem[5], mem[6], mem[7] }     = 32'h00008103;
     // LB x3, 1(x1)
     { mem[8], mem[9], mem[10], mem[11] }   = 32'h00108183;
     // LB x4, 2(x1)
     { mem[12], mem[13], mem[14], mem[15] } = 32'h00208203;
     // LB x5, 3(x1)
     { mem[16], mem[17], mem[18], mem[19] } = 32'h00308283;
     // ADDI x1, x0, -1
     { mem[20], mem[21], mem[22], mem[23] } = 32'hfff00093;
     // tu:
     // SB x2, 0(x1)
     { mem[24], mem[25], mem[26], mem[27] } = 32'h00208023;
     // SB x3, 0(x1)
     { mem[28], mem[29], mem[30], mem[31] } = 32'h00308023;
     // SB x4, 0(x1)
     { mem[32], mem[33], mem[34], mem[35] } = 32'h00408023;
     // SB x5, 0(x1)
     { mem[36], mem[37], mem[38], mem[39] } = 32'h00508023;
     // JAL x0, tu
     { mem[40], mem[41], mem[42], mem[43] } = 32'hff1ff06f;

     { mem[256], mem[257], mem[258], mem[259] } = 32'h41424344;
	end

	 always @(posedge i_clk) begin
      if (i_write)
        mem[i_addr] <= i_data;
      else
        o_data <= mem[i_addr];
	 end
endmodule
