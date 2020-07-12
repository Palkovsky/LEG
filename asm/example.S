# This program tests BRAM and MMIO transfers
ADDI x14, x0, -1   # 0xFFFFFFFF - UART TX MMIO
# Set x1=0x11223344
LUI x1, 0x49505
ADDI x1, x1, 0x152
# Store x1 under 0x00000100
ORG 0x100
SW x1, 0x100(x0)
# Wait for TX FIFO to have enough space(4 bytes)
ADDI x6, x0, 5
wait_free_buff:
LB x5, 0(x14)
BLTU    x5,    x6, wait_free_buff
# Load word from 0x00000100
LW x2, 0x100(x0)
# Write 1st byte to UART
SB x2, 0(x14)
SRAI x2, x2, 8
# Write 2nd byte to UART
SB x2, 0(x14)
SRAI x2, x2, 8
# Write 3rd byte to UART
SB x2, 0(x14)
SRAI x2, x2, 8
# Write 4th byte to UART
SB x2, 0(x14)
JAL x0, wait_free_buff
SET x5, 22