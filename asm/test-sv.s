org 0x200
start:
  lw x1, x0, var
  lv v1, x0, test_vec
  sv v1, x0, res_vec
  lw x2, x0, var

  addi x3, x0, 0x22
  beq x2, x1, print
  addi x3, x0, 0x11

  # 0x22 if sv didn't overwrite var
  # 0x11 otherwise
print:
  addi x1, x0, -16
  sb x3, x1, 0
halt:
  jal x0, halt

res_vec:
  dat 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
var:
  dat 0xdeadbeef # this shouldn't be overwriten
test_vec:
  dat 0x00112233, 0x44556677, 0x8899AABB, 0xCCDDEEFF, 0xFFEEDDCC, 0xBBAA9988, 0x77665544, 0x33221100
