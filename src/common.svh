`ifndef COMMON
 `define COMMON

  // Clock Rate
 `define CLK_RATE 25_000_000

 // Sizes
 `define DATA_WIDTH 32
 `define BRAM_WIDTH 14
 `define TX_FIFO_DEPTH 4
 `define VEC_DIM 16

 // OPCODE definitions
 `define LUI      7'b0110111
 `define AUIPC    7'b0010111
 `define JAL      7'b1101111
 `define JALR     7'b1100111
 `define BRANCH   7'b1100011
 `define LOAD     7'b0000011
 `define STORE    7'b0100011
 `define MISC_MEM 7'b0001111
 `define SYSTEM   7'b1110011
 `define OP_REG   7'b0110011
 `define OP_IMM   7'b0010011
 // Custom OPCODEs
 `define OP_VEC_I 7'b0001011
 `define OP_VEC_R 7'b0101011
 `define NOP      7'b0000000

 // BRANCH types
 `define BEQ  3'b000
 `define BNE  3'b001
 `define BLT  3'b100
 `define BGE  3'b101
 `define BLTU 3'b110
 `define BGEU 3'b111

 // LOAD types
 `define LB  3'b000
 `define LH  3'b001
 `define LW  3'b010
 `define LBU 3'b100
 `define LHU 3'b101

 // STORE types
 `define SB 3'b000
 `define SH 3'b001
 `define SW 3'b010

 // OP_IMM types
 `define ADDI  3'b000
 `define SLTI  3'b010
 `define SLTIU 3'b011
 `define XORI  3'b100
 `define ORI   3'b110
 `define ANDI  3'b111
 `define SLLI  3'b001
 `define SRLI  3'b101 // TO DIFFER CHECK immediate
 `define SRAI  3'b101

 // OP types
 `define ADD  3'b000 // TO DIFFER CHECK funct7
 `define SUB  3'b000
 `define SLL  3'b001
 `define SLT  3'b010
 `define SLTU 3'b011
 `define XOR  3'b100
 `define SRL  3'b101 // TO DIFFER CHECK funct7
 `define SRA  3'b101
 `define OR   3'b110
 `define AND  3'b111

 // MISC-MEM types
 `define FENCE 3'b000
 `define FENCE_I 3'b001

 // SYSTEM types
 `define ECALL  3'b000 // TO DIFFER CHECK funct7
 `define EBREAK 3'b000
 `define CSRRW  3'b001
 `define CSRRS  3'b010
 `define CSRRC  3'b011
 `define CSRRWI 3'b101
 `define CSRRSI 3'b110
 `define CSRRCI 3'b111

// ALU
 `define ALU_ADD  4'h1
 `define ALU_SUB  4'h2
 `define ALU_SLT  4'h3
 `define ALU_SLTU 4'h4
 `define ALU_OR   4'h5
 `define ALU_XOR  4'h6
 `define ALU_AND  4'h7
 `define ALU_SLL  4'h8
 `define ALU_SRL  4'h9
 `define ALU_SRA  4'hA

// Vector immediate instructions
 `define VECI_LV 3'h1 // Load vector
 `define VECI_SV 3'h2 // Store vector
 `define VECI_LM 3'h3 // Load matrix

// Vector register instructions
 `define VECR_DOTV  7'h1 // Dot product of two vectors
 `define VECR_MULV  7'h2 // Component-wise product of two vectors
 `define VECR_CMPV  7'h3 // Vector comparsion
 `define VECR_CMPMV 7'h5 // Vector comparsion of masked elements
 `define VECR_MOVV  7'hA // Vector move
 `define VECR_MOVMV 7'hB // Masked vector move
 `define VECR_MULMV 7'hC // Matrix multiplication
 `define VECR_ADDV  7'hD // Vector elementwise addition

// Vector comparsion types, encoded in funct3
 `define VEC_EQ 3'h0
 `define VEC_NE 3'h1
 `define VEC_LT 3'h2
 `define VEC_LE 3'h3
 `define VEC_GT 3'h4
 `define VEC_GE 3'h5

// UART
 `define UART_BAUD_RATE 9600
`endif
