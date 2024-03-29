  org 0x200
start:
  # gp=0x2000
  lui gp, 2
  # Load matrices and bias vectors

  lm m0, gp, l0_0-data
  lm m1, gp, l0_1-data
  lm m2, gp, l0_2-data
  lm m3, gp, l0_3-data

  lui t1, 3 # t1 = 0x3000
  lm m4, t1, l1-data_1
  lm m5, t1, l2-data_1
  lm m6, t1, l3-data_1

  lv v1, t1, b0-data_1
  lv v2, t1, b1-data_1
  lv v3, t1, b2-data_1
  lv v4, t1, b3-data_1

  # Load scale and mean vectors
  lv v20, t1, s0-data_1
  lv v21, t1, s1-data_1
  lv v22, t1, s2-data_1
  lv v23, t1, s3-data_1

  lv v24, t1, m0-data_1
  lv v25, t1, m1-data_1
  lv v26, t1, m2-data_1
  lv v27, t1, m3-data_1

  # ========================= UART READ
uart_start:
  # Put 0xCC on hex display.
  addi a0, zero, 204
  sb a0, zero, -16

  addi a0, zero, 0
  addi a1, zero, 16
  addi t2, zero, in_img
uart_loop:
  lbu a2, zero, -2               # Read word from UART
  lbu a3, zero, -2
  lbu a4, zero, -2
  lbu a5, zero, -2

  slli a2, a2, 24                # Combine bytes into single reg
  slli a3, a3, 16
  slli a4, a4, 8
  add a2, a2, a3
  add a2, a2, a4
  add a2, a2, a5
  sw a2, t2, 0

  addi a0, a0, 1                # Increment counters
  addi t2, t2, 4
  bltu a0, a1, uart_loop

  addi a0, zero, 0               # Put 0x00 on hex display
  sb a0, zero, -16

  # ========================= DATA LOAD
  # Load and preprocess input vectors
  addi a0, zero, in_img
  jal unpack
  addv v10, v10, v24
  mulv v5, v10, v20

  addi a0, zero, in_img + 16
  jal unpack
  addv v10, v10, v25
  mulv v6, v10, v21

  addi a0, zero, in_img + 32
  jal unpack
  addv v10, v10, v26
  mulv v7, v10, v22

  addi a0, zero, in_img + 48
  jal unpack
  addv v10, v10, v27
  mulv v8, v10, v23

  # ========================= FEED FORWARD
  # Apply layer 0
  mulmv v10, m0, v5
  mulmv v11, m1, v6
  addv v10, v10, v11
  mulmv v11, m2, v7
  addv v10, v10, v11
  mulmv v11, m3, v8
  addv v10, v10, v11

  addv v10, v10, v1 # bias
  ltv v10, v0       # relu
  movmv v10, v0

  # Apply layer 1
  mulmv v10, m4, v10

  addv v10, v10, v2 # bias
  ltv v10, v0       # relu
  movmv v10, v0

  # Apply layer 2
  mulmv v10, m5, v10

  addv v10, v10, v3 # bias
  ltv v10, v0       # relu
  movmv v10, v0

  # Apply layer 3
  mulmv v10, m6, v10

  addv v10, v10, v4 # bias
  ltv v10, v0       # relu
  movmv v10, v0

  jal check_result

  # Write predicted digit to hex display and UART
  sb a0, zero, -16
  sb a0, zero, -1

  j uart_start

check_result:
  addi sp, sp, -32   # allocate space for result vector
  sv v10, sp, 0
  mv t4, zero        # t4 <- loop counter
  addi t5, zero, -1  # t5 <- maximal element
  mv a0, zero        # a0 <- maximal index
  addi a2, zero, 10  # a2 <- element count of output vector
  mv a3, sp          # a3 <- output vector pointer

res_loop:
  bge t4, a2, res_ret
  lh a4, a3, 0
  blt a4, t5, res_skip

  mv t5, a4
  mv a0, t4
res_skip:
  addi t4, t4, 1
  addi a3, a3, 2
  j res_loop

res_ret:
  addi sp, sp, 32
  ret


# a0 = input bytes pointer
# returns the loaded vector in v10
unpack:
  addi sp, sp, -32   # reserve space for result vector
  mv a1, sp
  mv t2, zero        # t2 <- loop counter
  addi t3, zero, 16  # t3 <- loop limit

unpack_loop:
  bge t2, t3, unpack_ret

  lbu t4, a0, 0
  slli t4, t4, 3
  sh t4, a1, 0

  addi t2, t2, 1
  addi a0, a0, 1
  addi a1, a1, 2
  j unpack_loop

unpack_ret:
  lv v10, sp, 0
  addi sp, sp, 32
  ret

in_img:
dat 0, 0, 0, 0, 0, 0, 0, 0
dat 0, 0, 0, 0, 0, 0, 0, 0

org 0x2000
data:

l0_0:
dat 0xfe9901e3, 0x026bfbb9, 0xfe380533, 0x0236ffe0, 0xfcc4fe6a, 0x004bfd05, 0xfddcfdee, 0xfe3a0067
dat 0x0215fec2, 0xff70fd7b, 0x02b3ff88, 0xfdcf024e, 0x003efdff, 0xfde2fa79, 0x00bd03ba, 0xfe0bfcd9
dat 0xfe49ff06, 0x027804ec, 0xfe5401d0, 0xfc81fc84, 0x04bdff70, 0x023e004f, 0x01a9091b, 0xfcf0fcec
dat 0xfe32fdec, 0xff8dfcf2, 0xf870ff1b, 0x0000fa99, 0xfd7effc2, 0x0091fc91, 0xfebefe05, 0xfe53fe47
dat 0xfcd6fed1, 0x038dfe71, 0x0058ff4d, 0xfe67fc36, 0xfce100d8, 0xfe5101be, 0x013cfc92, 0xff65ff4b
dat 0x01de00e0, 0x0126ffa8, 0xfe35007d, 0x007c0441, 0x00cfff10, 0x0132fe18, 0x002d04d3, 0x0304ffed
dat 0x017501e5, 0x010e004d, 0x0313fd85, 0x018303b0, 0x0041fe1d, 0x0298fd9c, 0x006f08ee, 0x012cff55
dat 0x0229fde8, 0xff2105bc, 0x035f0247, 0xff1304cf, 0xfeb6ffb8, 0x03a6003f, 0xfddc03cf, 0xffa4fc23
dat 0x0037fe84, 0x029cff0b, 0xfe610045, 0x00edfe32, 0xfe62feb9, 0xffeffe05, 0xf8f0014d, 0xffa3fd9f
dat 0xfd20000d, 0x00e6fcdb, 0x0037fcf8, 0xfe4dfecd, 0x0090fdd7, 0x00a7fd28, 0xfc37019b, 0x01c700d0
dat 0x01edfedc, 0x0449ff17, 0xff9a059b, 0xffc6fff7, 0xff06ff1e, 0x015cffad, 0x00320356, 0xfe080044
dat 0x00b50170, 0xfed70585, 0x03d100c1, 0xfe2706c1, 0xfe890230, 0x031efeef, 0xfabd01a9, 0xfdcd010a
dat 0xfdef0110, 0xfcd3fc59, 0xff9b0282, 0xff3fff97, 0xfc86015a, 0xff7efe33, 0xfddefb1e, 0xfec100d3
dat 0xff35fe5f, 0xfc7bfff6, 0x00fbfd9c, 0x0005fe34, 0xfd9eff67, 0xfe1ffd19, 0xfdc6fece, 0x01a6fef7
dat 0xfe18ffe9, 0xfdf9fe0a, 0xfc3c0083, 0x02670120, 0x00ffff66, 0x0044006e, 0xfe5ffd0f, 0x00fb012d
dat 0xff61ff78, 0xfffc0073, 0xfd7efe9b, 0x01adff30, 0x0158ffaa, 0x010eff92, 0xfdbbfc5c, 0xfd99fe49
l0_1:
dat 0x0179ff6e, 0x02c40319, 0x0b02025f, 0xffd5ffd9, 0xfff5ff44, 0x07830429, 0x076e0450, 0xff700305
dat 0xff690027, 0x026afc1b, 0xfdef067a, 0x004bfc79, 0xfedefec3, 0x0077fcbc, 0xfef200a7, 0xff05ffa6
dat 0xfde10017, 0x00e3ff70, 0x0312ff0c, 0xfe4fff3b, 0xfc08fe37, 0xf860f9b1, 0x01c3f6d5, 0xfe33017d
dat 0xff01fcda, 0x01a404d5, 0xfef0fb3b, 0xfe8e01d9, 0x03d702a1, 0xff650313, 0xff83f926, 0x027c0443
dat 0x01090260, 0x039601e1, 0xfe9dfd9e, 0xff3b0018, 0xff3cfed8, 0x08d900b1, 0x006c0559, 0xffeefacf
dat 0xfd7eff16, 0x00b9000b, 0x01a9fe8d, 0x0024004e, 0xfbf0fd6a, 0x032502eb, 0x0154008e, 0xfeb1008b
dat 0xfeb500e0, 0xff34fb69, 0x029a03ca, 0xfe44fedc, 0xff0c05fe, 0xfce302b2, 0x05e60023, 0x01090392
dat 0x0027fb91, 0x03c70335, 0xfad9f62c, 0x007ff9d1, 0x023df9b5, 0xfd5a031b, 0xff87fa33, 0xfe54ff4f
dat 0xfdc8ff63, 0x01b6fe12, 0xf9b001bd, 0x0268fefc, 0x0117fd23, 0xffd00335, 0x009002fd, 0x024c0a22
dat 0xfb980198, 0x038f0166, 0xfa6a01fe, 0x00c402ff, 0x020d01bf, 0xff9e0234, 0x001a00dc, 0x00900382
dat 0x00a0010e, 0xf94ef83e, 0xfd3506cd, 0x01c6febf, 0xfe17ff4f, 0xfd77fb20, 0xfd20ff34, 0xfe400006
dat 0xfca6005c, 0x003a00e1, 0xf7a2fa74, 0xff4ffab8, 0x0013fee1, 0x004fff9f, 0xfe790017, 0x005500ce
dat 0xff2b01f0, 0xfdff0315, 0xfcbdfc77, 0xfdca0197, 0xfe3bff11, 0x003aff1f, 0xff2a0303, 0xfe0dfbb8
dat 0xff220056, 0x0213050e, 0xfdbb00c5, 0xffdaff96, 0x057cfed2, 0xfec00160, 0x02e2fcef, 0x03970421
dat 0xfb620022, 0xff71fe27, 0xfa52fb7f, 0x0188fda6, 0xfad6fee1, 0xfb200127, 0xfd5afc12, 0x019cff33
dat 0xff940050, 0xfdac01b8, 0xfd46fe22, 0x01de02a1, 0xfea1fdf9, 0xfdd0ffe8, 0xff03fc67, 0x014b01d9
l0_2:
dat 0xfbe20148, 0x02f80369, 0x00dcf8e2, 0xff72fff3, 0xfe230021, 0xf700fb0f, 0xfda3fcb3, 0x0190ffaa
dat 0xfeb6fe26, 0xfb24feee, 0x027e0238, 0x020602f4, 0x0076fecc, 0xfddbfb6a, 0x04a3034c, 0x0049fe5c
dat 0xfea7ffc1, 0xf967f887, 0xfc8af9b9, 0xfdefff7a, 0xfe87ff65, 0x035dff3e, 0xfbe6f921, 0x0123fd21
dat 0x02e801b7, 0xfc720412, 0x01a0fb97, 0xfefd0155, 0x0298fdeb, 0xfdc50828, 0x00970399, 0x00b10137
dat 0x018c00aa, 0x08070188, 0xfa92017c, 0x020cfaee, 0x00abff97, 0x068809e5, 0x010f0240, 0xfeb0fbec
dat 0xfec10030, 0xff90fe97, 0x0012fba4, 0x01b5ff2e, 0xffb5fe49, 0xfb14fe5f, 0xff23fed5, 0xfe1b00f0
dat 0xffa701f9, 0xff6a01e5, 0x065a02c6, 0xff5602e3, 0xfd9b0336, 0x043cfeee, 0x003d0191, 0xfdf7feee
dat 0x011a016c, 0xfaf90460, 0x017ef95d, 0x00470356, 0xfcb6ff74, 0xfd81fcef, 0x04d8ff0e, 0x0050ff7d
dat 0x037b010f, 0xffbd045f, 0x059805cd, 0xff230369, 0x06200001, 0x066bfc3d, 0xff9d06ef, 0xfdf7fa12
dat 0x0236fed3, 0xff6a018a, 0x028bfe77, 0xfeba00d9, 0x02500046, 0x08840382, 0xfa40f8ac, 0x0125fef4
dat 0xff4f0222, 0xfcbf01ab, 0xff8f013e, 0xfe5403c7, 0x012ffff0, 0xf770f8fe, 0x03e10062, 0xfea304e7
dat 0x00df01fd, 0xfc600156, 0x0517ff82, 0xff610505, 0xfc8101f0, 0xfbd9fa4b, 0x00d50078, 0xfec8ff1e
dat 0xfd00008a, 0x024ffdf5, 0xffb704b2, 0xfed90126, 0x00edfec1, 0xfdb50204, 0x0630fbe6, 0x02520786
dat 0x03a3ff80, 0xfc9d0047, 0x027fff75, 0x0017004a, 0x037d01e2, 0x02ea022b, 0x01df0208, 0xff27004f
dat 0x002cff9a, 0xfe25029c, 0x037e00bb, 0xfec104b9, 0xff16ff87, 0x01a90300, 0x023506cc, 0x021d07cb
dat 0x023dfe13, 0xfd2d00a2, 0xfffbfea5, 0xff0effe9, 0x03cdfe0d, 0xff6400f6, 0xff6900b4, 0x0064febe
l0_3:
dat 0x042c011f, 0xfeb4f8a6, 0xff69fd9a, 0x00550014, 0xfe7bfe1b, 0xfe6cff0d, 0x02640129, 0x02d402c6
dat 0x00370093, 0xfca0fddd, 0x02340204, 0xfffffd7c, 0xff810081, 0xff03010d, 0x00ed0097, 0x0370fec9
dat 0xfd4e00c0, 0x081e003e, 0x05e3064d, 0x00c000e7, 0x00460119, 0x0457033d, 0x03d6fe70, 0x01a205fd
dat 0xfe7fffdd, 0x027b046a, 0x00af02da, 0xfe690007, 0xff57ffe2, 0x00d1fbce, 0xff510051, 0xff7dfd69
dat 0xfdeffd26, 0xfe7004b5, 0x0242fd1d, 0x006ffa83, 0xfe33ff44, 0x04b7f8b6, 0xff0b06e1, 0x04a2fe76
dat 0xfef20134, 0xfd5e002f, 0xff2a007c, 0x014dfd36, 0xffff010a, 0x0078ffe5, 0xfc5e01a3, 0xfeabffc4
dat 0xfd16ff55, 0x0034fd20, 0xfa10f928, 0xfe89fdfb, 0xff9d001d, 0xfa2a0139, 0xfc50f8a4, 0xffc4fd02
dat 0xffde011a, 0xffff008d, 0x001800d2, 0xfe42fe13, 0x031efff6, 0x02be0620, 0xfc60026a, 0xfeb3ff18
dat 0x0088fedd, 0x0508fb3e, 0xfbafff19, 0x0508fd8f, 0xfe98fea3, 0xff09fff7, 0x0081fe6b, 0x05b6038d
dat 0x0061ff3b, 0x0918fe2c, 0x018e047e, 0xffc10157, 0xff320274, 0xffc8fc8f, 0x067c032c, 0x0026065d
dat 0xffb501ec, 0xfd2bfc7f, 0xffc00368, 0xff6f0505, 0x0139fe1c, 0x01d602cb, 0x005400b3, 0xfead024b
dat 0xffa101f3, 0xfe1afda2, 0xffb700ca, 0x0040ffdf, 0x0093005d, 0x016a06ae, 0xfe720032, 0xfe38fe68
dat 0xff50fedf, 0x007c0070, 0x076cfb35, 0xfd3903b6, 0xfd770167, 0xfd44fd29, 0x058a031f, 0xfcbc015c
dat 0x002c0221, 0xfebefee4, 0x004800c0, 0xff570100, 0x0028008a, 0xfb80fc3b, 0x016a00a8, 0xff0b012f
dat 0xfda2fe52, 0x039103e2, 0xfd3ffd0e, 0xfda20335, 0xfd6fff0e, 0xffbdff93, 0x0065fe28, 0xff83ff17
dat 0x00f800ec, 0x013902a6, 0x020e01ad, 0x0085fee6, 0x01320013, 0x010a027a, 0x003effd6, 0xff92022c

org 0x2800

b0:
dat 0xfdaeffff, 0x010b026e, 0x011403bc, 0x01de0041, 0x0372feed, 0xfe61ffb5, 0xfd6a0260, 0xfbc70295
l1:
dat 0xfeaefbac, 0xfc2e0773, 0xfdfefe69, 0xfce7fd21, 0x0424ff07, 0xfe4f0664, 0x01530530, 0x014afae5
dat 0xfeceff4e, 0x07620347, 0xfff4faa1, 0x04d50052, 0xffda07d4, 0x0686ff5f, 0x02c6fdd6, 0x006f0757
dat 0xfc7402ea, 0xfdaefe44, 0xfe19fc97, 0xfdb2ff69, 0x00e6fd3f, 0xfe570100, 0xfef503ca, 0xffd1ff39
dat 0x0575f8e4, 0x0001fca1, 0x014e0525, 0xff41fa58, 0xfa6efd14, 0xfffe0b68, 0xfde20338, 0xfd4ffce7
dat 0x0900029f, 0xf8a206df, 0xfced04cb, 0xfce6feeb, 0x05c20465, 0xfd2a004d, 0x02abf8b8, 0x02fcf986
dat 0x03820164, 0xf926fe71, 0x0367035e, 0x04b40762, 0xfc9b053e, 0x02fe04e6, 0xfc6dfd39, 0xfe7202e1
dat 0xfde80392, 0x01f7004e, 0xfced02c6, 0xffe4ff36, 0x04cdffe8, 0xff6cfd58, 0xfeb5fc92, 0x00db01ba
dat 0x0160fd7a, 0xfcf3fdc6, 0x008fff24, 0xfcc802e3, 0xfeef0121, 0xff57fefe, 0xfbedfd06, 0xfcd601c0
dat 0x05b601e9, 0x00d0fab1, 0xfe6705e4, 0xfd6f0186, 0x07390032, 0xfe93fa32, 0x04fe01e3, 0x03d2fc82
dat 0x0497ff2c, 0xfe54fd35, 0xff80fb77, 0xfdbf030a, 0xfe1901c5, 0xfe5cff18, 0xfd6504e5, 0xfe090395
dat 0x00c8fe15, 0x0292fda4, 0xfc59011d, 0xfc13fa6c, 0x01e3fe20, 0x017a0402, 0xffaf03f9, 0x019705b6
dat 0xfddcfeab, 0xfec9fec6, 0xfcf103a6, 0xfbb8fc4f, 0xff7bfb73, 0xfdebfd51, 0x025a0687, 0xff8003e8
dat 0xff960362, 0xf8c5fafa, 0x009d0402, 0x0714f8be, 0xfb25ff66, 0x0733fe26, 0xfe9f0498, 0xfa5900a4
dat 0xfbe7fbae, 0x02880190, 0x01d60b46, 0xfe02fa73, 0x02b8ff86, 0xfcf4fd6e, 0xff2d029c, 0xffca0054
dat 0xfd5302b5, 0x04d508ce, 0x01210273, 0x01daff0f, 0x03b9f88d, 0xff08fe3d, 0x02ea0488, 0xff6500f1
dat 0xf8e408f6, 0xffef0629, 0x015201e8, 0x0256fcd0, 0x01a7f8e9, 0x015301df, 0x004dfd22, 0xff4bfab6
b1:
dat 0xfb370149, 0x06a3029c, 0xfe9e007a, 0x0136fc2d, 0x004005ae, 0xfe7ffb28, 0x069602f1, 0x023cfeae

org 0x3000
data_1:

l2:
dat 0x0086ffa1, 0xfdcd0351, 0x0427fe4c, 0x03db02af, 0x00b6ff2d, 0xfdcffe25, 0xfdaaff44, 0xfcbc04e5
dat 0xff21066c, 0xfc3ffd94, 0xfc980941, 0xfdc5ff4a, 0xfeb801cc, 0xfba2fbc3, 0x015efd3b, 0xfe32ffc5
dat 0xfde9fe0f, 0x021500c1, 0xfff4fe37, 0x00e9ff8b, 0x0138ff48, 0x01b8feda, 0x01320080, 0xfa83fc4d
dat 0x0697fe0c, 0x02c4000a, 0xfbf8f981, 0x01b50166, 0x004bfb99, 0x089106de, 0x040ffa80, 0xfee4097e
dat 0xfbad04ea, 0x0e6802ba, 0x03a8fe78, 0x0124fe52, 0x019ffa2c, 0x001bfec8, 0x00560345, 0x0301fcda
dat 0xff46fd67, 0x0005fc67, 0xfea7fc6e, 0xfed9fe48, 0x0188fc3b, 0x01c80333, 0x00bbff5c, 0x0108011d
dat 0x01fcfa02, 0x0351ff93, 0xfebd0448, 0xfd6502be, 0x024a0288, 0xff6dff1d, 0x08ab09e3, 0xfea7fe6e
dat 0x056afd82, 0xfd5eff0d, 0x04f3034c, 0x016bff70, 0x01bd07f7, 0x00310477, 0x026afe8a, 0xf1def7f9
dat 0x0746ffdc, 0xfdffff2d, 0xfc1c0015, 0xfdc80232, 0xfdb7fecb, 0xfd9afda3, 0xfe34021c, 0x058702a0
dat 0x0436fd3a, 0xfaedfe22, 0x0768fc30, 0xfea20058, 0x05dcf870, 0xfbb2fd74, 0xfdd309df, 0x00e500e8
dat 0xf5a5fe8b, 0xfa1f0477, 0x06f6065c, 0x01fa0269, 0x041d00f1, 0xfbc5ff35, 0xf7b6018e, 0x08b7fd78
dat 0x03560710, 0xffc50087, 0xf9ec03e9, 0x013efeb7, 0xfd9d07e9, 0xffadfea0, 0x0375fd3e, 0x00ea048d
dat 0xfb4c00c5, 0x005bfd12, 0xfb060075, 0x0018ffe3, 0xfff304df, 0x04eeff9f, 0x0581008a, 0xfe4a0155
dat 0xfea2024b, 0xfd410334, 0x0394fce5, 0x021c027f, 0x04ebfc0f, 0xfc6300f2, 0xfd2efcb1, 0xfea4fdeb
dat 0xfdfa02d0, 0xfc1e0185, 0xfd93009e, 0xfd9cfb50, 0x007c034c, 0x00aefd81, 0xffe60a6a, 0x08a600ef
dat 0xfdc7fd57, 0x0141005f, 0xfd11fcba, 0xfd6b01e3, 0x00df00d3, 0x001ffeca, 0xffe5015d, 0x0156fdec
b2:
dat 0xfc81014a, 0x00fafd48, 0xfc3b06ca, 0xfcbffd79, 0xfffdfb72, 0xfe20fce3, 0x03610180, 0xfbed088d
l3:
dat 0xff0b0246, 0x0567fdbe, 0xffedfbc2, 0xfa24fbbb, 0x0127071e, 0x0157f911, 0x00770037, 0xfc68f9a9
dat 0x083401d7, 0xf7df038f, 0xff90f837, 0x02010588, 0xfb13fcd4, 0x00710944, 0xfdd202af, 0x0188fc7d
dat 0x089efc7c, 0xf7e1fd87, 0xfedd0001, 0x00aef4b6, 0xfe3f02aa, 0x090dfaef, 0x035f00ea, 0x03230151
dat 0xfe09fd73, 0x03a80129, 0xfc221095, 0xfa14fa7d, 0xfb9efaa8, 0xfd98fe1a, 0x026cfcdc, 0x0030fed2
dat 0xfd49003b, 0xfd2100c0, 0xffe2ff4c, 0x1077fe89, 0xfee60507, 0xffdcfa53, 0xfdd9fdfc, 0xfc8efc38
dat 0xfce9fc9d, 0x030d0101, 0x009a0046, 0x027b056d, 0x09f90322, 0xf69b0185, 0xfc6ffc50, 0x026104f5
dat 0x007ffdef, 0x078202b3, 0x03d1fd5f, 0x02b8feb3, 0x0021fdfc, 0x0122fbe3, 0xff080299, 0xfd8ef863
dat 0xfdd90526, 0x01e50112, 0xff1a010b, 0x0654fce5, 0x079efbe0, 0xf7a202de, 0x065efdcf, 0x020afef2
dat 0xfe1cfc7b, 0xfd5b02d1, 0x00d101cf, 0xf7870484, 0xfb85fd30, 0x00e9fd48, 0x0033047b, 0x00a9079e
dat 0xfd4bffa6, 0x01adff40, 0xfefe01b0, 0xfb78fb64, 0x00c2021e, 0xfb9b0fbf, 0xffd8fce6, 0xfe630b2a
b3:
dat 0xf982f9d5, 0x0a9c0358, 0xf6d5f63d, 0x06a0fe68, 0x06130a8c, 0x00000000, 0x00000000, 0x00000000

m0:
dat 0xffd90000, 0xfa15fd66, 0xfd1cfa13, 0xffefff52, 0xff01ffff, 0xfa03facf, 0xfbe9fadc, 0xfff2ff14
m1:
dat 0xfeb30000, 0xfc81fb0c, 0xfc19fc73, 0xfffaff1b, 0xfec40000, 0xfb97fb74, 0xfc39fb09, 0x0000fed7
m2:
dat 0xfed50000, 0xfb77fc2b, 0xfba1fad9, 0x0000fe8c, 0xff35ffff, 0xfc63fc8f, 0xfbe2fc2a, 0xfffdfe46
m3:
dat 0xffa6ffff, 0xfb3bfc3f, 0xfb9ffb4b, 0xffe6fe23, 0xffdc0000, 0xf9f5fd39, 0xfc9efa18, 0xffd1fef7

s0:
dat 0x8d220800, 0x1e221aed, 0x16981ddd, 0x7b6c267f, 0x280f4ee1, 0x2031179e, 0x15271ac5, 0x9aa623b3
s1:
dat 0x23cd04e5, 0x16111680, 0x14a914bb, 0x23ec2747, 0x28b1fef0, 0x15c414ad, 0x15cd14d0, 0x9c0d22bb
s2:
dat 0x24ca0800, 0x146d143e, 0x15cf1594, 0x08002432, 0x2af071e0, 0x13e11395, 0x167b1474, 0xa0921d90
s3:
dat 0x495372f1, 0x187f16af, 0x153b1826, 0x82111a07, 0x890a3390, 0x1d441917, 0x15b319f3, 0x44d51f4d
