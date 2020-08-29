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
mem[28] = 'h4000908b; // lv v1 x1 iris3 - data
mem[29] = 'h181100ab; // mulmv v1 v2 v1
mem[30] = 'h10009f0b; // lv v30 x1 b0 - data
mem[31] = 'h1be080ab; // addv v1 v1 v30
mem[32] = 'h0600a02b; // ltv v1 v0
mem[33] = 'h160000ab; // movmv v1 v0
mem[34] = 'h181500ab; // mulmv v1 v10 v1
mem[35] = 'h22009f0b; // lv v30 x1 b1 - data
mem[36] = 'h1be080ab; // addv v1 v1 v30
mem[37] = 'h0600a02b; // ltv v1 v0
mem[38] = 'h160000ab; // movmv v1 v0
mem[39] = 'h181900ab; // mulmv v1 v18 v1
mem[40] = 'h34009f0b; // lv v30 x1 b2 - data
mem[41] = 'h1be080ab; // addv v1 v1 v30
mem[42] = 'h0600a02b; // ltv v1 v0
mem[43] = 'h160000ab; // movmv v1 v0
mem[44] = 'h181d00ab; // mulmv v1 v26 v1
mem[45] = 'h3c009f0b; // lv v30 x1 b3 - data
mem[46] = 'h1be080ab; // addv v1 v1 v30
mem[47] = 'h0600a02b; // ltv v1 v0
mem[48] = 'h160000ab; // movmv v1 v0
mem[49] = 'h0000006f; // jal x0 loop
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
mem[2296] = 'h02bf0400; // dw 0x02bf0400
mem[2297] = 'h00280119; // dw 0x00280119
mem[2298] = 'h00000000; // dw 0x00000000
mem[2299] = 'h00000000; // dw 0x00000000
mem[2300] = 'h00000000; // dw 0x00000000
mem[2301] = 'h00000000; // dw 0x00000000
mem[2302] = 'h00000000; // dw 0x00000000
mem[2303] = 'h00000000; // dw 0x00000000
mem[2304] = 'h018502fd; // dw 0x018502fd
mem[2305] = 'h00e90295; // dw 0x00e90295
mem[2306] = 'h00000000; // dw 0x00000000
mem[2307] = 'h00000000; // dw 0x00000000
mem[2308] = 'h00000000; // dw 0x00000000
mem[2309] = 'h00000000; // dw 0x00000000
mem[2310] = 'h00000000; // dw 0x00000000
mem[2311] = 'h00000000; // dw 0x00000000
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
