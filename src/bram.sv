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
mem[0] = 'h000020b7; // lui x1 2
mem[1] = 'h0000910b; // lv v2 x1 l0 - data + 0
mem[2] = 'h0200918b; // lv v3 x1 l0 - data + 32
mem[3] = 'h0400920b; // lv v4 x1 l0 - data + 64
mem[4] = 'h0600928b; // lv v5 x1 l0 - data + 96
mem[5] = 'h0800930b; // lv v6 x1 l0 - data + 128
mem[6] = 'h0a00938b; // lv v7 x1 l0 - data + 160
mem[7] = 'h0c00940b; // lv v8 x1 l0 - data + 192
mem[8] = 'h0e00948b; // lv v9 x1 l0 - data + 224
mem[9] = 'h1200950b; // lv v10 x1 l1 - data + 0
mem[10] = 'h1600960b; // lv v12 x1 l1 - data + 64
mem[11] = 'h1400958b; // lv v11 x1 l1 - data + 32
mem[12] = 'h1800968b; // lv v13 x1 l1 - data + 96
mem[13] = 'h1a00970b; // lv v14 x1 l1 - data + 128
mem[14] = 'h1c00978b; // lv v15 x1 l1 - data + 160
mem[15] = 'h1e00980b; // lv v16 x1 l1 - data + 192
mem[16] = 'h2000988b; // lv v17 x1 l1 - data + 224
mem[17] = 'h2400990b; // lv v18 x1 l2 - data + 0
mem[18] = 'h2600998b; // lv v19 x1 l2 - data + 32
mem[19] = 'h28009a0b; // lv v20 x1 l2 - data + 64
mem[20] = 'h2a009a8b; // lv v21 x1 l2 - data + 96
mem[21] = 'h2c009b0b; // lv v22 x1 l2 - data + 128
mem[22] = 'h2e009b8b; // lv v23 x1 l2 - data + 160
mem[23] = 'h30009c0b; // lv v24 x1 l2 - data + 192
mem[24] = 'h32009c8b; // lv v25 x1 l2 - data + 224
mem[25] = 'h36009d0b; // lv v26 x1 l3 - data + 0
mem[26] = 'h38009d8b; // lv v27 x1 l3 - data + 32
mem[27] = 'h3a009e0b; // lv v28 x1 l3 - data + 64
mem[28] = 'h47808113; // addi x2 x1 iris_x - data
mem[29] = 'h3e008193; // addi x3 x1 iris_y - data
mem[30] = 'h4b010a13; // addi x20 x2 1200
mem[31] = 'h0001108b; // lv v1 x2 0
mem[32] = 'h181100ab; // mulmv v1 v2 v1
mem[33] = 'h10009f0b; // lv v30 x1 b0 - data
mem[34] = 'h1be080ab; // addv v1 v1 v30
mem[35] = 'h0600a02b; // ltv v1 v0
mem[36] = 'h160000ab; // movmv v1 v0
mem[37] = 'h181500ab; // mulmv v1 v10 v1
mem[38] = 'h22009f0b; // lv v30 x1 b1 - data
mem[39] = 'h1be080ab; // addv v1 v1 v30
mem[40] = 'h0600a02b; // ltv v1 v0
mem[41] = 'h160000ab; // movmv v1 v0
mem[42] = 'h181900ab; // mulmv v1 v18 v1
mem[43] = 'h34009f0b; // lv v30 x1 b2 - data
mem[44] = 'h1be080ab; // addv v1 v1 v30
mem[45] = 'h0600a02b; // ltv v1 v0
mem[46] = 'h160000ab; // movmv v1 v0
mem[47] = 'h181d00ab; // mulmv v1 v26 v1
mem[48] = 'h3c009f0b; // lv v30 x1 b3 - data
mem[49] = 'h1be080ab; // addv v1 v1 v30
mem[50] = 'h0600a02b; // ltv v1 v0
mem[51] = 'h160000ab; // movmv v1 v0
mem[52] = 'h00018503; // lb x10 x3 0
mem[53] = 'h02000fef; // jal x31 check_result
mem[54] = 'h00810113; // addi x2 x2 8
mem[55] = 'h00118193; // addi x3 x3 1
mem[56] = 'hf9414ee3; // blt x2 x20 loop
mem[57] = 'hff000093; // addi x1 x0 - 16
mem[58] = 'h17002103; // lw x2 x0 correct_results
mem[59] = 'h00208023; // sb x2 x1 0
mem[60] = 'h0000006f; // jal x0 halt
mem[61] = 'h1400208b; // sv v1 x0 res_vec
mem[62] = 'h00000237; // lui x4 0
mem[63] = 'hfff00293; // addi x5 x0 - 1
mem[64] = 'h00000337; // lui x6 0
mem[65] = 'h00300393; // addi x7 x0 3
mem[66] = 'h14000493; // addi x9 x0 res_vec
mem[67] = 'h02725063; // bge x4 x7 res_loop_end
mem[68] = 'h00049403; // lh x8 x9 0
mem[69] = 'h00544663; // blt x8 x5 res_skip
mem[70] = 'h008002b3; // add x5 x0 x8
mem[71] = 'h00400333; // add x6 x0 x4
mem[72] = 'h00120213; // addi x4 x4 1
mem[73] = 'h00248493; // addi x9 x9 2
mem[74] = 'hfe5ff06f; // j res_loop
mem[75] = 'h00a31863; // bne x6 x10 res_ret
mem[76] = 'h17002283; // lw x5 x0 correct_results
mem[77] = 'h00128293; // addi x5 x5 1
mem[78] = 'h16502823; // sw x5 x0 correct_results
mem[79] = 'h000f8067; // jr x31 0
mem[80] = 'h00000000; // dw 0x00000000
mem[81] = 'h00000000; // dw 0x00000000
mem[82] = 'h00000000; // dw 0x00000000
mem[83] = 'h00000000; // dw 0x00000000
mem[84] = 'h00000000; // dw 0x00000000
mem[85] = 'h00000000; // dw 0x00000000
mem[86] = 'h00000000; // dw 0x00000000
mem[87] = 'h00000000; // dw 0x00000000
mem[88] = 'h00000000; // dw 0
mem[89] = 'h00000000; // dw 0
mem[90] = 'h00000000; // dw 0
mem[91] = 'h00000000; // dw 0
mem[92] = 'h00000000; // dw 0
mem[2048] = 'h04f40c54; // dw 0x04f40c54
mem[2049] = 'hfe1ff6ca; // dw 0xfe1ff6ca
mem[2050] = 'h00000000; // dw 0x00000000
mem[2051] = 'h00000000; // dw 0x00000000
mem[2052] = 'h00000000; // dw 0x00000000
mem[2053] = 'h00000000; // dw 0x00000000
mem[2054] = 'h00000000; // dw 0x00000000
mem[2055] = 'h00000000; // dw 0x00000000
mem[2056] = 'hffff0000; // dw 0xffff0000
mem[2057] = 'h00190102; // dw 0x00190102
mem[2058] = 'h00000000; // dw 0x00000000
mem[2059] = 'h00000000; // dw 0x00000000
mem[2060] = 'h00000000; // dw 0x00000000
mem[2061] = 'h00000000; // dw 0x00000000
mem[2062] = 'h00000000; // dw 0x00000000
mem[2063] = 'h00000000; // dw 0x00000000
mem[2064] = 'h057f01f9; // dw 0x057f01f9
mem[2065] = 'hf6f3fb68; // dw 0xf6f3fb68
mem[2066] = 'h00000000; // dw 0x00000000
mem[2067] = 'h00000000; // dw 0x00000000
mem[2068] = 'h00000000; // dw 0x00000000
mem[2069] = 'h00000000; // dw 0x00000000
mem[2070] = 'h00000000; // dw 0x00000000
mem[2071] = 'h00000000; // dw 0x00000000
mem[2072] = 'hf7f8f924; // dw 0xf7f8f924
mem[2073] = 'h02b30819; // dw 0x02b30819
mem[2074] = 'h00000000; // dw 0x00000000
mem[2075] = 'h00000000; // dw 0x00000000
mem[2076] = 'h00000000; // dw 0x00000000
mem[2077] = 'h00000000; // dw 0x00000000
mem[2078] = 'h00000000; // dw 0x00000000
mem[2079] = 'h00000000; // dw 0x00000000
mem[2080] = 'h0003ff3c; // dw 0x0003ff3c
mem[2081] = 'h0000fff8; // dw 0x0000fff8
mem[2082] = 'h00000000; // dw 0x00000000
mem[2083] = 'h00000000; // dw 0x00000000
mem[2084] = 'h00000000; // dw 0x00000000
mem[2085] = 'h00000000; // dw 0x00000000
mem[2086] = 'h00000000; // dw 0x00000000
mem[2087] = 'h00000000; // dw 0x00000000
mem[2088] = 'hf5c5f7c6; // dw 0xf5c5f7c6
mem[2089] = 'h09420587; // dw 0x09420587
mem[2090] = 'h00000000; // dw 0x00000000
mem[2091] = 'h00000000; // dw 0x00000000
mem[2092] = 'h00000000; // dw 0x00000000
mem[2093] = 'h00000000; // dw 0x00000000
mem[2094] = 'h00000000; // dw 0x00000000
mem[2095] = 'h00000000; // dw 0x00000000
mem[2096] = 'hff7900fb; // dw 0xff7900fb
mem[2097] = 'h0030ffdf; // dw 0x0030ffdf
mem[2098] = 'h00000000; // dw 0x00000000
mem[2099] = 'h00000000; // dw 0x00000000
mem[2100] = 'h00000000; // dw 0x00000000
mem[2101] = 'h00000000; // dw 0x00000000
mem[2102] = 'h00000000; // dw 0x00000000
mem[2103] = 'h00000000; // dw 0x00000000
mem[2104] = 'hf580fb91; // dw 0xf580fb91
mem[2105] = 'h084702b3; // dw 0x084702b3
mem[2106] = 'h00000000; // dw 0x00000000
mem[2107] = 'h00000000; // dw 0x00000000
mem[2108] = 'h00000000; // dw 0x00000000
mem[2109] = 'h00000000; // dw 0x00000000
mem[2110] = 'h00000000; // dw 0x00000000
mem[2111] = 'h00000000; // dw 0x00000000
mem[2112] = 'hfaa5054a; // dw 0xfaa5054a
mem[2113] = 'h07fc0600; // dw 0x07fc0600
mem[2114] = 'h064bffe2; // dw 0x064bffe2
mem[2115] = 'h0811fd0f; // dw 0x0811fd0f
mem[2116] = 'h00000000; // dw 0x00000000
mem[2117] = 'h00000000; // dw 0x00000000
mem[2118] = 'h00000000; // dw 0x00000000
mem[2119] = 'h00000000; // dw 0x00000000
mem[2120] = 'h006bfc7c; // dw 0x006bfc7c
mem[2121] = 'h07e3fc4b; // dw 0x07e3fc4b
mem[2122] = 'h06adfffd; // dw 0x06adfffd
mem[2123] = 'h09390000; // dw 0x09390000
mem[2124] = 'h00000000; // dw 0x00000000
mem[2125] = 'h00000000; // dw 0x00000000
mem[2126] = 'h00000000; // dw 0x00000000
mem[2127] = 'h00000000; // dw 0x00000000
mem[2128] = 'h000004ea; // dw 0x000004ea
mem[2129] = 'h068902a6; // dw 0x068902a6
mem[2130] = 'h016e0000; // dw 0x016e0000
mem[2131] = 'h059a0040; // dw 0x059a0040
mem[2132] = 'h00000000; // dw 0x00000000
mem[2133] = 'h00000000; // dw 0x00000000
mem[2134] = 'h00000000; // dw 0x00000000
mem[2135] = 'h00000000; // dw 0x00000000
mem[2136] = 'hffd50000; // dw 0xffd50000
mem[2137] = 'h0000ff89; // dw 0x0000ff89
mem[2138] = 'hfff80000; // dw 0xfff80000
mem[2139] = 'hfff5ffb2; // dw 0xfff5ffb2
mem[2140] = 'h00000000; // dw 0x00000000
mem[2141] = 'h00000000; // dw 0x00000000
mem[2142] = 'h00000000; // dw 0x00000000
mem[2143] = 'h00000000; // dw 0x00000000
mem[2144] = 'h00000a8b; // dw 0x00000a8b
mem[2145] = 'hf82b06b3; // dw 0xf82b06b3
mem[2146] = 'hf7dd0003; // dw 0xf7dd0003
mem[2147] = 'hfd35fffd; // dw 0xfd35fffd
mem[2148] = 'h00000000; // dw 0x00000000
mem[2149] = 'h00000000; // dw 0x00000000
mem[2150] = 'h00000000; // dw 0x00000000
mem[2151] = 'h00000000; // dw 0x00000000
mem[2152] = 'h000dffd5; // dw 0x000dffd5
mem[2153] = 'hffcf0000; // dw 0xffcf0000
mem[2154] = 'h00000000; // dw 0x00000000
mem[2155] = 'hffd6001a; // dw 0xffd6001a
mem[2156] = 'h00000000; // dw 0x00000000
mem[2157] = 'h00000000; // dw 0x00000000
mem[2158] = 'h00000000; // dw 0x00000000
mem[2159] = 'h00000000; // dw 0x00000000
mem[2160] = 'h00000875; // dw 0x00000875
mem[2161] = 'hf8bb0732; // dw 0xf8bb0732
mem[2162] = 'hfbdeffb9; // dw 0xfbdeffb9
mem[2163] = 'hf7b3fffb; // dw 0xf7b3fffb
mem[2164] = 'h00000000; // dw 0x00000000
mem[2165] = 'h00000000; // dw 0x00000000
mem[2166] = 'h00000000; // dw 0x00000000
mem[2167] = 'h00000000; // dw 0x00000000
mem[2168] = 'h00020485; // dw 0x00020485
mem[2169] = 'hfa600751; // dw 0xfa600751
mem[2170] = 'hf61e0055; // dw 0xf61e0055
mem[2171] = 'hfab20000; // dw 0xfab20000
mem[2172] = 'h00000000; // dw 0x00000000
mem[2173] = 'h00000000; // dw 0x00000000
mem[2174] = 'h00000000; // dw 0x00000000
mem[2175] = 'h00000000; // dw 0x00000000
mem[2176] = 'h003604b8; // dw 0x003604b8
mem[2177] = 'h05ea0636; // dw 0x05ea0636
mem[2178] = 'hfcc3ffbd; // dw 0xfcc3ffbd
mem[2179] = 'hfc8effe8; // dw 0xfc8effe8
mem[2180] = 'h00000000; // dw 0x00000000
mem[2181] = 'h00000000; // dw 0x00000000
mem[2182] = 'h00000000; // dw 0x00000000
mem[2183] = 'h00000000; // dw 0x00000000
mem[2184] = 'h05b30838; // dw 0x05b30838
mem[2185] = 'h00b4fd9e; // dw 0x00b4fd9e
mem[2186] = 'h0520fd85; // dw 0x0520fd85
mem[2187] = 'h057c0607; // dw 0x057c0607
mem[2188] = 'h00000000; // dw 0x00000000
mem[2189] = 'h00000000; // dw 0x00000000
mem[2190] = 'h00000000; // dw 0x00000000
mem[2191] = 'h00000000; // dw 0x00000000
mem[2192] = 'h0248fad1; // dw 0x0248fad1
mem[2193] = 'h03f80002; // dw 0x03f80002
mem[2194] = 'h040eff76; // dw 0x040eff76
mem[2195] = 'h02a00623; // dw 0x02a00623
mem[2196] = 'h00000000; // dw 0x00000000
mem[2197] = 'h00000000; // dw 0x00000000
mem[2198] = 'h00000000; // dw 0x00000000
mem[2199] = 'h00000000; // dw 0x00000000
mem[2200] = 'h02560436; // dw 0x02560436
mem[2201] = 'hfa3e0000; // dw 0xfa3e0000
mem[2202] = 'hfb1c0000; // dw 0xfb1c0000
mem[2203] = 'hfbb2f88d; // dw 0xfbb2f88d
mem[2204] = 'h00000000; // dw 0x00000000
mem[2205] = 'h00000000; // dw 0x00000000
mem[2206] = 'h00000000; // dw 0x00000000
mem[2207] = 'h00000000; // dw 0x00000000
mem[2208] = 'hff7a032a; // dw 0xff7a032a
mem[2209] = 'h00160030; // dw 0x00160030
mem[2210] = 'hff9c0001; // dw 0xff9c0001
mem[2211] = 'hfcb90036; // dw 0xfcb90036
mem[2212] = 'h00000000; // dw 0x00000000
mem[2213] = 'h00000000; // dw 0x00000000
mem[2214] = 'h00000000; // dw 0x00000000
mem[2215] = 'h00000000; // dw 0x00000000
mem[2216] = 'h00000000; // dw 0x00000000
mem[2217] = 'h0000ffc6; // dw 0x0000ffc6
mem[2218] = 'h00000000; // dw 0x00000000
mem[2219] = 'h00000000; // dw 0x00000000
mem[2220] = 'h00000000; // dw 0x00000000
mem[2221] = 'h00000000; // dw 0x00000000
mem[2222] = 'h00000000; // dw 0x00000000
mem[2223] = 'h00000000; // dw 0x00000000
mem[2224] = 'h044a095d; // dw 0x044a095d
mem[2225] = 'hf7cd0000; // dw 0xf7cd0000
mem[2226] = 'hf85f0000; // dw 0xf85f0000
mem[2227] = 'h070bf893; // dw 0x070bf893
mem[2228] = 'h00000000; // dw 0x00000000
mem[2229] = 'h00000000; // dw 0x00000000
mem[2230] = 'h00000000; // dw 0x00000000
mem[2231] = 'h00000000; // dw 0x00000000
mem[2232] = 'h00000046; // dw 0x00000046
mem[2233] = 'h0003fff9; // dw 0x0003fff9
mem[2234] = 'hffd70000; // dw 0xffd70000
mem[2235] = 'hffb4ffdd; // dw 0xffb4ffdd
mem[2236] = 'h00000000; // dw 0x00000000
mem[2237] = 'h00000000; // dw 0x00000000
mem[2238] = 'h00000000; // dw 0x00000000
mem[2239] = 'h00000000; // dw 0x00000000
mem[2240] = 'hffcbfab9; // dw 0xffcbfab9
mem[2241] = 'h0453ffb7; // dw 0x0453ffb7
mem[2242] = 'h06940000; // dw 0x06940000
mem[2243] = 'h00870379; // dw 0x00870379
mem[2244] = 'h00000000; // dw 0x00000000
mem[2245] = 'h00000000; // dw 0x00000000
mem[2246] = 'h00000000; // dw 0x00000000
mem[2247] = 'h00000000; // dw 0x00000000
mem[2248] = 'h025204f6; // dw 0x025204f6
mem[2249] = 'h08350000; // dw 0x08350000
mem[2250] = 'h0a250000; // dw 0x0a250000
mem[2251] = 'h06f40798; // dw 0x06f40798
mem[2252] = 'h00000000; // dw 0x00000000
mem[2253] = 'h00000000; // dw 0x00000000
mem[2254] = 'h00000000; // dw 0x00000000
mem[2255] = 'h00000000; // dw 0x00000000
mem[2256] = 'h03a60167; // dw 0x03a60167
mem[2257] = 'hfd3dfe3e; // dw 0xfd3dfe3e
mem[2258] = 'hfb570626; // dw 0xfb570626
mem[2259] = 'h076d002a; // dw 0x076d002a
mem[2260] = 'h00000000; // dw 0x00000000
mem[2261] = 'h00000000; // dw 0x00000000
mem[2262] = 'h00000000; // dw 0x00000000
mem[2263] = 'h00000000; // dw 0x00000000
mem[2264] = 'hfe7c0290; // dw 0xfe7c0290
mem[2265] = 'hffb300e0; // dw 0xffb300e0
mem[2266] = 'h00f5f7e8; // dw 0x00f5f7e8
mem[2267] = 'h01e10687; // dw 0x01e10687
mem[2268] = 'h00000000; // dw 0x00000000
mem[2269] = 'h00000000; // dw 0x00000000
mem[2270] = 'h00000000; // dw 0x00000000
mem[2271] = 'h00000000; // dw 0x00000000
mem[2272] = 'hf4a7fcb6; // dw 0xf4a7fcb6
mem[2273] = 'h00000003; // dw 0x00000003
mem[2274] = 'h0005011e; // dw 0x0005011e
mem[2275] = 'h0421fb2a; // dw 0x0421fb2a
mem[2276] = 'h00000000; // dw 0x00000000
mem[2277] = 'h00000000; // dw 0x00000000
mem[2278] = 'h00000000; // dw 0x00000000
mem[2279] = 'h00000000; // dw 0x00000000
mem[2280] = 'h0f6cf6ad; // dw 0x0f6cf6ad
mem[2281] = 'h004afec4; // dw 0x004afec4
mem[2282] = 'h000008ac; // dw 0x000008ac
mem[2283] = 'hfaaaff94; // dw 0xfaaaff94
mem[2284] = 'h00000000; // dw 0x00000000
mem[2285] = 'h00000000; // dw 0x00000000
mem[2286] = 'h00000000; // dw 0x00000000
mem[2287] = 'h00000000; // dw 0x00000000
mem[2288] = 'h000f03d9; // dw 0x000f03d9
mem[2289] = 'h0000021a; // dw 0x0000021a
mem[2290] = 'h00000000; // dw 0x00000000
mem[2291] = 'h00000000; // dw 0x00000000
mem[2292] = 'h00000000; // dw 0x00000000
mem[2293] = 'h00000000; // dw 0x00000000
mem[2294] = 'h00000000; // dw 0x00000000
mem[2295] = 'h00000000; // dw 0x00000000
mem[2296] = 'h00000000; // dw 0x00000000
mem[2297] = 'h00000000; // dw 0x00000000
mem[2298] = 'h00000000; // dw 0x00000000
mem[2299] = 'h00000000; // dw 0x00000000
mem[2300] = 'h00000000; // dw 0x00000000
mem[2301] = 'h00000000; // dw 0x00000000
mem[2302] = 'h00000000; // dw 0x00000000
mem[2303] = 'h00000000; // dw 0x00000000
mem[2304] = 'h00000000; // dw 0x00000000
mem[2305] = 'h00000000; // dw 0x00000000
mem[2306] = 'h00000000; // dw 0x00000000
mem[2307] = 'h00000000; // dw 0x00000000
mem[2308] = 'h00000101; // dw 0x00000101
mem[2309] = 'h01010101; // dw 0x01010101
mem[2310] = 'h01010101; // dw 0x01010101
mem[2311] = 'h01010101; // dw 0x01010101
mem[2312] = 'h01010101; // dw 0x01010101
mem[2313] = 'h01010101; // dw 0x01010101
mem[2314] = 'h01010101; // dw 0x01010101
mem[2315] = 'h01010101; // dw 0x01010101
mem[2316] = 'h01010101; // dw 0x01010101
mem[2317] = 'h01010101; // dw 0x01010101
mem[2318] = 'h01010101; // dw 0x01010101
mem[2319] = 'h01010101; // dw 0x01010101
mem[2320] = 'h01010101; // dw 0x01010101
mem[2321] = 'h02020202; // dw 0x02020202
mem[2322] = 'h02020202; // dw 0x02020202
mem[2323] = 'h02020202; // dw 0x02020202
mem[2324] = 'h02020202; // dw 0x02020202
mem[2325] = 'h02020202; // dw 0x02020202
mem[2326] = 'h02020202; // dw 0x02020202
mem[2327] = 'h02020202; // dw 0x02020202
mem[2328] = 'h02020202; // dw 0x02020202
mem[2329] = 'h02020202; // dw 0x02020202
mem[2330] = 'h02020202; // dw 0x02020202
mem[2331] = 'h02020202; // dw 0x02020202
mem[2332] = 'h02020202; // dw 0x02020202
mem[2333] = 'h02020000; // dw 0x02020000
mem[2334] = 'h02bf0400; // dw 0x02bf0400
mem[2335] = 'h00280119; // dw 0x00280119
mem[2336] = 'h02870420; // dw 0x02870420
mem[2337] = 'h002b012e; // dw 0x002b012e
mem[2338] = 'h02b90400; // dw 0x02b90400
mem[2339] = 'h002c011b; // dw 0x002c011b
mem[2340] = 'h02a303ea; // dw 0x02a303ea
mem[2341] = 'h002c0147; // dw 0x002c0147
mem[2342] = 'h02d303ec; // dw 0x02d303ec
mem[2343] = 'h00280119; // dw 0x00280119
mem[2344] = 'h02bd03ca; // dw 0x02bd03ca
mem[2345] = 'h00480131; // dw 0x00480131
mem[2346] = 'h02ce03cb; // dw 0x02ce03cb
mem[2347] = 'h003f0128; // dw 0x003f0128
mem[2348] = 'h02b103f6; // dw 0x02b103f6
mem[2349] = 'h00290130; // dw 0x00290130
mem[2350] = 'h029b03f4; // dw 0x029b03f4
mem[2351] = 'h002e0142; // dw 0x002e0142
mem[2352] = 'h02950415; // dw 0x02950415
mem[2353] = 'h00150140; // dw 0x00150140
mem[2354] = 'h02be0400; // dw 0x02be0400
mem[2355] = 'h0026011c; // dw 0x0026011c
mem[2356] = 'h02b803d7; // dw 0x02b803d7
mem[2357] = 'h00290148; // dw 0x00290148
mem[2358] = 'h02950421; // dw 0x02950421
mem[2359] = 'h00160134; // dw 0x00160134
mem[2360] = 'h02d3040c; // dw 0x02d3040c
mem[2361] = 'h00180109; // dw 0x00180109
mem[2362] = 'h02db0425; // dw 0x02db0425
mem[2363] = 'h002500db; // dw 0x002500db
mem[2364] = 'h02ef03cd; // dw 0x02ef03cd
mem[2365] = 'h00440100; // dw 0x00440100
mem[2366] = 'h02d603ed; // dw 0x02d603ed
mem[2367] = 'h004a00f2; // dw 0x004a00f2
mem[2368] = 'h02b803f6; // dw 0x02b803f6
mem[2369] = 'h003c0116; // dw 0x003c0116
mem[2370] = 'h02a503f7; // dw 0x02a503f7
mem[2371] = 'h0035012f; // dw 0x0035012f
mem[2372] = 'h02d703d0; // dw 0x02d703d0
mem[2373] = 'h0039011f; // dw 0x0039011f
mem[2374] = 'h028b040a; // dw 0x028b040a
mem[2375] = 'h00260145; // dw 0x00260145
mem[2376] = 'h02c403d0; // dw 0x02c403d0
mem[2377] = 'h004d011f; // dw 0x004d011f
mem[2378] = 'h031003ea; // dw 0x031003ea
mem[2379] = 'h002c00da; // dw 0x002c00da
mem[2380] = 'h027e03d9; // dw 0x027e03d9
mem[2381] = 'h00610148; // dw 0x00610148
mem[2382] = 'h02a403ba; // dw 0x02a403ba
mem[2383] = 'h0028017a; // dw 0x0028017a
mem[2384] = 'h02730415; // dw 0x02730415
mem[2385] = 'h002a014e; // dw 0x002a014e
mem[2386] = 'h029e03d9; // dw 0x029e03d9
mem[2387] = 'h004f013b; // dw 0x004f013b
mem[2388] = 'h02b10400; // dw 0x02b10400
mem[2389] = 'h00270127; // dw 0x00270127
mem[2390] = 'h02ab0414; // dw 0x02ab0414
mem[2391] = 'h00280119; // dw 0x00280119
mem[2392] = 'h02a403e0; // dw 0x02a403e0
mem[2393] = 'h002a0152; // dw 0x002a0152
mem[2394] = 'h028f03f5; // dw 0x028f03f5
mem[2395] = 'h002a0152; // dw 0x002a0152
mem[2396] = 'h028b040a; // dw 0x028b040a
mem[2397] = 'h004d011f; // dw 0x004d011f
mem[2398] = 'h030203d1; // dw 0x030203d1
mem[2399] = 'h0013011a; // dw 0x0013011a
mem[2400] = 'h02f903e5; // dw 0x02f903e5
mem[2401] = 'h002400fe; // dw 0x002400fe
mem[2402] = 'h028f040b; // dw 0x028f040b
mem[2403] = 'h002a013d; // dw 0x002a013d
mem[2404] = 'h02ab042b; // dw 0x02ab042b
mem[2405] = 'h002b0100; // dw 0x002b0100
mem[2406] = 'h02ab0431; // dw 0x02ab0431
mem[2407] = 'h002700fe; // dw 0x002700fe
mem[2408] = 'h02e103ec; // dw 0x02e103ec
mem[2409] = 'h0014011f; // dw 0x0014011f
mem[2410] = 'h02b203f4; // dw 0x02b203f4
mem[2411] = 'h002e012b; // dw 0x002e012b
mem[2412] = 'h02ab0400; // dw 0x02ab0400
mem[2413] = 'h0028012d; // dw 0x0028012d
mem[2414] = 'h02c603f6; // dw 0x02c603f6
mem[2415] = 'h003d0108; // dw 0x003d0108
mem[2416] = 'h02310449; // dw 0x02310449
mem[2417] = 'h0049013d; // dw 0x0049013d
mem[2418] = 'h02d003de; // dw 0x02d003de
mem[2419] = 'h002d0125; // dw 0x002d0125
mem[2420] = 'h029e03bd; // dw 0x029e03bd
mem[2421] = 'h00730132; // dw 0x00730132
mem[2422] = 'h02b703a5; // dw 0x02b703a5
mem[2423] = 'h0049015b; // dw 0x0049015b
mem[2424] = 'h0287040b; // dw 0x0287040b
mem[2425] = 'h0041012e; // dw 0x0041012e
mem[2426] = 'h02d703d0; // dw 0x02d703d0
mem[2427] = 'h00260132; // dw 0x00260132
mem[2428] = 'h02b903ea; // dw 0x02b903ea
mem[2429] = 'h002c0131; // dw 0x002c0131
mem[2430] = 'h02c403f6; // dw 0x02c403f6
mem[2431] = 'h0026011f; // dw 0x0026011f
mem[2432] = 'h02ab040a; // dw 0x02ab040a
mem[2433] = 'h00290122; // dw 0x00290122
mem[2434] = 'h01920370; // dw 0x01920370
mem[2435] = 'h00b0024f; // dw 0x00b0024f
mem[2436] = 'h01a40348; // dw 0x01a40348
mem[2437] = 'h00c5024f; // dw 0x00c5024f
mem[2438] = 'h0183035e; // dw 0x0183035e
mem[2439] = 'h00bb0264; // dw 0x00bb0264
mem[2440] = 'h0168035c; // dw 0x0168035c
mem[2441] = 'h00cb0271; // dw 0x00cb0271
mem[2442] = 'h01740360; // dw 0x01740360
mem[2443] = 'h00c70264; // dw 0x00c70264
mem[2444] = 'h01910330; // dw 0x01910330
mem[2445] = 'h00ba0284; // dw 0x00ba0284
mem[2446] = 'h01a9032b; // dw 0x01a9032b
mem[2447] = 'h00ce025d; // dw 0x00ce025d
mem[2448] = 'h01a80361; // dw 0x01a80361
mem[2449] = 'h00b10247; // dw 0x00b10247
mem[2450] = 'h0182036e; // dw 0x0182036e
mem[2451] = 'h00ad0264; // dw 0x00ad0264
mem[2452] = 'h01a30327; // dw 0x01a30327
mem[2453] = 'h00d9025d; // dw 0x00d9025d
mem[2454] = 'h0164037a; // dw 0x0164037a
mem[2455] = 'h00b2026f; // dw 0x00b2026f
mem[2456] = 'h01a5033c; // dw 0x01a5033c
mem[2457] = 'h00d2024d; // dw 0x00d2024d
mem[2458] = 'h015503a3; // dw 0x015503a3
mem[2459] = 'h009b026d; // dw 0x009b026d
mem[2460] = 'h0189033b; // dw 0x0189033b
mem[2461] = 'h00be027d; // dw 0x00be027d
mem[2462] = 'h01bb0358; // dw 0x01bb0358
mem[2463] = 'h00c70226; // dw 0x00c70226
mem[2464] = 'h01970370; // dw 0x01970370
mem[2465] = 'h00b80242; // dw 0x00b80242
mem[2466] = 'h01a50312; // dw 0x01a50312
mem[2467] = 'h00d20277; // dw 0x00d20277
mem[2468] = 'h01970369; // dw 0x01970369
mem[2469] = 'h00970269; // dw 0x00970269
mem[2470] = 'h01390372; // dw 0x01390372
mem[2471] = 'h00d50280; // dw 0x00d50280
mem[2472] = 'h0187036b; // dw 0x0187036b
mem[2473] = 'h00ac0262; // dw 0x00ac0262
mem[2474] = 'h01a10302; // dw 0x01a10302
mem[2475] = 'h00eb0272; // dw 0x00eb0272
mem[2476] = 'h01940370; // dw 0x01940370
mem[2477] = 'h00bb0241; // dw 0x00bb0241
mem[2478] = 'h01510351; // dw 0x01510351
mem[2479] = 'h00ca0294; // dw 0x00ca0294
mem[2480] = 'h0183034c; // dw 0x0183034c
mem[2481] = 'h00a6028a; // dw 0x00a6028a
mem[2482] = 'h018f0370; // dw 0x018f0370
mem[2483] = 'h00b3024f; // dw 0x00b3024f
mem[2484] = 'h018f036e; // dw 0x018f036e
mem[2485] = 'h00ba0249; // dw 0x00ba0249
mem[2486] = 'h016b0371; // dw 0x016b0371
mem[2487] = 'h00b5026e; // dw 0x00b5026e
mem[2488] = 'h01770345; // dw 0x01770345
mem[2489] = 'h00d40270; // dw 0x00d40270
mem[2490] = 'h018f0339; // dw 0x018f0339
mem[2491] = 'h00ce026b; // dw 0x00ce026b
mem[2492] = 'h01a00390; // dw 0x01a00390
mem[2493] = 'h00a00230; // dw 0x00a00230
mem[2494] = 'h01800370; // dw 0x01800370
mem[2495] = 'h00b00260; // dw 0x00b00260
mem[2496] = 'h0186037e; // dw 0x0186037e
mem[2497] = 'h00a30259; // dw 0x00a30259
mem[2498] = 'h01970369; // dw 0x01970369
mem[2499] = 'h00b5024b; // dw 0x00b5024b
mem[2500] = 'h0167031e; // dw 0x0167031e
mem[2501] = 'h00d502a6; // dw 0x00d502a6
mem[2502] = 'h01ab0300; // dw 0x01ab0300
mem[2503] = 'h00d50280; // dw 0x00d50280
mem[2504] = 'h01c10319; // dw 0x01c10319
mem[2505] = 'h00d30253; // dw 0x00d30253
mem[2506] = 'h018d035a; // dw 0x018d035a
mem[2507] = 'h00c0025a; // dw 0x00c0025a
mem[2508] = 'h01490386; // dw 0x01490386
mem[2509] = 'h00ba0276; // dw 0x00ba0276
mem[2510] = 'h01b70333; // dw 0x01b70333
mem[2511] = 'h00be0258; // dw 0x00be0258
mem[2512] = 'h0181034f; // dw 0x0181034f
mem[2513] = 'h00c80268; // dw 0x00c80268
mem[2514] = 'h01850336; // dw 0x01850336
mem[2515] = 'h00b30292; // dw 0x00b30292
mem[2516] = 'h0197033b; // dw 0x0197033b
mem[2517] = 'h00be0270; // dw 0x00be0270
mem[2518] = 'h01880369; // dw 0x01880369
mem[2519] = 'h00b5025a; // dw 0x00b5025a
mem[2520] = 'h01960373; // dw 0x01960373
mem[2521] = 'h00b10247; // dw 0x00b10247
mem[2522] = 'h0191033f; // dw 0x0191033f
mem[2523] = 'h00c1026f; // dw 0x00c1026f
mem[2524] = 'h01b4033c; // dw 0x01b4033c
mem[2525] = 'h00ae0262; // dw 0x00ae0262
mem[2526] = 'h01a5033c; // dw 0x01a5033c
mem[2527] = 'h00bd0262; // dw 0x00bd0262
mem[2528] = 'h01940360; // dw 0x01940360
mem[2529] = 'h00b50257; // dw 0x00b50257
mem[2530] = 'h01b6037d; // dw 0x01b6037d
mem[2531] = 'h00c1020d; // dw 0x00c1020d
mem[2532] = 'h019d0348; // dw 0x019d0348
mem[2533] = 'h00c0025c; // dw 0x00c0025c
mem[2534] = 'h017502c9; // dw 0x017502c9
mem[2535] = 'h011b02a7; // dw 0x011b02a7
mem[2536] = 'h016502fe; // dw 0x016502fe
mem[2537] = 'h00fb02a2; // dw 0x00fb02a2
mem[2538] = 'h01530323; // dw 0x01530323
mem[2539] = 'h00ee029c; // dw 0x00ee029c
mem[2540] = 'h01660309; // dw 0x01660309
mem[2541] = 'h00de02b3; // dw 0x00de02b3
mem[2542] = 'h015f02f9; // dw 0x015f02f9
mem[2543] = 'h010102a7; // dw 0x010102a7
mem[2544] = 'h013e0326; // dw 0x013e0326
mem[2545] = 'h00df02bc; // dw 0x00df02bc
mem[2546] = 'h017802e2; // dw 0x017802e2
mem[2547] = 'h010002a6; // dw 0x010002a6
mem[2548] = 'h01450331; // dw 0x01450331
mem[2549] = 'h00c902c1; // dw 0x00c902c1
mem[2550] = 'h01310331; // dw 0x01310331
mem[2551] = 'h00db02c3; // dw 0x00db02c3
mem[2552] = 'h017c02f8; // dw 0x017c02f8
mem[2553] = 'h01080284; // dw 0x01080284
mem[2554] = 'h01860318; // dw 0x01860318
mem[2555] = 'h00f4026e; // dw 0x00f4026e
mem[2556] = 'h01530324; // dw 0x01530324
mem[2557] = 'h00ef029a; // dw 0x00ef029a
mem[2558] = 'h01610320; // dw 0x01610320
mem[2559] = 'h00f70287; // dw 0x00f70287
mem[2560] = 'h01510300; // dw 0x01510300
mem[2561] = 'h010d02a2; // dw 0x010d02a2
mem[2562] = 'h016402e2; // dw 0x016402e2
mem[2563] = 'h01310289; // dw 0x01310289
mem[2564] = 'h017d02fa; // dw 0x017d02fa
mem[2565] = 'h01120277; // dw 0x01120277
mem[2566] = 'h016e0318; // dw 0x016e0318
mem[2567] = 'h00db029e; // dw 0x00db029e
mem[2568] = 'h017d0305; // dw 0x017d0305
mem[2569] = 'h00dd02a1; // dw 0x00dd02a1
mem[2570] = 'h01110329; // dw 0x01110329
mem[2571] = 'h00f202d5; // dw 0x00f202d5
mem[2572] = 'h01330344; // dw 0x01330344
mem[2573] = 'h00d102b9; // dw 0x00d102b9
mem[2574] = 'h016a030d; // dw 0x016a030d
mem[2575] = 'h01040285; // dw 0x01040285
mem[2576] = 'h017702ee; // dw 0x017702ee
mem[2577] = 'h010c0290; // dw 0x010c0290
mem[2578] = 'h012b0335; // dw 0x012b0335
mem[2579] = 'h00d502cb; // dw 0x00d502cb
mem[2580] = 'h01600336; // dw 0x01600336
mem[2581] = 'h00eb027f; // dw 0x00eb027f
mem[2582] = 'h017c0303; // dw 0x017c0303
mem[2583] = 'h00f20290; // dw 0x00f20290
mem[2584] = 'h0168032a; // dw 0x0168032a
mem[2585] = 'h00cb02a3; // dw 0x00cb02a3
mem[2586] = 'h0170032e; // dw 0x0170032e
mem[2587] = 'h00ec0276; // dw 0x00ec0276
mem[2588] = 'h01850317; // dw 0x01850317
mem[2589] = 'h00e9027b; // dw 0x00e9027b
mem[2590] = 'h01530308; // dw 0x01530308
mem[2591] = 'h00fe02a7; // dw 0x00fe02a7
mem[2592] = 'h015d0346; // dw 0x015d0346
mem[2593] = 'h00ba02a3; // dw 0x00ba02a3
mem[2594] = 'h013b0341; // dw 0x013b0341
mem[2595] = 'h00d602ae; // dw 0x00d602ae
mem[2596] = 'h01830325; // dw 0x01830325
mem[2597] = 'h00cc028c; // dw 0x00cc028c
mem[2598] = 'h01510303; // dw 0x01510303
mem[2599] = 'h010902a3; // dw 0x010902a3
mem[2600] = 'h016d0336; // dw 0x016d0336
mem[2601] = 'h00c40299; // dw 0x00c40299
mem[2602] = 'h0153031c; // dw 0x0153031c
mem[2603] = 'h00b702da; // dw 0x00b702da
mem[2604] = 'h0142033a; // dw 0x0142033a
mem[2605] = 'h00f7028e; // dw 0x00f7028e
mem[2606] = 'h018902d9; // dw 0x018902d9
mem[2607] = 'h01160288; // dw 0x01160288
mem[2608] = 'h017a030c; // dw 0x017a030c
mem[2609] = 'h00db029e; // dw 0x00db029e
mem[2610] = 'h018a0314; // dw 0x018a0314
mem[2611] = 'h00ec0276; // dw 0x00ec0276
mem[2612] = 'h016b0327; // dw 0x016b0327
mem[2613] = 'h00f60278; // dw 0x00f60278
mem[2614] = 'h01650303; // dw 0x01650303
mem[2615] = 'h01140284; // dw 0x01140284
mem[2616] = 'h016d032c; // dw 0x016d032c
mem[2617] = 'h010f0258; // dw 0x010f0258
mem[2618] = 'h016502fe; // dw 0x016502fe
mem[2619] = 'h00fb02a2; // dw 0x00fb02a2
mem[2620] = 'h016802fd; // dw 0x016802fd
mem[2621] = 'h01030298; // dw 0x01030298
mem[2622] = 'h017302f2; // dw 0x017302f2
mem[2623] = 'h01190281; // dw 0x01190281
mem[2624] = 'h0165031e; // dw 0x0165031e
mem[2625] = 'h0112026b; // dw 0x0112026b
mem[2626] = 'h01460336; // dw 0x01460336
mem[2627] = 'h00f8028c; // dw 0x00f8028c
mem[2628] = 'h0170031d; // dw 0x0170031d
mem[2629] = 'h00f5027e; // dw 0x00f5027e
mem[2630] = 'h019202de; // dw 0x019202de
mem[2631] = 'h0110027f; // dw 0x0110027f
mem[2632] = 'h018502fd; // dw 0x018502fd
mem[2633] = 'h00e90295; // dw 0x00e90295
mem[2634] = 'h00000000; // dw 0
mem[2635] = 'h00000000; // dw 0
mem[2636] = 'h00000000; // dw 0
mem[2637] = 'h00000000; // dw 0
mem[2638] = 'h00000000; // dw 0
mem[2639] = 'h00000000; // dw 0
mem[2640] = 'h00000000; // dw 0
mem[2641] = 'h00000000; // dw 0
mem[2642] = 'h00000000; // dw 0
mem[2643] = 'h00000000; // dw 0
mem[2644] = 'h00000000; // dw 0
mem[2645] = 'h00000000; // dw 0
mem[2646] = 'h00000000; // dw 0
mem[2647] = 'h00000000; // dw 0
mem[2648] = 'h00000000; // dw 0
mem[2649] = 'h00000000; // dw 0
mem[2650] = 'h00000000; // dw 0
mem[2651] = 'h00000000; // dw 0
mem[2652] = 'h00000000; // dw 0
mem[2653] = 'h00000000; // dw 0
mem[2654] = 'h00000000; // dw 0
mem[2655] = 'h00000000; // dw 0
mem[2656] = 'h00000000; // dw 0
mem[2657] = 'h00000000; // dw 0
mem[2658] = 'h00000000; // dw 0
mem[2659] = 'h00000000; // dw 0
mem[2660] = 'h00000000; // dw 0
mem[2661] = 'h00000000; // dw 0
mem[2662] = 'h00000000; // dw 0
mem[2663] = 'h00000000; // dw 0
mem[2664] = 'h00000000; // dw 0
mem[2665] = 'h00000000; // dw 0
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
