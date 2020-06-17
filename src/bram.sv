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
     /*
      * ADDI x14, x0, -1
      * ADDI x15, x0, 256
      * LB x1, 0(x15)
      * LB x2, 1(x15)
      * LB x3, 2(x15)
      * LB x4, 3(x15)
      * ADDI x6, x0, 5
      * wait_free_buff:
      * LB x5, 0(x14)
      * BLTU x5, x6, wait_free_buff
      * SB x1, 0(x14)
      * SB x2, 0(x14)
      * SB x3, 0(x14)
      * SB x4, 0(x14)
      * JAL x0, wait_free_buff
     { mem[0], mem[1], mem[2], mem[3] }     = 32'hfff00713;
		 { mem[4], mem[5], mem[6], mem[7] }     = 32'h10000793;
     { mem[8], mem[9], mem[10], mem[11] }   = 32'h00078083;
     { mem[12], mem[13], mem[14], mem[15] } = 32'h00178103;
     { mem[16], mem[17], mem[18], mem[19] } = 32'h00278183;
     { mem[20], mem[21], mem[22], mem[23] } = 32'h00378203;
     { mem[24], mem[25], mem[26], mem[27] } = 32'h00500313;
     { mem[28], mem[29], mem[30], mem[31] } = 32'h00070283;
     { mem[32], mem[33], mem[34], mem[35] } = 32'hfe62eee3;
     { mem[36], mem[37], mem[38], mem[39] } = 32'h00170023;
     { mem[40], mem[41], mem[42], mem[43] } = 32'h00270023;
     { mem[44], mem[45], mem[46], mem[47] } = 32'h00370023;
     { mem[48], mem[49], mem[50], mem[51] } = 32'h00470023;
     { mem[52], mem[53], mem[54], mem[55] } = 32'hfe9ff06f;
     // Data to send
     { mem[256], mem[257], mem[258], mem[259] } = 32'h41424344;
      */

     /*
      * ADDI x15, x0, -3 # 0xFFFFFFFD
      * ADDI x14, x0, -2 # 0xFFFFFFFE
      * ADDI x13, x0, -1 # 0xFFFFFFFF
      * poll:
      * LB x2, 0(x15)
      * BEQ x2, x0, poll
      * LB x3, 0(x14)
      * SB x3, 0(x13)
      * SB x0, 0(x13)
      * JAL x0, poll

     { mem[0], mem[1], mem[2], mem[3] }     = 32'hffd00793;
	  { mem[4], mem[5], mem[6], mem[7] }     = 32'hffe00713;
     { mem[8], mem[9], mem[10], mem[11] }   = 32'hfff00693;
     { mem[12], mem[13], mem[14], mem[15] } = 32'h00078103;
     { mem[16], mem[17], mem[18], mem[19] } = 32'hfe010ee3;
     { mem[20], mem[21], mem[22], mem[23] } = 32'h00070183;
     { mem[24], mem[25], mem[26], mem[27] } = 32'h00368023;
     { mem[28], mem[29], mem[30], mem[31] } = 32'h00068023;
     { mem[32], mem[33], mem[34], mem[35] } = 32'hfedff06f;
	        */
			  
		/*
		ADDI x15, x0, -3 # 0xFFFFFFFD
		ADDI x14, x0, -2 # 0xFFFFFFFE
		ADDI x13, x0, -1 # 0xFFFFFFFF
		ADDI x12, x0, 2
		poll1:
		LB x2, 0(x15)
		BEQ x2, x0, poll1
		LB x3, 0(x14)
		poll2:
		LB x2, 0(x13)
		BLTU x2, x12, poll2
		SB x3, 0(x13)
		SB x0, 0(x13)
		JAL x0, poll1
		*/
     { mem[0], mem[1], mem[2], mem[3] }     = 32'hffd00793;
	  { mem[4], mem[5], mem[6], mem[7] }     = 32'hffe00713;
     { mem[8], mem[9], mem[10], mem[11] }   = 32'hfff00693;
     { mem[12], mem[13], mem[14], mem[15] } = 32'h00200613;
     { mem[16], mem[17], mem[18], mem[19] } = 32'h00078103;
     { mem[20], mem[21], mem[22], mem[23] } = 32'hfe010ee3;
     { mem[24], mem[25], mem[26], mem[27] } = 32'h00070183;
     { mem[28], mem[29], mem[30], mem[31] } = 32'h00068103;
     { mem[32], mem[33], mem[34], mem[35] } = 32'hfec16ee3;
     { mem[36], mem[37], mem[38], mem[39] } = 32'h00368023;
     { mem[40], mem[41], mem[42], mem[43] } = 32'h00068023;
     { mem[44], mem[45], mem[46], mem[47] } = 32'hfe5ff06f;
	end

	 always @(posedge i_clk) begin
      if (i_write)
        mem[i_addr] <= i_data;
      else
        o_data <= mem[i_addr];
	 end
endmodule
