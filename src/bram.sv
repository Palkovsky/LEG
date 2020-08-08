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
      # Vector load test
      0: addi x1, x0, 16
      4: lv v0, x1, 16
      8: sv v0, x1, 32
      12: lv v1, x1, 16
      16: jal x0, 2
      32: dh 0000h 1111h 2222h 3333h 4444h 5555h ...
     mem[0] = 'h01000093;
     mem[1] = 'h0100900B;
     mem[2] = 'h0200A00B;
     mem[3] = 'h0100908B;
     // Position-indepenednt loop
     mem[4] = 'h0000006f;
     // Data
     mem[8] = 'h11110000;
     mem[9] = 'h33332222;
     mem[10] = 'h55554444;
     mem[11] = 'h77776666;
     mem[12] = 'h99998888;
     mem[13] = 'hBBBBAAAA;
     mem[14] = 'hDDDDCCCC;
     mem[15] = 'hFFFFEEEE;
    */

mem[0] = 'hfff00793; // addi x15 x0 - 1
mem[1] = 'h1000100b; // lv v0 x0 ascii
mem[2] = 'h1200200b; // sv v0 x0 ascii_cpy
mem[3] = 'h12002083; // lw x1 x0 ascii_cpy
mem[4] = 'h0400076f; // jal x14 send_x1
mem[5] = 'h12402083; // lw x1 x0 ascii_cpy + 4
mem[6] = 'h0380076f; // jal x14 send_x1
mem[7] = 'h12802083; // lw x1 x0 ascii_cpy + 8
mem[8] = 'h0300076f; // jal x14 send_x1
mem[9] = 'h12c02083; // lw x1 x0 ascii_cpy + 12
mem[10] = 'h0280076f; // jal x14 send_x1
mem[11] = 'h13002083; // lw x1 x0 ascii_cpy + 16
mem[12] = 'h0200076f; // jal x14 send_x1
mem[13] = 'h13402083; // lw x1 x0 ascii_cpy + 20
mem[14] = 'h0180076f; // jal x14 send_x1
mem[15] = 'h13802083; // lw x1 x0 ascii_cpy + 24
mem[16] = 'h0100076f; // jal x14 send_x1
mem[17] = 'h13c02083; // lw x1 x0 ascii_cpy + 28
mem[18] = 'h0080076f; // jal x14 send_x1
mem[19] = 'h0000006f; // jal x0 hang
mem[20] = 'h00178023; // sb x1 x15 0
mem[21] = 'h4080d093; // srai x1 x1 8
mem[22] = 'h00178023; // sb x1 x15 0
mem[23] = 'h4080d093; // srai x1 x1 8
mem[24] = 'h00178023; // sb x1 x15 0
mem[25] = 'h4080d093; // srai x1 x1 8
mem[26] = 'h00178023; // sb x1 x15 0
mem[27] = 'h00070067; // jalr x0 x14 0
mem[64] = 'h41424344; // dw 0x41424344
mem[65] = 'h45464748; // dw 0x45464748
mem[66] = 'h494a4b4c; // dw 0x494a4b4c
mem[67] = 'h4d4e4f50; // dw 0x4d4e4f50
mem[68] = 'h51525354; // dw 0x51525354
mem[69] = 'h55565758; // dw 0x55565758
mem[70] = 'h595a3132; // dw 0x595a3132
mem[71] = 'h33343536; // dw 0x33343536
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
