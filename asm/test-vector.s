addi x15, x0, -1 # UART

lv v0, x0, ascii
sv v0, x0, ascii_cpy

lw x1, x0, ascii_cpy
jal x14, send_x1
lw x1, x0, ascii_cpy+4
jal x14, send_x1
lw x1, x0, ascii_cpy+8
jal x14, send_x1
lw x1, x0, ascii_cpy+12
jal x14, send_x1
lw x1, x0, ascii_cpy+16
jal x14, send_x1
lw x1, x0, ascii_cpy+20
jal x14, send_x1
lw x1, x0, ascii_cpy+24
jal x14, send_x1
lw x1, x0, ascii_cpy+28

hang:
    jal x0, hang

send_x1:
    sb x1, x15, 0
    srai x1, x1, 8
    sb x1, x15, 0
    srai x1, x1, 8
    sb x1, x15, 0
    srai x1, x1, 8
    sb x1, x15, 0
    jalr x0, x14, 0

org 0x100
ascii:
#    'A B C D     E F G H     I J K L     M N O P'
dat 0x41424344, 0x45464748, 0x494A4B4C, 0x4D4E4F50
#    'Q R S T     U V W X     Y Z 1 2     3 4 5 6'
dat 0x51525354, 0x55565758, 0x595A3132  0x33343536
ascii_cpy: