`include "common.svh"

module execute (
	input                        i_clk,
	input                        i_rst,

  // Instruction
  input [31:0]                 i_inst,

  // Memory interface
  input [`DATA_WIDTH-1:0]      i_mem_data,
  output reg [31:0]            o_mem_addr = 0,
  output reg                   o_mem_write = 0,
  output reg [`DATA_WIDTH-1:0] o_mem_data = 0,

  // Control unit interface
  input [31:0]                 i_pc,
  output reg                   o_pc_change = 0,
  output reg [31:0]            o_new_pc = 0,
  output reg                   o_ready,
  output reg                   o_invalid_inst = 0
);
   // Control signals
   reg [3:0]                   r_cycle = 0;
   reg                         r_last_cycle = 1;
   wire [3:0]                  w_next_cycle = r_cycle+1;
   assign o_ready = r_last_cycle;

   // RISC-V instruction decoder
   wire [6:0]                 w_opcode = i_inst[6:0];   // R/I/S/U
   wire [4:0]                 w_rd     = i_inst[11:7];  // R/I/U
   wire [2:0]                 w_funct3 = i_inst[14:12]; // R/I/S
   wire [4:0]                 w_rs1    = i_inst[19:15]; // R/I/S
   wire [4:0]                 w_rs2    = i_inst[24:20]; // R/S
   wire [6:0]                 w_funct7 = i_inst[31:25]; // R
   // RISC-V immediates
   wire [11:0]                w_I = i_inst[31:20];
   wire [11:0]                w_S = { i_inst[31:25], i_inst[11:7] };
   wire [11:0]                w_B = { i_inst[31], i_inst[7], i_inst[30:25], i_inst[11:8] };
   wire [19:0]                w_U = i_inst[31:12];
   wire [19:0]                w_J = { i_inst[31], i_inst[19:12], i_inst[20], i_inst[30:21] };
   // Sign extended immediates
   wire [31:0]                w_I_se = { {20{w_I[11]}}, w_I };
   wire [31:0]                w_S_se = { {20{w_S[11]}}, w_S };
   wire [31:0]                w_B_se = { {19{w_B[11]}}, w_B, 1'b0 };
   wire [31:0]                w_J_se = { {11{w_J[19]}}, w_J, 1'b0 };

   // 32 scalar registers
   reg [31:0]                 X[0:31] = '{ 32{32'b0} };

   /*
    * ========= LAST INSTRUCTION CYCLE DETECTION
    * This signal tells user to latch new instruction.
    */
   always_comb begin
      r_last_cycle = (w_next_cycle >= 1);
      if (w_opcode == `LOAD || w_opcode == `STORE) begin
         case (w_funct3)
           `LH, `LHU, `SH: r_last_cycle = (w_next_cycle >= 2);
           `LW, `SW:       r_last_cycle = (w_next_cycle >= 4);
         endcase
      end
   end

   /*
    * ========= MEMORY ACCESS INSTRUCTIONS
    */
   // Memory-related signals
   reg [2:0]                  w_bytes_to_transfer;
   reg                        w_ld_unsigned;
   reg [2:0]                  r_bytes_transfered = 0;
   wire [4:0]                 w_transfer_chunk;

   assign w_transfer_chunk  = (w_bytes_to_transfer-r_bytes_transfered)*8-1;

   task LOAD_SEQ();
      r_bytes_transfered <= r_bytes_transfered+1;
      // If all transfered
      if(r_bytes_transfered+1 == w_bytes_to_transfer) begin
         r_bytes_transfered <= 0;
         // Do either zero-extension or sign-extension
         case (w_bytes_to_transfer)
           1: X[w_rd][31:8]  <= (w_ld_unsigned) ? 24'b0 : { {24{i_mem_data[7]}} };
           2: X[w_rd][31:16] <= (w_ld_unsigned) ? 16'b0 : { {16{i_mem_data[7]}} };
         endcase
      end
      // Copy to register
      X[w_rd][w_transfer_chunk -: 8] <= i_mem_data;
   endtask

   task STORE_SEQ();
      r_bytes_transfered <= r_bytes_transfered+1;
      if(r_bytes_transfered+1 == w_bytes_to_transfer)
         r_bytes_transfered <= 0;
   endtask

   // Drive memory interface for STORE and LOAD.
   always_comb begin
      if (w_opcode == `STORE) begin
         o_mem_write = 1;
         o_mem_addr = X[w_rs1] + w_S + r_bytes_transfered;
         o_mem_data = X[w_rs2][w_transfer_chunk -: 8];
         w_ld_unsigned = 0;
         case (w_funct3)
           `SB: w_bytes_to_transfer = 1;
           `SH: w_bytes_to_transfer = 2;
           `SW: w_bytes_to_transfer = 4;
           default: w_bytes_to_transfer = 0;
         endcase
      end
      else if (w_opcode == `LOAD) begin
         o_mem_write = 0;
         o_mem_addr = X[w_rs1] + w_I + r_bytes_transfered;
         o_mem_data = 0;
         w_ld_unsigned = (w_funct3 == `LBU || w_funct3 == `LHU);
         case (w_funct3)
           `LB, `LBU: w_bytes_to_transfer = 1;
           `LH, `LHU: w_bytes_to_transfer = 2;
           `LW:       w_bytes_to_transfer = 4;
           default:   w_bytes_to_transfer = 0;
         endcase
      end
      else begin
         o_mem_write = 0;
         o_mem_data = 0;
         o_mem_addr = 0;
         w_ld_unsigned = 0;
         w_bytes_to_transfer = 0;
      end
   end

   /*
    * ========= REGISTER-IMM INSTRUCTIONS
    */
   task OP_IMM_SEQ();
      case(w_funct3)
        // ADDI adds the sign-extended 12-bit immediate to register rs1. Arithmetic overflow is ignored and
        // the result is simply the low XLEN bits of the result. ADDI rd, rs1, 0 is used to implement the MV
        // rd, rs1 assembler pseudo-instruction.
        `ADDI: X[w_rd] <= X[w_rs1] + w_I;
        // SLTI (set less than immediate) places the value 1 in register rd if register rs1 is less than
        // the signextended immediate when both are treated as signed numbers, else 0 is written to rd.
        `SLTI: X[w_rd] <= ($signed(X[w_rs1]) < $signed(w_I_se)) ? 1 : 0;
        // SLTIU is similar but compares the values as unsigned numbers (i.e., the immediate is first
        // sign-extended to XLEN bits then treated as an unsigned number). Note, SLTIU rd, rs1, 1 sets rd
        // to 1 if rs1 equals  zero, otherwise sets rd to 0 (assembler pseudo-op SEQZ rd, rs).
        `SLTIU: X[w_rd] <= (X[w_rs1] < w_I_se) ? 1 : 0;
        // ANDI, ORI, XORI are logical operations that perform bitwise AND, OR, and XOR on register rs1
        // and the sign-extended 12-bit immediate and place the result in rd. Note, XORI rd, rs1, -1 performs
        // a bitwise logical inversion of register rs1 (assembler pseudo-instruction NOT rd, rs).
        `XORI: X[w_rd] <= X[w_rs1] ^ w_I_se;
        `ORI:  X[w_rd] <= X[w_rs1] | w_I_se;
        `ANDI: X[w_rd] <= X[w_rs1] & w_I_se;
        // Shifts by a constant are encoded as a specialization of the I-type format. The operand to be shifted
        // is in rs1, and the shift amount is encoded in the lower 5 bits of the I-immediate field. The right
        // shift type is encoded in a high bit of the I-immediate. SLLI is a logical left shift (zeros are shifted
        // into the lower bits); SRLI is a logical right shift (zeros are shifted into the upper bits); and SRAI
        // is an arithmetic right shift (the original sign bit is copied into the vacated upper bits).
        `SLLI: X[w_rd] <= X[w_rs1] << w_I[4:0];
        `SRLI, `SRAI: begin
           case (w_I[11:5])
              // SRLI
              7'b0000000: begin
                 X[w_rd] <= X[w_rs1] >> w_I[4:0];
              end
              // SRAI
              7'b0100000: begin
                 X[w_rd] <= $signed(X[w_rs1]) >>> w_I[4:0];
              end
              default:
                o_invalid_inst <= 1;
           endcase
        end
      endcase
   endtask

   task LUI_SEQ();
      // LUI (load upper immediate) is used to build 32-bit constants and uses the U-type format. LUI
      // places the U-immediate value in the top 20 bits of the destination register rd, filling in the lowest
      // 12 bits with zeros.
      X[w_rd] <= { w_U, 12'b0 };
   endtask

   task AUIPC_SEQ();
      // AUIPC (add upper immediate to pc) is used to build pc-relative addresses and uses the U-type
      // format. AUIPC forms a 32-bit offset from the 20-bit U-immediate, filling in the lowest 12 bits with
      // zeros, adds this offset to the pc, then places the result in register rd.
      X[w_rd] <= i_pc + { w_U, 12'b0 };
   endtask

   /*
    * ========= REGISTER-REGISTER INSTRUCTIONS
    */
   task OP_REG_SEQ();
      case(w_funct3)
        // ADD and SUB perform addition and subtraction respectively. Overflows are ignored and the low
        // XLEN bits of results are written to the destination.
        `ADD, `SUB: begin
           case (w_funct7)
             // ADD
             7'b0000000: X[w_rd] <= X[w_rs1]+X[w_rs2];
             //SUB
             7'b0100000: X[w_rd] <= X[w_rs1]-X[w_rs2];
             default:
               o_invalid_inst <= 1;
           endcase
        end
        // SLT and SLTU perform signed and unsigned
        // compares respectively, writing 1 to rd if rs1 < rs2, 0 otherwise. Note, SLTU rd, x0, rs2 sets rd to 1
        // if rs2 is not equal to zero, otherwise sets rd to zero (assembler pseudo-op SNEZ rd, rs).
        `SLT: X[w_rd] <= ($signed(X[w_rs1]) < $signed(X[w_rs2])) ? 1 : 0;
        `SLTU: X[w_rd] <= (X[w_rs1] < X[w_rs2]) ? 1 : 0;
        // AND, OR and XOR perform bitwise logical operations.
        `OR: X[w_rd] <= X[w_rs1] | X[w_rs2];
        `XOR: X[w_rd] <= X[w_rs1] ^ X[w_rs2];
        `AND: X[w_rd] <= X[w_rs1] & X[w_rs2];
        // SLL, SRL, and SRA perform logical left, logical right, and arithmetic right shifts on the value in
        // register rs1 by the shift amount held in the lower 5 bits of register rs2.
        `SLL: X[w_rd] <= X[w_rs1] << X[w_rs2];
        `SRL | `SRA: begin
           case (w_funct7)
             // SRL
             7'b0000000: X[w_rd] <= X[w_rs1] >> X[w_rs2];
             // SRA
             7'b0100000: X[w_rd] <= $signed(X[w_rs1]) >>> X[w_rs2];
             default:
               o_invalid_inst <= 1;
           endcase
        end
      endcase
   endtask;

   /*
    * ========= JUMPS
    */
   // Combinatorial part of the jump instructions logic.
   always_comb begin
      case (w_opcode)
        `JAL: begin
           o_new_pc = i_pc + w_J_se;
           o_pc_change = 1;
        end
        `JALR: begin
           o_new_pc = (X[w_rs1] + w_I) & ~(32'b1);
           o_pc_change = 1;
        end
        `BRANCH: begin
           o_pc_change = 0;
           case (w_funct3)
             `BEQ: if (X[w_rs1] == X[w_rs2]) begin
                o_new_pc = i_pc + w_B_se;
                o_pc_change = 1;
             end
             `BNE: if (X[w_rs1] != X[w_rs2]) begin
                o_new_pc = i_pc + w_B_se;
                o_pc_change = 1;
             end
             `BLT: if ($signed(X[w_rs1]) < $signed(X[w_rs2])) begin
                o_new_pc = i_pc + w_B_se;
                o_pc_change = 1;
             end
             `BLTU: if (X[w_rs1] < X[w_rs2]) begin
                o_new_pc = i_pc + w_B_se;
                o_pc_change = 1;
             end
             `BGE: if ($signed(X[w_rs1]) > $signed(X[w_rs2])) begin
                o_new_pc = i_pc + w_B_se;
                o_pc_change = 1;
             end
             `BGEU: if (X[w_rs1] > X[w_rs2]) begin
                o_new_pc = i_pc + w_B_se;
                o_pc_change = 1;
             end
             default:
               o_invalid_inst <= 1;
           endcase
        end
        default: begin
           o_new_pc = 0;
           o_pc_change = 0;
        end
      endcase
   end

   task JAL_SEQ();
      // The jump and link (JAL) instruction uses the J-type format, where the J-immediate encodes a
      // signed offset in multiples of 2 bytes. The offset is sign-extended and added to the pc to form the
      // jump target address. Jumps can therefore target a ±1 MiB range. JAL stores the address of the
      // instruction following the jump (pc+4) into register rd. The standard software calling convention
      // uses x1 as the return address register and x5 as an alternate link register.
      // Plain unconditional jumps (assembler pseudo-op J) are encoded as a JAL with rd=x0.
      if (w_rd != 0)
        X[w_rd] <= i_pc+4;
   endtask

   task JALR_SEQ();
      // The indirect jump instruction JALR (jump and link register) uses the I-type encoding. The target
      // address is obtained by adding the 12-bit signed I-immediate to the register rs1, then setting the
      // least-significant bit of the result to zero. The address of the instruction following the jump (pc+4)
      // is written to register rd. Register x0 can be used as the destination if the result is not required.
      if (w_rd != 0)
        X[w_rd] <= i_pc+4;
   endtask

   task BRANCH_SEQ();
      // No sequential logic for branch.
   endtask

   always @(posedge i_clk) begin
      if (i_rst) begin
         r_cycle <= 0;
         o_invalid_inst <= 0;
      end
      else begin
         o_invalid_inst <= 0;
         r_cycle <= (r_last_cycle) ? 0 : r_cycle+1;

         case(w_opcode)
           // Standard opcodes
           `LOAD:   LOAD_SEQ();
           `STORE:  STORE_SEQ();
           `OP_IMM: OP_IMM_SEQ();
           `LUI:    LUI_SEQ();
           `AUIPC:  AUIPC_SEQ();
           `OP_REG: OP_REG_SEQ();
           `JAL:    JAL_SEQ();
           `JALR:   JALR_SEQ();
           `BRANCH: BRANCH_SEQ();
           // Custom opcodes
           `NOP: ;
           default:
              o_invalid_inst <= 1;
         endcase
      end
   end
endmodule
