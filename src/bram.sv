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
mem[9] = 'h1000950b; // lv v10 x1 l1 - data + 0
mem[10] = 'h1400960b; // lv v12 x1 l1 - data + 64
mem[11] = 'h1200958b; // lv v11 x1 l1 - data + 32
mem[12] = 'h1600968b; // lv v13 x1 l1 - data + 96
mem[13] = 'h1800970b; // lv v14 x1 l1 - data + 128
mem[14] = 'h1a00978b; // lv v15 x1 l1 - data + 160
mem[15] = 'h1c00980b; // lv v16 x1 l1 - data + 192
mem[16] = 'h1e00988b; // lv v17 x1 l1 - data + 224
mem[17] = 'h2000990b; // lv v18 x1 l2 - data + 0
mem[18] = 'h2200998b; // lv v19 x1 l2 - data + 32
mem[19] = 'h24009a0b; // lv v20 x1 l2 - data + 64
mem[20] = 'h26009a8b; // lv v21 x1 l2 - data + 96
mem[21] = 'h28009b0b; // lv v22 x1 l2 - data + 128
mem[22] = 'h2a009b8b; // lv v23 x1 l2 - data + 160
mem[23] = 'h2c009c0b; // lv v24 x1 l2 - data + 192
mem[24] = 'h2e009c8b; // lv v25 x1 l2 - data + 224
mem[25] = 'h30009d0b; // lv v26 x1 l3 - data + 0
mem[26] = 'h32009d8b; // lv v27 x1 l3 - data + 32
mem[27] = 'h34009e0b; // lv v28 x1 l3 - data + 64
mem[28] = 'h3600908b; // lv v1 x1 iris1 - data
mem[29] = 'h181100ab; // mulmv v1 v2 v1
mem[30] = 'h0600a02b; // ltv v1 v0
mem[31] = 'h160000ab; // movmv v1 v0
mem[32] = 'h0000006f; // jal x0 loop
mem[2048] = 'h09ec0b41; // dw 0x09ec0b41
mem[2049] = 'hf56bfe06; // dw 0xf56bfe06
mem[2050] = 'h00000000; // dw 0x00000000
mem[2051] = 'h00000000; // dw 0x00000000
mem[2052] = 'h00000000; // dw 0x00000000
mem[2053] = 'h00000000; // dw 0x00000000
mem[2054] = 'h00000000; // dw 0x00000000
mem[2055] = 'h00000000; // dw 0x00000000
mem[2056] = 'h072005a2; // dw 0x072005a2
mem[2057] = 'hf823ff37; // dw 0xf823ff37
mem[2058] = 'h00000000; // dw 0x00000000
mem[2059] = 'h00000000; // dw 0x00000000
mem[2060] = 'h00000000; // dw 0x00000000
mem[2061] = 'h00000000; // dw 0x00000000
mem[2062] = 'h00000000; // dw 0x00000000
mem[2063] = 'h00000000; // dw 0x00000000
mem[2064] = 'h01c20603; // dw 0x01c20603
mem[2065] = 'hfb8df712; // dw 0xfb8df712
mem[2066] = 'h00000000; // dw 0x00000000
mem[2067] = 'h00000000; // dw 0x00000000
mem[2068] = 'h00000000; // dw 0x00000000
mem[2069] = 'h00000000; // dw 0x00000000
mem[2070] = 'h00000000; // dw 0x00000000
mem[2071] = 'h00000000; // dw 0x00000000
mem[2072] = 'hfb6701a9; // dw 0xfb6701a9
mem[2073] = 'h065d07cf; // dw 0x065d07cf
mem[2074] = 'h00000000; // dw 0x00000000
mem[2075] = 'h00000000; // dw 0x00000000
mem[2076] = 'h00000000; // dw 0x00000000
mem[2077] = 'h00000000; // dw 0x00000000
mem[2078] = 'h00000000; // dw 0x00000000
mem[2079] = 'h00000000; // dw 0x00000000
mem[2080] = 'h03d1ffb8; // dw 0x03d1ffb8
mem[2081] = 'hfa0bf7b0; // dw 0xfa0bf7b0
mem[2082] = 'h00000000; // dw 0x00000000
mem[2083] = 'h00000000; // dw 0x00000000
mem[2084] = 'h00000000; // dw 0x00000000
mem[2085] = 'h00000000; // dw 0x00000000
mem[2086] = 'h00000000; // dw 0x00000000
mem[2087] = 'h00000000; // dw 0x00000000
mem[2088] = 'hffce0000; // dw 0xffce0000
mem[2089] = 'h0000002a; // dw 0x0000002a
mem[2090] = 'h00000000; // dw 0x00000000
mem[2091] = 'h00000000; // dw 0x00000000
mem[2092] = 'h00000000; // dw 0x00000000
mem[2093] = 'h00000000; // dw 0x00000000
mem[2094] = 'h00000000; // dw 0x00000000
mem[2095] = 'h00000000; // dw 0x00000000
mem[2096] = 'hff6f0000; // dw 0xff6f0000
mem[2097] = 'h008efef2; // dw 0x008efef2
mem[2098] = 'h00000000; // dw 0x00000000
mem[2099] = 'h00000000; // dw 0x00000000
mem[2100] = 'h00000000; // dw 0x00000000
mem[2101] = 'h00000000; // dw 0x00000000
mem[2102] = 'h00000000; // dw 0x00000000
mem[2103] = 'h00000000; // dw 0x00000000
mem[2104] = 'h00040000; // dw 0x00040000
mem[2105] = 'h00000000; // dw 0x00000000
mem[2106] = 'h00000000; // dw 0x00000000
mem[2107] = 'h00000000; // dw 0x00000000
mem[2108] = 'h00000000; // dw 0x00000000
mem[2109] = 'h00000000; // dw 0x00000000
mem[2110] = 'h00000000; // dw 0x00000000
mem[2111] = 'h00000000; // dw 0x00000000
mem[2112] = 'h06e50317; // dw 0x06e50317
mem[2113] = 'h01ca0525; // dw 0x01ca0525
mem[2114] = 'hffff079d; // dw 0xffff079d
mem[2115] = 'hffddfffe; // dw 0xffddfffe
mem[2116] = 'h00000000; // dw 0x00000000
mem[2117] = 'h00000000; // dw 0x00000000
mem[2118] = 'h00000000; // dw 0x00000000
mem[2119] = 'h00000000; // dw 0x00000000
mem[2120] = 'h04e9fce6; // dw 0x04e9fce6
mem[2121] = 'h05f3fbb7; // dw 0x05f3fbb7
mem[2122] = 'h0000feb3; // dw 0x0000feb3
mem[2123] = 'h0000ffe1; // dw 0x0000ffe1
mem[2124] = 'h00000000; // dw 0x00000000
mem[2125] = 'h00000000; // dw 0x00000000
mem[2126] = 'h00000000; // dw 0x00000000
mem[2127] = 'h00000000; // dw 0x00000000
mem[2128] = 'h067405d2; // dw 0x067405d2
mem[2129] = 'hfbc70905; // dw 0xfbc70905
mem[2130] = 'h000007e0; // dw 0x000007e0
mem[2131] = 'h0058ffb0; // dw 0x0058ffb0
mem[2132] = 'h00000000; // dw 0x00000000
mem[2133] = 'h00000000; // dw 0x00000000
mem[2134] = 'h00000000; // dw 0x00000000
mem[2135] = 'h00000000; // dw 0x00000000
mem[2136] = 'hff92fff5; // dw 0xff92fff5
mem[2137] = 'h0003ff62; // dw 0x0003ff62
mem[2138] = 'h0000008f; // dw 0x0000008f
mem[2139] = 'h00320000; // dw 0x00320000
mem[2140] = 'h00000000; // dw 0x00000000
mem[2141] = 'h00000000; // dw 0x00000000
mem[2142] = 'h00000000; // dw 0x00000000
mem[2143] = 'h00000000; // dw 0x00000000
mem[2144] = 'hffeafffc; // dw 0xffeafffc
mem[2145] = 'h00000000; // dw 0x00000000
mem[2146] = 'h0000ffe1; // dw 0x0000ffe1
mem[2147] = 'h00000000; // dw 0x00000000
mem[2148] = 'h00000000; // dw 0x00000000
mem[2149] = 'h00000000; // dw 0x00000000
mem[2150] = 'h00000000; // dw 0x00000000
mem[2151] = 'h00000000; // dw 0x00000000
mem[2152] = 'h04510878; // dw 0x04510878
mem[2153] = 'hfca3077f; // dw 0xfca3077f
mem[2154] = 'h0076071e; // dw 0x0076071e
mem[2155] = 'hffb60026; // dw 0xffb60026
mem[2156] = 'h00000000; // dw 0x00000000
mem[2157] = 'h00000000; // dw 0x00000000
mem[2158] = 'h00000000; // dw 0x00000000
mem[2159] = 'h00000000; // dw 0x00000000
mem[2160] = 'h00000000; // dw 0x00000000
mem[2161] = 'h0000ffff; // dw 0x0000ffff
mem[2162] = 'h00a80001; // dw 0x00a80001
mem[2163] = 'hffe2fff3; // dw 0xffe2fff3
mem[2164] = 'h00000000; // dw 0x00000000
mem[2165] = 'h00000000; // dw 0x00000000
mem[2166] = 'h00000000; // dw 0x00000000
mem[2167] = 'h00000000; // dw 0x00000000
mem[2168] = 'hffdcffff; // dw 0xffdcffff
mem[2169] = 'h00000000; // dw 0x00000000
mem[2170] = 'h00000000; // dw 0x00000000
mem[2171] = 'hffc90000; // dw 0xffc90000
mem[2172] = 'h00000000; // dw 0x00000000
mem[2173] = 'h00000000; // dw 0x00000000
mem[2174] = 'h00000000; // dw 0x00000000
mem[2175] = 'h00000000; // dw 0x00000000
mem[2176] = 'h070ffaeb; // dw 0x070ffaeb
mem[2177] = 'h0077fbbf; // dw 0x0077fbbf
mem[2178] = 'hf6e40010; // dw 0xf6e40010
mem[2179] = 'h00c00000; // dw 0x00c00000
mem[2180] = 'h00000000; // dw 0x00000000
mem[2181] = 'h00000000; // dw 0x00000000
mem[2182] = 'h00000000; // dw 0x00000000
mem[2183] = 'h00000000; // dw 0x00000000
mem[2184] = 'hfa1307e7; // dw 0xfa1307e7
mem[2185] = 'hffc207f5; // dw 0xffc207f5
mem[2186] = 'h0514fff5; // dw 0x0514fff5
mem[2187] = 'hfff7ff87; // dw 0xfff7ff87
mem[2188] = 'h00000000; // dw 0x00000000
mem[2189] = 'h00000000; // dw 0x00000000
mem[2190] = 'h00000000; // dw 0x00000000
mem[2191] = 'h00000000; // dw 0x00000000
mem[2192] = 'hffb3ffb6; // dw 0xffb3ffb6
mem[2193] = 'h00000000; // dw 0x00000000
mem[2194] = 'h004efffa; // dw 0x004efffa
mem[2195] = 'h00110000; // dw 0x00110000
mem[2196] = 'h00000000; // dw 0x00000000
mem[2197] = 'h00000000; // dw 0x00000000
mem[2198] = 'h00000000; // dw 0x00000000
mem[2199] = 'h00000000; // dw 0x00000000
mem[2200] = 'h0ae5049d; // dw 0x0ae5049d
mem[2201] = 'h0000fd7d; // dw 0x0000fd7d
mem[2202] = 'hf993ffa6; // dw 0xf993ffa6
mem[2203] = 'h0000fff8; // dw 0x0000fff8
mem[2204] = 'h00000000; // dw 0x00000000
mem[2205] = 'h00000000; // dw 0x00000000
mem[2206] = 'h00000000; // dw 0x00000000
mem[2207] = 'h00000000; // dw 0x00000000
mem[2208] = 'hf9e2044b; // dw 0xf9e2044b
mem[2209] = 'h000007ed; // dw 0x000007ed
mem[2210] = 'h07920004; // dw 0x07920004
mem[2211] = 'hffa30005; // dw 0xffa30005
mem[2212] = 'h00000000; // dw 0x00000000
mem[2213] = 'h00000000; // dw 0x00000000
mem[2214] = 'h00000000; // dw 0x00000000
mem[2215] = 'h00000000; // dw 0x00000000
mem[2216] = 'h0668fd54; // dw 0x0668fd54
mem[2217] = 'h0000f8ff; // dw 0x0000f8ff
mem[2218] = 'hfa150000; // dw 0xfa150000
mem[2219] = 'hfffc0030; // dw 0xfffc0030
mem[2220] = 'h00000000; // dw 0x00000000
mem[2221] = 'h00000000; // dw 0x00000000
mem[2222] = 'h00000000; // dw 0x00000000
mem[2223] = 'h00000000; // dw 0x00000000
mem[2224] = 'h02f0002d; // dw 0x02f0002d
mem[2225] = 'h001bf529; // dw 0x001bf529
mem[2226] = 'hf402002b; // dw 0xf402002b
mem[2227] = 'h002cff49; // dw 0x002cff49
mem[2228] = 'h00000000; // dw 0x00000000
mem[2229] = 'h00000000; // dw 0x00000000
mem[2230] = 'h00000000; // dw 0x00000000
mem[2231] = 'h00000000; // dw 0x00000000
mem[2232] = 'hfff2ffe7; // dw 0xfff2ffe7
mem[2233] = 'h00380000; // dw 0x00380000
mem[2234] = 'hff9d0000; // dw 0xff9d0000
mem[2235] = 'hff8b0002; // dw 0xff8b0002
mem[2236] = 'h00000000; // dw 0x00000000
mem[2237] = 'h00000000; // dw 0x00000000
mem[2238] = 'h00000000; // dw 0x00000000
mem[2239] = 'h00000000; // dw 0x00000000
mem[2240] = 'h0634f8cf; // dw 0x0634f8cf
mem[2241] = 'hf90aff61; // dw 0xf90aff61
mem[2242] = 'hfcec0313; // dw 0xfcec0313
mem[2243] = 'h000001fc; // dw 0x000001fc
mem[2244] = 'h00000000; // dw 0x00000000
mem[2245] = 'h00000000; // dw 0x00000000
mem[2246] = 'h00000000; // dw 0x00000000
mem[2247] = 'h00000000; // dw 0x00000000
mem[2248] = 'h017af50e; // dw 0x017af50e
mem[2249] = 'h05310000; // dw 0x05310000
mem[2250] = 'hf986f6f5; // dw 0xf986f6f5
mem[2251] = 'h0005fb5b; // dw 0x0005fb5b
mem[2252] = 'h00000000; // dw 0x00000000
mem[2253] = 'h00000000; // dw 0x00000000
mem[2254] = 'h00000000; // dw 0x00000000
mem[2255] = 'h00000000; // dw 0x00000000
mem[2256] = 'hf871054f; // dw 0xf871054f
mem[2257] = 'h02450000; // dw 0x02450000
mem[2258] = 'h079af899; // dw 0x079af899
mem[2259] = 'h00040b7a; // dw 0x00040b7a
mem[2260] = 'h00000000; // dw 0x00000000
mem[2261] = 'h00000000; // dw 0x00000000
mem[2262] = 'h00000000; // dw 0x00000000
mem[2263] = 'h00000000; // dw 0x00000000
mem[2264] = 'h046a066e; // dw 0x046a066e
mem[2265] = 'h004101c4; // dw 0x004101c4
mem[2266] = 'h00000000; // dw 0x00000000
mem[2267] = 'h00000000; // dw 0x00000000
mem[2268] = 'h00000000; // dw 0x00000000
mem[2269] = 'h00000000; // dw 0x00000000
mem[2270] = 'h00000000; // dw 0x00000000
mem[2271] = 'h00000000; // dw 0x00000000
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
