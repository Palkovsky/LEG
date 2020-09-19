`include "../tb/funcs.svh"

module bram #(
	DATA_WIDTH,
	ADDR_WIDTH
)(
  input                         i_clk,
  input [DATA_WIDTH/8-1:0][7:0] i_data,
  input [ADDR_WIDTH-1:0]        i_addr,
  input                         i_write,
  input [DATA_WIDTH/8-1:0]      i_byte_write_enable,
  output reg [DATA_WIDTH-1:0]   o_data
);
	 localparam
     RAM_SIZE=1<<ADDR_WIDTH;
   localparam WORD_BYTES = DATA_WIDTH / 8;

   reg [WORD_BYTES-1:0][7:0]    mem[0:RAM_SIZE-1];

	initial begin
     /*
      * # This program tests BRAM and MMIO transfers
      * 0: ADDI x14, x0, -1   # 0xFFFFFFFF - UART TX MMIO
      # Set x1=0x11223344
      * 1: LUI x1, 0x49505
      * 2: ADDI x1, x1, 0x152
      * # Store x1 under 0x00000100
      * 3: SW x1, 0x100(x0)
      * # Wait for TX FIFO to have enough space(4 bytes)
      * 4: ADDI x6, x0, 5
      * wait_free_buff:
      * 5: LB x5, 0(x14)
      * 6: BLTU x5, x6, wait_free_buff
      * # Load word from 0x00000100
      * 7: LW x2, 0x100(x0)
      * # Write 1st byte to UART
      * 8: SB x2, 0(x14)
      * 9: SRAI x2, x2, 8
      * # Write 2nd byte to UART
      * A: SB x2, 0(x14)
      * B: SRAI x2, x2, 8
      * # Write 3rd byte to UART
      * C: SB x2, 0(x14)
      * D: SRAI x2, x2, 8
      * # Write 4th byte to UART
      * E: SB x2, 0(x14)
      * F: JAL x0, wait_free_buff
     mem[00] = 32'hfff00713;
		 mem[01] = 32'h495050b7;
     mem[02] = 32'h15208093;
     mem[03] = 32'h10102023;
     mem[04] = 32'h00500313;
     mem[05] = 32'h00070283;
     mem[06] = 32'hfe62eee3;
     mem[07] = 32'h10002103;
     mem[08] = 32'h00270023;
     mem[09] = 32'h40815113;
     mem[10] = 32'h00270023;
     mem[11] = 32'h40815113;
     mem[12] = 32'h00270023;
     mem[13] = 32'h40815113;
     mem[14] = 32'h00270023;
     mem[15] = 32'hfd9ff06f;
     // Data
     mem[64] = 32'h41424344;
      */

    /*
     * Tests unaligned memory accesses.
     * Expected print order: 3, 4, 1, 2
     * # Base addrs
     * 0: ADDI x15, x0, -1
     * 1: ADDI x14, x0, 0x100
     * # x1='4321'
     * store:
     * 2: LUI x1, 0x34333
     * 3: ADDI x1, x1, 0x231
     * # Store x1 on addr 0x100
     * 4: SB x1, 0(x14)
     * 5: SRAI x1, x1, 8
     * 6: SB x1, 1(x14)
     * 7: SRAI x1, x1, 8
     * 8: SH x1, 2(x14)
     * load:
     * 9: LBU x1, 2(x14) # x1 = 'xxx3'
     * 10: SB x1, 0(x15)
     * 11: LBU x1, 3(x14) # x1 = 'xxx4'
     * 12: SB x1, 0(x15)
     * 13: LHU x1, 0(x14) # x1 = 'xx21'
     * 14: SB x1, 0(x15)
     * 15: SRAI x1, x1, 8
     * 16: SB x1, 0(x15)
     * 17: JAL store
     mem[00] = 32'hfff00793;
		 mem[01] = 32'h10000713;
     mem[02] = 32'h343330b7;
     mem[03] = 32'h23108093;
     mem[04] = 32'h00170023;
     mem[05] = 32'h4080d093;
     mem[06] = 32'h001700a3;
     mem[07] = 32'h4080d093;
     mem[08] = 32'h00171123;
     mem[09] = 32'h00274083;
     mem[10] = 32'h00178023;
     mem[11] = 32'h00374083;
     mem[12] = 32'h00178023;
     mem[13] = 32'h00075083;
     mem[14] = 32'h00178023;
     mem[15] = 32'h4080d093;
     mem[16] = 32'h00178023;
     mem[17] = 32'hfc5ff0ef;
     */

	  /*
     * # Echo with I/O wait.
     * 0: ADDI x14, x0, -2 # 0xFFFFFFFE
     * 1: ADDI x13, x0, -1 # 0xFFFFFFFF
     * echo:
     * # Read byte from RX
     * 2: LB x3, 0(x14) # This hangs, when there's no data.
     * # Write to TX FIFO
     * 3: SB x3, 0(x13) # This would hang if the FIFO was full.
     * 4: JAL x0, echo
	   mem[00] = 32'hffe00713;
	   mem[01] = 32'hfff00693;
     mem[02] = 32'h00070183;
     mem[03] = 32'h00368023;
     mem[04] = 32'hff9ff06f;
	  */

     /*
      * # Trying to overflow TX FIFO
      * # SB instruction should hang when trying to write to full FIFO
      * # therefore the overflow shouldn't happen.
	   * 0: ADDI x15, x0, -1
		* start:
		* 1: LUI x1, 0x31323
		* 2: ADDI x1, x1, 0x334
	   * send:
		* 3: SB x1, 0(x15)
		* 4: SRAI x1, x1, 8
		* 5: BEQ x1, x0, start
		* 6: JAL x0, send
     mem[00] = 32'hfff00793;
	   mem[01] = 32'h313230b7;
     mem[02] = 32'h33408093;
     mem[03] = 32'h00178023;
     mem[04] = 32'h4080d093;
     mem[05] = 32'hfe0088e3;
	   mem[06] = 32'hff5ff06f;
      */

     /*
      * Bootloader
      */
mem[0] = 'h00001137; // lui sp 0x1
mem[1] = 'h008000ef; // jal main
mem[2] = 'h0000006f; // j halt
mem[3] = 'hfe010113; // addi sp sp - 32
mem[4] = 'h00112e23; // sw ra sp 28
mem[5] = 'h00812c23; // sw s0 sp 24
mem[6] = 'h00912a23; // sw s1 sp 20
mem[7] = 'h01212823; // sw s2 sp 16
mem[8] = 'h01312623; // sw s3 sp 12
mem[9] = 'h0bb00513; // addi a0 zero 187
mem[10] = 'hfea00823; // sb a0 zero - 16
mem[11] = 'hfea008a3; // sb a0 zero - 15
mem[12] = 'hff200593; // addi a1 zero - 14
mem[13] = 'h00a58023; // sb a0 a1 0
mem[14] = 'h02000993; // addi s3 zero 32
mem[15] = 'h01000913; // addi s2 zero 16
mem[16] = 'h03c0006f; // j .lbb0_2
mem[17] = 'hfe000823; // sb zero zero - 16
mem[18] = 'hfe0008a3; // sb zero zero - 15
mem[19] = 'hfe000923; // sb zero zero - 14
mem[20] = 'hffe04503; // lbu a0 zero - 2
mem[21] = 'hffe04583; // lbu a1 zero - 2
mem[22] = 'hffe04603; // lbu a2 zero - 2
mem[23] = 'h00859593; // slli a1 a1 8
mem[24] = 'hffe00683; // lb a3 zero - 2
mem[25] = 'h00b56533; // or a0 a0 a1
mem[26] = 'h01061593; // slli a1 a2 16
mem[27] = 'h00b56533; // or a0 a0 a1
mem[28] = 'h01869593; // slli a1 a3 24
mem[29] = 'h00b56533; // or a0 a0 a1
mem[30] = 'h000500e7; // jalr a0
mem[31] = 'hffe04503; // lbu a0 zero - 2
mem[32] = 'hfd3502e3; // beq a0 s3 .lbb0_1
mem[33] = 'hff251ce3; // bne a0 s2 .lbb0_2
mem[34] = 'hfe0008a3; // sb zero zero - 15
mem[35] = 'hffe04503; // lbu a0 zero - 2
mem[36] = 'hffe04583; // lbu a1 zero - 2
mem[37] = 'hffe04603; // lbu a2 zero - 2
mem[38] = 'h00859593; // slli a1 a1 8
mem[39] = 'h00b56533; // or a0 a0 a1
mem[40] = 'h01061593; // slli a1 a2 16
mem[41] = 'h00b56733; // or a4 a0 a1
mem[42] = 'hffe00783; // lb a5 zero - 2
mem[43] = 'hffe04483; // lbu s1 zero - 2
mem[44] = 'hffe04403; // lbu s0 zero - 2
mem[45] = 'hffe04503; // lbu a0 zero - 2
mem[46] = 'hffe04583; // lbu a1 zero - 2
mem[47] = 'hffe04803; // lbu a6 zero - 2
mem[48] = 'hffe04683; // lbu a3 zero - 2
mem[49] = 'hffe04283; // lbu t0 zero - 2
mem[50] = 'hffe00883; // lb a7 zero - 2
mem[51] = 'h01879793; // slli a5 a5 24
mem[52] = 'h00f76733; // or a4 a4 a5
mem[53] = 'h06070063; // beqz a4 .lbb0_7
mem[54] = 'h00000793; // mv a5 zero
mem[55] = 'h00841413; // slli s0 s0 8
mem[56] = 'h0084e4b3; // or s1 s1 s0
mem[57] = 'h01051513; // slli a0 a0 16
mem[58] = 'h00956533; // or a0 a0 s1
mem[59] = 'h01859593; // slli a1 a1 24
mem[60] = 'h00b564b3; // or s1 a0 a1
mem[61] = 'hffe04503; // lbu a0 zero - 2
mem[62] = 'hffe04583; // lbu a1 zero - 2
mem[63] = 'hffe04403; // lbu s0 zero - 2
mem[64] = 'h00859593; // slli a1 a1 8
mem[65] = 'hffe00603; // lb a2 zero - 2
mem[66] = 'h00b56533; // or a0 a0 a1
mem[67] = 'h01041593; // slli a1 s0 16
mem[68] = 'h00b56533; // or a0 a0 a1
mem[69] = 'h01861593; // slli a1 a2 24
mem[70] = 'h00b56533; // or a0 a0 a1
mem[71] = 'h00a7c7b3; // xor a5 a5 a0
mem[72] = 'h00a4a023; // sw a0 s1 0
mem[73] = 'hfff70713; // addi a4 a4 - 1
mem[74] = 'h00448493; // addi s1 s1 4
mem[75] = 'hfc0714e3; // bnez a4 .lbb0_6
mem[76] = 'h0080006f; // j .lbb0_8
mem[77] = 'h00000793; // mv a5 zero
mem[78] = 'h00869513; // slli a0 a3 8
mem[79] = 'h01056533; // or a0 a0 a6
mem[80] = 'h01029593; // slli a1 t0 16
mem[81] = 'h00b56533; // or a0 a0 a1
mem[82] = 'h01889593; // slli a1 a7 24
mem[83] = 'h00a5e5b3; // or a1 a1 a0
mem[84] = 'h00100513; // addi a0 zero 1
mem[85] = 'h00b78463; // beq a5 a1 .lbb0_10
mem[86] = 'h00200513; // addi a0 zero 2
mem[87] = 'hfea00fa3; // sb a0 zero - 1
mem[88] = 'hf1dff06f; // j .lbb0_2
  end

  always @(posedge i_clk) begin
     o_data <= mem[i_addr];
     if (i_write) begin
        if (i_byte_write_enable[0]) begin
           mem[i_addr][0] <= i_data[0];
        end
        if (i_byte_write_enable[1]) begin
           mem[i_addr][1] <= i_data[1];
        end
        if (i_byte_write_enable[2]) begin
           mem[i_addr][2] <= i_data[2];
        end
        if (i_byte_write_enable[3]) begin
           mem[i_addr][3] <= i_data[3];
        end
     end
  end
endmodule

// Wrapper for bram with support of ready/valid protocol.
module bram_rv #(
 DATA_WIDTH,
 ADDR_WIDTH
)(
  input                          i_clk,
  input                          i_rst,
  input [ADDR_WIDTH-1:0]         i_addr,

  input [DATA_WIDTH-1:0]         i_data,
  input                          i_wr_valid,
  output reg                     o_wr_ready,

  output reg [DATA_WIDTH-1:0]    o_data,
  output reg                     o_rd_valid,
  input                          i_rd_ready,
  input logic [DATA_WIDTH/8-1:0] i_byte_write_enable
);

   reg [DATA_WIDTH-1:0]  bram_data_in;
   reg                   bram_write;
   wire [DATA_WIDTH-1:0] bram_data_out;

   reg                   reading = 0;

   always_comb begin
      { bram_write, o_wr_ready, bram_data_in, o_rd_valid, o_data } <= 0;

      if (i_wr_valid)
         { bram_write, o_wr_ready, bram_data_in } <= { 1'b1, 1'b1, i_data };
      else if (reading)
        { o_rd_valid, o_data } <= { 1'b1, bram_data_out };
   end

   always @(posedge i_clk) begin
      if (i_rst)
        reading <= 0;
      else
        reading <= (i_rd_ready && !reading);
   end

   bram
     #(
       .DATA_WIDTH(DATA_WIDTH),
       .ADDR_WIDTH(ADDR_WIDTH)
      ) bram
      (
       .i_clk(i_clk),
       .i_data(bram_data_in),
       .i_addr(i_addr),
       .i_write(bram_write),
       .i_byte_write_enable(i_byte_write_enable),
       .o_data(bram_data_out)
      );
endmodule
