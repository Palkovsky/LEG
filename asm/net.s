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

  # Feed forward
  lv v1, x1, iris1-data

  # Input -> First layer
  mulmv v1, v2, v1 # MULMV v1=(v2:v17)*v1
  ltv v1, v0
  movmv v1, v0

loop:
  jal x0, loop

org 0x2000
data:
l0:
dat 0x4012690a, 0xd3efc2ec, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xaafb90ff, 0xbe0309fc, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xc5096e0e, 0xedf064f7, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xa5fb4cff, 0x3efc5dfd, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xd5faf302, 0xb20b670e, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x5002bbfd, 0x04fce5fe, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xdd0182f9, 0x02032400, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xe8f97502, 0x04031f10, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
l1:
dat 0xce0262ff, 0xab03f5fa, 0xb0fb0404, 0xd1fed604, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xc1fc7cf1, 0x8e00c0f7, 0x21fe9e0f, 0x3c078ffb, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xe60498f3, 0x94ff38fc, 0x42016202, 0x34fd1bfe, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x57008eff, 0xd704a4fd, 0x75fed2fe, 0x9807e1fe, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xb6ff7cff, 0xd203e8f9, 0x0d01a701, 0x98f9c9ff, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xb101aefb, 0x410494fe, 0xd4ff1e04, 0x450a6ffc, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xe3fdec01, 0xed00ecfb, 0x35fcf9fb, 0x07fc35fe, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xf20225fc, 0xc200e5fd, 0x15fccc00, 0x7ffce4fb, 0x00000000, 0x00000000, 0x00000000, 0x00000000
l2:
dat 0xb0fe7bff, 0x41fd0f03, 0xeffc9f04, 0xa2fc3604, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x8211a2fd, 0xb906130a, 0xb2098503, 0x90fb24fd, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xc4f912fc, 0x9003b5fe, 0xcffdfdfc, 0xffffc3fb, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x31fc37fc, 0x54fe64fe, 0x84f972ff, 0x3503fbff, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x781a2200, 0xdefdd600, 0xc3fd5b04, 0x0cfd10fd, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x7ffc6dfe, 0x61fcde04, 0x0e007b01, 0x66027501, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xc4fdde04, 0x45ff19fe, 0xc10c31fe, 0x030220fe, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0xe6fc58fb, 0xa3fb41fd, 0x35011702, 0x51fb3503, 0x00000000, 0x00000000, 0x00000000, 0x00000000
l3:
dat 0x91dfa2ff, 0x8cfb56ff, 0x8efd68fc, 0xc0fab8fb, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x1411a3fa, 0xdafd55fe, 0x410121fe, 0x65fb430d, 0x00000000, 0x00000000, 0x00000000, 0x00000000
dat 0x690c6602, 0xe2041105, 0x9f050f0a, 0x3afc25fb, 0x00000000, 0x00000000, 0x00000000, 0x00000000
iris1: # Should be class 1
dat 0x00183327, 0x9a01330b, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
iris2: # Should be class 2
dat 0x3313002c, 0xcd08661e, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
iris3: # Should be class 3
dat 0x0018332f, 0x660ecd28, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
