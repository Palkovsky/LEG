`include "common.svh"

module execute (
  input                        i_clk,
  input                        i_rst,

  // Instruction
  input [31:0]                 i_inst,

  // Memory interface
  output reg [31:0]            o_addr = 0,
  // Writes
  output reg [`DATA_WIDTH-1:0] o_data = 0,
  output reg                   o_wr_valid = 0,
  input                        i_wr_ready,
  output reg [2:0]             o_wr_width,
  // Reads
  input [`DATA_WIDTH-1:0]      i_data,
  input                        i_rd_valid,
  output reg                   o_rd_ready = 0,

  // Control unit interface
  input [31:0]                 i_pc,
  output reg                   o_pc_change = 0,
  output reg [31:0]            o_new_pc = 0,
  output reg                   o_finished,
  output reg                   o_invalid_inst
);
   // Control signals
   reg [3:0]                   r_cycle = 0;
   wire [3:0]                  w_next_cycle = r_cycle+1;
   reg                         r_last_cycle;
   assign o_finished = r_last_cycle;

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
   reg [31:0]                 X[0:15] = '{ 16{32'b0} };

   // ALU
   reg [31:0]                r_alu_op1;
   reg [31:0]                r_alu_op2;
   reg [31:0]                r_alu_op3;
   reg [3:0]                 r_alu_operation;
   reg [31:0]                r_alu_result;

   // Vector transfer
   logic [5:0]               r_vec_transfered = 0;
   logic [7:0][31:0]         r_vec_tmp = 0;

   // vec_ram access
   logic                     w_vram_we;
   logic [4:0]               w_vram_waddr;
   logic [15:0][15:0]        w_vram_wdata;

   logic [4:0]               w_vram_raddr1;
   logic [15:0][15:0]        w_vram_rdata1;
   logic [7:0][31:0]         w_vram_rdata1_32;
   assign w_vram_rdata1_32 = w_vram_rdata1;

   logic [4:0]               w_vram_raddr2;
   logic [15:0][15:0]        w_vram_rdata2;
   logic [7:0][31:0]         w_vram_rdata2_32;
   assign w_vram_rdata2_32 = w_vram_rdata2;

   // vec_mul
   logic [15:0]              w_vmul_dot;
   logic [15:0][15:0]        w_vmul_res;

   // vec_cmp
   logic [15:0]              r_vcmp_mask = '1;
   logic [15:0]              w_vcmp_mask_arg;
   logic [15:0]              w_vcmp_mask_res;

   /*
    * ========= MEMORY ACCESS INSTRUCTIONS
    */
   reg                        mem_transfer_done;

   task LOAD_SEQ();
      if (o_rd_ready && i_rd_valid) begin
         case (w_funct3)
           `LBU:
             X[w_rd] <= { 24'b0, i_data[7:0] };
           `LB:
             X[w_rd] <= { {24{i_data[7]}}, i_data[7:0] };
           `LHU:
             X[w_rd] <= { 16'b0, i_data[15:0] };
           `LH:
             X[w_rd] <= { {16{i_data[15]}}, i_data[15:0] };
           `LW:
             X[w_rd] <= i_data[31:0];
         endcase
      end
   endtask

   task STORE_SEQ();
   endtask

   task VECI_SEQ();
      if (w_funct3 == `VECI_LV)
         VEC_LOAD_SEQ();
      else if (w_funct3 == `VECI_SV)
         VEC_STORE_SEQ();
   endtask

   task VEC_LOAD_SEQ();
      if (o_rd_ready && i_rd_valid && r_vec_transfered < 8) begin
         r_vec_tmp[r_vec_transfered] <= i_data;
         r_vec_transfered <= r_vec_transfered + 1;
      end
      if (r_vec_transfered == 8)
         r_vec_transfered <= 9;
      if (r_vec_transfered == 9) 
         r_vec_transfered <= 0;
   endtask

   task VEC_STORE_SEQ();
      if (o_wr_valid && i_wr_ready && r_vec_transfered < 8)
         r_vec_transfered <= r_vec_transfered + 1;

      if (r_vec_transfered >= 8)
         r_vec_transfered <= 0;
   endtask

   always_comb begin
      // Write signals
      w_vram_we <= 0;
      w_vram_waddr <= w_rd;
      w_vram_wdata <= 0;
      
      // Read signals
      w_vram_raddr1 <= w_rs1;
      w_vram_raddr2 <= w_rs2;

      // cmp
      w_vcmp_mask_arg <= 0;

      if (w_opcode == `OP_VEC_I) begin
         w_vram_wdata <= r_vec_tmp;
         case (w_funct3)
            `VECI_LV:
               w_vram_we <= (r_vec_transfered >= 8);
            `VECI_SV:
               w_vram_raddr1 <= w_rd;
         endcase
      end 
      else if (w_opcode == `OP_VEC_R) begin
         case (w_funct7)
           `VECR_DOTV: ;
           `VECR_MULV: begin
               w_vram_wdata <= w_vmul_res;
               w_vram_we <= 1;
           end
           `VECR_CMPV:  w_vcmp_mask_arg <= '1;
           `VECR_CMPMV: w_vcmp_mask_arg <= r_vcmp_mask;
         endcase
      end
   end

   task VECR_SEQ();
      case (w_funct7)
         `VECR_DOTV:
            X[w_rd] <= w_vmul_dot;
         `VECR_MULV:  ;
         `VECR_CMPV, `VECR_CMPMV:  
            r_vcmp_mask <= w_vcmp_mask_res;
      endcase
   endtask

   // Drive memory interface for STORE and LOAD.
   always_comb begin
      o_wr_valid <= 0;
      o_rd_ready <= 0;
      o_data <= 0;
      o_addr <= 0;
      mem_transfer_done <= 0;

      case (w_funct3)
        `SB: o_wr_width <= 1;
        `SH: o_wr_width <= 2;
        `SW: o_wr_width <= 4;
        default: o_wr_width <= 0;
      endcase

      if (w_opcode == `STORE) begin
         mem_transfer_done <= (o_wr_valid && i_wr_ready);
         o_wr_valid <= 1;
         o_addr <= r_alu_result;
         o_data <= X[w_rs2];
      end
      else if (w_opcode == `LOAD) begin
         mem_transfer_done <= (i_rd_valid && o_rd_ready);
         o_rd_ready <= 1;
         o_addr <= r_alu_result;
      end
      else if (w_opcode == `OP_VEC_I && w_funct3 == `VECI_LV) begin
         o_rd_ready <= 1;
         o_addr <= r_alu_result;
      end
      else if (w_opcode == `OP_VEC_I && w_funct3 == `VECI_SV) begin
         o_wr_valid <= 1;
         o_addr <= r_alu_result;
         o_data <= w_vram_rdata1_32[r_vec_transfered];
      end
   end

   /*
    * ========= LAST INSTRUCTION CYCLE DETECTION
    * This signal tells user to latch new instruction.
    */
   always_comb begin
      if (w_opcode == `LOAD || w_opcode == `STORE)
        r_last_cycle <= mem_transfer_done;
      else if (w_opcode == `OP_VEC_I && w_funct3 == `VECI_LV)
         r_last_cycle <= r_vec_transfered == `VEC_DIM / 2 + 1;
      else if (w_opcode == `OP_VEC_I && w_funct3 == `VECI_SV)
         r_last_cycle <= r_vec_transfered == `VEC_DIM / 2;
      else
        r_last_cycle <= (w_next_cycle >= 1);
   end

   /*
    * ========= ALU
    */
   alu alu
     (
      .i_operand_1(r_alu_op1),
      .i_operand_2(r_alu_op2),
      .i_operand_3(r_alu_op3),
      .i_operation(r_alu_operation),
      .o_result(r_alu_result)
      );

   always_comb begin
      r_alu_operation <= 0;
      r_alu_op1 <= 0;
      r_alu_op2 <= 0;
      r_alu_op3 <= 0;
      o_invalid_inst <= 0;
      case (w_opcode)
        `LOAD: begin
           r_alu_operation <= `ALU_ADD;
           r_alu_op1 <= X[w_rs1]; // base address
           r_alu_op2 <= w_I;      // imm offset
        end
        `OP_VEC_I: begin
           case (w_funct3)
             `VECI_LV, `VECI_SV: begin
                r_alu_operation <= `ALU_ADD;
                r_alu_op1 <= X[w_rs1]; // base address
                r_alu_op2 <= w_I;      // imm offset
                r_alu_op3 <= r_vec_transfered * 4;
             end
            endcase
         end
        `STORE: begin
           r_alu_operation <= `ALU_ADD;
           r_alu_op1 <= X[w_rs1];
           r_alu_op2 <= w_S;
        end
        `BRANCH: begin
           r_alu_operation <= `ALU_ADD;
           r_alu_op1 <= i_pc;
           r_alu_op2 <= w_B_se;
        end
        `JAL: begin
           r_alu_operation <= `ALU_ADD;
           r_alu_op1 <= i_pc;
           r_alu_op2 <= w_J_se;
        end
        `JALR: begin
           r_alu_operation <= `ALU_ADD;
           r_alu_op1 <= X[w_rs1];
           r_alu_op2 <= w_I_se;
        end
        `AUIPC: begin
           r_alu_operation <= `ALU_ADD;
           r_alu_op1 <= i_pc;
           r_alu_op2 <= { w_U, 12'b0 };
        end
        `OP_IMM: begin
           r_alu_op1 <= X[w_rs1];
           r_alu_op2 <= w_I_se;
           case (w_funct3)
             `ADDI: r_alu_operation <= `ALU_ADD;
             `SLTI: r_alu_operation <= `ALU_SLT;
             `SLTIU: r_alu_operation <= `ALU_SLTU;
             `ORI: r_alu_operation <= `ALU_OR;
             `XORI: r_alu_operation <= `ALU_XOR;
             `ANDI: r_alu_operation <= `ALU_AND;
             `SLLI: begin
                r_alu_operation <= `ALU_SLL;
                r_alu_op2 <= w_I[4:0];
             end
             `SRLI | `SRAI: begin
                r_alu_op2 <= w_I[4:0];
                if (w_I[11:5] == 7'b0000000)
                   r_alu_operation <= `ALU_SRL;
                else if(w_I[11:5] == 7'b0100000)
                   r_alu_operation <= `ALU_SRA;
                else
                  o_invalid_inst <= 1;
             end
           endcase
        end
        `OP_REG: begin
           r_alu_op1 <= X[w_rs1];
           r_alu_op2 <= X[w_rs2];
           case(w_funct3)
             `ADD, `SUB: begin
                if (w_funct7 == 7'b0000000)
                   r_alu_operation <= `ALU_ADD;
                else if (w_funct7 == 7'b0100000)
                   r_alu_operation <= `ALU_SUB;
                else
                  o_invalid_inst <= 1;
             end
             `SLT: r_alu_operation <= `ALU_SLT;
             `SLTU: r_alu_operation <= `ALU_SLTU;
             `OR: r_alu_operation <= `ALU_OR;
             `XOR: r_alu_operation <= `ALU_XOR;
             `AND: r_alu_operation <= `ALU_AND;
             `SLL: r_alu_operation <= `ALU_SLL;
             `SRL | `SRA: begin
                if (w_funct7 == 7'b0000000)
                   r_alu_operation <= `ALU_SRL;
                else if (w_funct7 == 7'b0100000)
                   r_alu_operation <= `ALU_SRA;
                else
                  o_invalid_inst <= 1;
             end
           endcase
        end
        `LUI, `NOP: ;
        default:
          o_invalid_inst <= 1;
      endcase
   end

   /*
    * ========= REGISTER-IMM INSTRUCTIONS
    */
   task OP_IMM_SEQ();
      X[w_rd] <= r_alu_result;
   endtask

   task LUI_SEQ();
      X[w_rd] <= { w_U, 12'b0 };
   endtask

   task AUIPC_SEQ();
      X[w_rd] <= r_alu_result;
   endtask

   /*
    * ========= REGISTER-REGISTER INSTRUCTIONS
    */
   task OP_REG_SEQ();
      X[w_rd] <= r_alu_result;
   endtask

   /*
    * ========= JUMPS
    */
   // Combinatorial part of the jump instructions logic.
   always_comb begin
      o_new_pc <= 0;
      o_pc_change <= 0;
      case (w_opcode)
        `JAL: begin
           o_new_pc <= r_alu_result;
           o_pc_change <= 1;
        end
        `JALR: begin
           o_new_pc <= r_alu_result & ~(32'b1);
           o_pc_change <= 1;
        end
        `BRANCH: begin
           o_pc_change <= 0;
           case (w_funct3)
             `BEQ: if (X[w_rs1] == X[w_rs2]) begin
                o_new_pc <= r_alu_result;
                o_pc_change <= 1;
             end
             `BNE: if (X[w_rs1] != X[w_rs2]) begin
                o_new_pc <= r_alu_result;
                o_pc_change <= 1;
             end
             `BLT: if ($signed(X[w_rs1]) < $signed(X[w_rs2])) begin
                o_new_pc <= r_alu_result;
                o_pc_change <= 1;
             end
             `BLTU: if (X[w_rs1] < X[w_rs2]) begin
                o_new_pc <= r_alu_result;
                o_pc_change <= 1;
             end
             `BGE: if ($signed(X[w_rs1]) > $signed(X[w_rs2])) begin
                o_new_pc <= r_alu_result;
                o_pc_change <= 1;
             end
             `BGEU: if (X[w_rs1] > X[w_rs2]) begin
                o_new_pc <= r_alu_result;
                o_pc_change <= 1;
             end
             default: ; // Invalid inst
           endcase
        end
      endcase
   end

   task JAL_SEQ();
      if (w_rd != 0)
        X[w_rd] <= i_pc+4;
   endtask

   task JALR_SEQ();
      if (w_rd != 0)
        X[w_rd] <= i_pc+4;
   endtask

   task BRANCH_SEQ();
   endtask

   always @(posedge i_clk) begin
      if (i_rst) begin
         r_cycle <= 0;
      end
      else begin
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
           `OP_VEC_I: VECI_SEQ();
           `OP_VEC_R: VECR_SEQ();
           `NOP: ;
         endcase
      end
   end

   vec_ram #(
     .VEC_SIZE(16),
     .VEC_INDEX_WIDTH(5)
   ) vec_ram (
     .i_clk(i_clk),
     .i_rst(i_rst),

     .i_read_addr_a(w_vram_raddr1),
     .o_read_data_a(w_vram_rdata1),

     .i_read_addr_b(w_vram_raddr2),
     .o_read_data_b(w_vram_rdata2),

     .i_write_enable(w_vram_we),
     .i_write_addr(w_vram_waddr),
     .i_write_data(w_vram_wdata)
   );

   vec_mul #(
     .VEC_SIZE(16)
   ) vec_mul (
     .i_vec_a(w_vram_rdata1),
     .i_vec_b(w_vram_rdata2),

     .o_dot(w_vmul_dot),
     .o_vec_c(w_vmul_res)
   );

   vec_cmp #(
      .VEC_SIZE(16)
   ) vec_cmp (
     .i_op(w_funct3),
     .i_mask(w_vcmp_mask_arg),
     .i_vec_a(w_vram_rdata1),
     .i_vec_b(w_vram_rdata2), 
     
     .o_mask(w_vcmp_mask_res)
   );
endmodule
