label1:
ANDI x1, x0, label3
ANDI x1, x0, label2+8
label2:
SW x15, x0, label1+4
SB x15, x0, label2-4
label3:

AUIPC x1, data+32
AUIPC x1, end-32

ORG 0x1000
data:
DAT 1, 2, 3, 4
DAT 5, 6, 7, 8
DAT 9, 10, 11, 12
DAT 13, 14, 15, 16
end: