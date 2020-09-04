start:
  # x1=0x2000
  lui x1, 2

  # Layer 0
  lv v2, x1, l0-data+0
  lv v3, x1, l0-data+32
  lv v4, x1, l0-data+64
  lv v5, x1, l0-data+96
  lv v6, x1, l0-data+128
  lv v7, x1, l0-data+160
  lv v8, x1, l0-data+192
  lv v9, x1, l0-data+224

  # Layer 1
  lv v10, x1, l1-data+0
  lv v12, x1, l1-data+64
  lv v11, x1, l1-data+32
  lv v13, x1, l1-data+96
  lv v14, x1, l1-data+128
  lv v15, x1, l1-data+160
  lv v16, x1, l1-data+192
  lv v17, x1, l1-data+224

  # Layer 2
  lv v18, x1, l2-data+0
  lv v19, x1, l2-data+32
  lv v20, x1, l2-data+64
  lv v21, x1, l2-data+96
  lv v22, x1, l2-data+128
  lv v23, x1, l2-data+160
  lv v24, x1, l2-data+192
  lv v25, x1, l2-data+224

  # Layer 3
  lv v26, x1, l3-data+0
  lv v27, x1, l3-data+32
  lv v28, x1, l3-data+64

  addi x2, x1, iris_x - data # x2 <- iris_x pointer
  addi x3, x1, iris_y - data # x2 <- iris_y pointer
  addi x20, x2, 1200 # 150 * 8

loop:
  # Feed forward
  lv v1, x2, 0

  # Input -> Layer 0
  mulmv v1, v2, v1 # MULMV v1=(v2:v9)*v1
  # Bias
  lv v30, x1, b0-data
  addv v1, v1, v30
  # ReLu
  ltv v1, v0
  movmv v1, v0

  # Layer 1 -> Layer 2
  mulmv v1, v10, v1 # MULMV v1=(v10:v17)*v1
  lv v30, x1, b1-data
  addv v1, v1, v30
  # ReLu
  ltv v1, v0
  movmv v1, v0

  # Layer 2 -> Layer 3
  mulmv v1, v18, v1 # MULMV v1=(v18:v25)*v1
  lv v30, x1, b2-data
  addv v1, v1, v30
  # ReLu
  ltv v1, v0
  movmv v1, v0

  # Layer 3 -> Out
  mulmv v1, v26, v1 # MULMV v1=(v26:v28)*v1
  lv v30, x1, b3-data
  addv v1, v1, v30
  # ReLu
  ltv v1, v0
  movmv v1, v0

  lb x10, x3, 0
  jal x31, check_result

  addi x2, x2, 8
  addi x3, x3, 1

  blt x2, x20, loop

  addi x1, x0, -16

  # Write correct result count to hex display
  lw x2, x0, correct_results
  sb x2, x1, 0

halt:
  jal x0, halt

# expected result in x10
check_result:
  sv v1, x0, res_vec
  lui x4, 0  # x4 <- loop counter
  addi x5, x0, -1 # x5 <- maximal element
  lui x6, 0  # x6 <- maximal index
  addi x7, x0, 3
  addi x9, x0, res_vec

res_loop:
  bge x4, x7, res_loop_end
  lh x8, x9, 0
  blt x8, x5, res_skip

  add x5, x0, x8
  add x6, x0, x4
res_skip:
  addi x4, x4, 1
  addi x9, x9, 2
  j res_loop

res_loop_end:
  bne x6, x10, res_ret
  lw x5, x0, correct_results
  addi x5, x5, 1
  sw x5, x0, correct_results

res_ret:
  jr x31, 0

res_vec:
dat 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
correct_results:
dat 0

org 0x2000
data:
l0:
dat 0x04f40c54, 0xfe1ff6ca, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xffff0000, 0x00190102, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x057f01f9, 0xf6f3fb68, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xf7f8f924, 0x02b30819, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x0003ff3c, 0x0000fff8, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xf5c5f7c6, 0x09420587, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xff7900fb, 0x0030ffdf, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xf580fb91, 0x084702b3, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
b0:
dat 0xfaa5054a, 0x07fc0600, 0x064bffe2, 0x0811fd0f, 0x00000000, 0x00000000, 0x00000000, 0x00000000
l1:
dat 0x006bfc7c, 0x07e3fc4b, 0x06adfffd, 0x09390000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x000004ea, 0x068902a6, 0x016e0000, 0x059a0040, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xffd50000, 0x0000ff89, 0xfff80000, 0xfff5ffb2, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x00000a8b, 0xf82b06b3, 0xf7dd0003, 0xfd35fffd, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x000dffd5, 0xffcf0000, 0x00000000, 0xffd6001a, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x00000875, 0xf8bb0732, 0xfbdeffb9, 0xf7b3fffb, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x00020485, 0xfa600751, 0xf61e0055, 0xfab20000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x003604b8, 0x05ea0636, 0xfcc3ffbd, 0xfc8effe8, 0x00000000, 0x00000000, 0x00000000, 0x00000000
b1:
dat 0x05b30838, 0x00b4fd9e, 0x0520fd85, 0x057c0607, 0x00000000, 0x00000000, 0x00000000, 0x00000000
l2:
dat 0x0248fad1, 0x03f80002, 0x040eff76, 0x02a00623, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x02560436, 0xfa3e0000, 0xfb1c0000, 0xfbb2f88d, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xff7a032a, 0x00160030, 0xff9c0001, 0xfcb90036, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x00000000, 0x0000ffc6, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x044a095d, 0xf7cd0000, 0xf85f0000, 0x070bf893, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x00000046, 0x0003fff9, 0xffd70000, 0xffb4ffdd, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xffcbfab9, 0x0453ffb7, 0x06940000, 0x00870379, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x025204f6, 0x08350000, 0x0a250000, 0x06f40798, 0x00000000, 0x00000000, 0x00000000, 0x00000000
b2:
dat 0x03a60167, 0xfd3dfe3e, 0xfb570626, 0x076d002a, 0x00000000, 0x00000000, 0x00000000, 0x00000000
l3:
dat 0xfe7c0290, 0xffb300e0, 0x00f5f7e8, 0x01e10687, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xf4a7fcb6, 0x00000003, 0x0005011e, 0x0421fb2a, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x0f6cf6ad, 0x004afec4, 0x000008ac, 0xfaaaff94, 0x00000000, 0x00000000, 0x00000000, 0x00000000
b3:
dat 0x000f03d9, 0x0000021a, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000

iris_y:
dat 0x00000000
dat 0x00000000
dat 0x00000000
dat 0x00000000
dat 0x00000000
dat 0x00000000
dat 0x00000000
dat 0x00000000
dat 0x00000000
dat 0x00000000
dat 0x00000000
dat 0x00000000
dat 0x00000101
dat 0x01010101
dat 0x01010101
dat 0x01010101
dat 0x01010101
dat 0x01010101
dat 0x01010101
dat 0x01010101
dat 0x01010101
dat 0x01010101
dat 0x01010101
dat 0x01010101
dat 0x01010101
dat 0x02020202
dat 0x02020202
dat 0x02020202
dat 0x02020202
dat 0x02020202
dat 0x02020202
dat 0x02020202
dat 0x02020202
dat 0x02020202
dat 0x02020202
dat 0x02020202
dat 0x02020202
dat 0x02020000

iris_x:
dat 0x02bf0400, 0x00280119
dat 0x02870420, 0x002b012e
dat 0x02b90400, 0x002c011b
dat 0x02a303ea, 0x002c0147
dat 0x02d303ec, 0x00280119
dat 0x02bd03ca, 0x00480131
dat 0x02ce03cb, 0x003f0128
dat 0x02b103f6, 0x00290130
dat 0x029b03f4, 0x002e0142
dat 0x02950415, 0x00150140
dat 0x02be0400, 0x0026011c
dat 0x02b803d7, 0x00290148
dat 0x02950421, 0x00160134
dat 0x02d3040c, 0x00180109
dat 0x02db0425, 0x002500db
dat 0x02ef03cd, 0x00440100
dat 0x02d603ed, 0x004a00f2
dat 0x02b803f6, 0x003c0116
dat 0x02a503f7, 0x0035012f
dat 0x02d703d0, 0x0039011f
dat 0x028b040a, 0x00260145
dat 0x02c403d0, 0x004d011f
dat 0x031003ea, 0x002c00da
dat 0x027e03d9, 0x00610148
dat 0x02a403ba, 0x0028017a
dat 0x02730415, 0x002a014e
dat 0x029e03d9, 0x004f013b
dat 0x02b10400, 0x00270127
dat 0x02ab0414, 0x00280119
dat 0x02a403e0, 0x002a0152
dat 0x028f03f5, 0x002a0152
dat 0x028b040a, 0x004d011f
dat 0x030203d1, 0x0013011a
dat 0x02f903e5, 0x002400fe
dat 0x028f040b, 0x002a013d
dat 0x02ab042b, 0x002b0100
dat 0x02ab0431, 0x002700fe
dat 0x02e103ec, 0x0014011f
dat 0x02b203f4, 0x002e012b
dat 0x02ab0400, 0x0028012d
dat 0x02c603f6, 0x003d0108
dat 0x02310449, 0x0049013d
dat 0x02d003de, 0x002d0125
dat 0x029e03bd, 0x00730132
dat 0x02b703a5, 0x0049015b
dat 0x0287040b, 0x0041012e
dat 0x02d703d0, 0x00260132
dat 0x02b903ea, 0x002c0131
dat 0x02c403f6, 0x0026011f
dat 0x02ab040a, 0x00290122
dat 0x01920370, 0x00b0024f
dat 0x01a40348, 0x00c5024f
dat 0x0183035e, 0x00bb0264
dat 0x0168035c, 0x00cb0271
dat 0x01740360, 0x00c70264
dat 0x01910330, 0x00ba0284
dat 0x01a9032b, 0x00ce025d
dat 0x01a80361, 0x00b10247
dat 0x0182036e, 0x00ad0264
dat 0x01a30327, 0x00d9025d
dat 0x0164037a, 0x00b2026f
dat 0x01a5033c, 0x00d2024d
dat 0x015503a3, 0x009b026d
dat 0x0189033b, 0x00be027d
dat 0x01bb0358, 0x00c70226
dat 0x01970370, 0x00b80242
dat 0x01a50312, 0x00d20277
dat 0x01970369, 0x00970269
dat 0x01390372, 0x00d50280
dat 0x0187036b, 0x00ac0262
dat 0x01a10302, 0x00eb0272
dat 0x01940370, 0x00bb0241
dat 0x01510351, 0x00ca0294
dat 0x0183034c, 0x00a6028a
dat 0x018f0370, 0x00b3024f
dat 0x018f036e, 0x00ba0249
dat 0x016b0371, 0x00b5026e
dat 0x01770345, 0x00d40270
dat 0x018f0339, 0x00ce026b
dat 0x01a00390, 0x00a00230
dat 0x01800370, 0x00b00260
dat 0x0186037e, 0x00a30259
dat 0x01970369, 0x00b5024b
dat 0x0167031e, 0x00d502a6
dat 0x01ab0300, 0x00d50280
dat 0x01c10319, 0x00d30253
dat 0x018d035a, 0x00c0025a
dat 0x01490386, 0x00ba0276
dat 0x01b70333, 0x00be0258
dat 0x0181034f, 0x00c80268
dat 0x01850336, 0x00b30292
dat 0x0197033b, 0x00be0270
dat 0x01880369, 0x00b5025a
dat 0x01960373, 0x00b10247
dat 0x0191033f, 0x00c1026f
dat 0x01b4033c, 0x00ae0262
dat 0x01a5033c, 0x00bd0262
dat 0x01940360, 0x00b50257
dat 0x01b6037d, 0x00c1020d
dat 0x019d0348, 0x00c0025c
dat 0x017502c9, 0x011b02a7
dat 0x016502fe, 0x00fb02a2
dat 0x01530323, 0x00ee029c
dat 0x01660309, 0x00de02b3
dat 0x015f02f9, 0x010102a7
dat 0x013e0326, 0x00df02bc
dat 0x017802e2, 0x010002a6
dat 0x01450331, 0x00c902c1
dat 0x01310331, 0x00db02c3
dat 0x017c02f8, 0x01080284
dat 0x01860318, 0x00f4026e
dat 0x01530324, 0x00ef029a
dat 0x01610320, 0x00f70287
dat 0x01510300, 0x010d02a2
dat 0x016402e2, 0x01310289
dat 0x017d02fa, 0x01120277
dat 0x016e0318, 0x00db029e
dat 0x017d0305, 0x00dd02a1
dat 0x01110329, 0x00f202d5
dat 0x01330344, 0x00d102b9
dat 0x016a030d, 0x01040285
dat 0x017702ee, 0x010c0290
dat 0x012b0335, 0x00d502cb
dat 0x01600336, 0x00eb027f
dat 0x017c0303, 0x00f20290
dat 0x0168032a, 0x00cb02a3
dat 0x0170032e, 0x00ec0276
dat 0x01850317, 0x00e9027b
dat 0x01530308, 0x00fe02a7
dat 0x015d0346, 0x00ba02a3
dat 0x013b0341, 0x00d602ae
dat 0x01830325, 0x00cc028c
dat 0x01510303, 0x010902a3
dat 0x016d0336, 0x00c40299
dat 0x0153031c, 0x00b702da
dat 0x0142033a, 0x00f7028e
dat 0x018902d9, 0x01160288
dat 0x017a030c, 0x00db029e
dat 0x018a0314, 0x00ec0276
dat 0x016b0327, 0x00f60278
dat 0x01650303, 0x01140284
dat 0x016d032c, 0x010f0258
dat 0x016502fe, 0x00fb02a2
dat 0x016802fd, 0x01030298
dat 0x017302f2, 0x01190281
dat 0x0165031e, 0x0112026b
dat 0x01460336, 0x00f8028c
dat 0x0170031d, 0x00f5027e
dat 0x019202de, 0x0110027f
dat 0x018502fd, 0x00e90295

iris_x_end:
dat 0, 0, 0, 0
dat 0, 0, 0, 0
dat 0, 0, 0, 0
dat 0, 0, 0, 0
dat 0, 0, 0, 0
dat 0, 0, 0, 0
dat 0, 0, 0, 0
dat 0, 0, 0, 0
