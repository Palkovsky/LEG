`include "common.svh"

module execute (
  input                        i_clk,
  input                        i_rst,

  // Instruction
  input [31:0]                 i_inst,
  input                        i_inst_valid,

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

   // 32 32-bit scalar registers
   reg [31:0]                 X[0:31] = '{ 32{32'b0} };

   logic [31:0]                X_rs1;
   logic [31:0]                X_rs2;

   // ALU
   reg [31:0]                r_alu_op1;
   reg [31:0]                r_alu_op2;
   reg [31:0]                r_alu_op3;
   reg [3:0]                 r_alu_operation;
   reg [31:0]                r_alu_result;

   // Vector transfer
   logic [5:0]               r_vec_counter = 0;
   logic [5:0]               r_mat_counter = 0;
   logic [7:0][31:0]         r_vec_tmp = 0;
   logic [15:0][15:0]        r_vec_tmp16 = 0;

   // vec_ram access
   logic                     w_vram_we;
   logic [4:0]               w_vram_windex;
   logic [3:0]               w_vram_wrow;
   logic                     w_vram_wmatrix;
   logic [15:0][15:0]        w_vram_wdata;

   logic [4:0]               w_vram_rindex1;
   logic [3:0]               w_vram_rrow1;
   logic                     w_vram_rmatrix1;
   logic [15:0][15:0]        w_vram_rdata1;
   logic [7:0][31:0]         w_vram_rdata1_32;
   assign w_vram_rdata1_32 = w_vram_rdata1;

   logic [4:0]               w_vram_rindex2;
   logic [3:0]               w_vram_rrow2;
   logic                     w_vram_rmatrix2;
   logic [15:0][15:0]        w_vram_rdata2;
   logic [7:0][31:0]         w_vram_rdata2_32;
   assign w_vram_rdata2_32 = w_vram_rdata2;

   // vec_mul
   logic [15:0]              w_vmul_dot;
   logic [15:0][15:0]        w_vmul_mul;
   logic [15:0][15:0]        w_vmul_add;

   // vec_cmp
   logic [15:0]              r_vcmp_mask = '1;
   logic [15:0]              w_vcmp_mask_arg;
   logic [15:0]              w_vcmp_mask_res;

   /*
    * ========= MEMORY ACCESS INSTRUCTIONS
    */
   reg                        mem_transfer_done;

   task SAVE_INT_RESULT(logic[31:0] value);
      if (w_rd != 0) begin
         X[w_rd] <= value;
      end
   endtask

   always_comb begin
      if (w_rs1 == 0) begin
         X_rs1 <= 0;
      end
      else begin
         X_rs1 <= X[w_rs1];
      end

      if (w_rs2 == 0) begin
         X_rs2 <= 0;
      end
      else begin
         X_rs2 <= X[w_rs2];
      end
   end

   task LOAD_SEQ();
      if (o_rd_ready && i_rd_valid) begin
         case (w_funct3)
           `LBU:
             SAVE_INT_RESULT({ 24'b0, i_data[7:0] });
           `LB:
             SAVE_INT_RESULT({ {24{i_data[7]}}, i_data[7:0] });
           `LHU:
             SAVE_INT_RESULT({ 16'b0, i_data[15:0] });
           `LH:
             SAVE_INT_RESULT({ {16{i_data[15]}}, i_data[15:0] });
           `LW:
             SAVE_INT_RESULT(i_data[31:0]);
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
      else if (w_funct3 == `VECI_LM)
         MX_LOAD_SEQ();
   endtask

   task VEC_LOAD_SEQ();
      if (o_rd_ready && i_rd_valid && r_vec_counter < 8) begin
         r_vec_tmp[r_vec_counter] <= i_data;
         r_vec_counter <= r_vec_counter + 1;
      end
      if (r_vec_counter == 8)
         r_vec_counter <= 9;
      if (r_vec_counter == 9)
         r_vec_counter <= 0;
   endtask

   task VEC_STORE_SEQ();
      if (o_wr_valid && i_wr_ready && r_vec_counter < 8)
         r_vec_counter <= r_vec_counter + 1;

      if (r_vec_counter >= 7)
         r_vec_counter <= 0;
   endtask

   task MX_LOAD_SEQ();
      if (o_rd_ready && i_rd_valid && r_vec_counter < 8) begin
         r_vec_tmp[r_vec_counter] <= i_data;
         r_vec_counter <= r_vec_counter + 1;
      end
      if (r_vec_counter == 8)
        r_vec_counter <= 9;
      if (r_vec_counter == 9) begin
         r_vec_counter <= 0;
         if (r_mat_counter < 15)
           r_mat_counter <= r_mat_counter + 1;
         else
           r_mat_counter <= 0;
      end
   endtask

   always_comb begin
      // Write signals
      w_vram_we <= 0;
      w_vram_windex <= w_rd;
      w_vram_wrow <= 0;
      w_vram_wmatrix <= 0;
      w_vram_wdata <= 0;

      // Read signals
      w_vram_rindex1 <= w_rs1;
      w_vram_rmatrix1 <= 0;
      w_vram_rrow1 <= 0;

      w_vram_rindex2 <= w_rs2;
      w_vram_rmatrix2 <= 0;
      w_vram_rrow2 <= 0;

    // Default mask
      w_vcmp_mask_arg <= '1;

      if (i_inst_valid) begin
         // Vector mask
         case ({w_opcode, w_funct7})
           { `OP_VEC_R, `VECR_CMPMV },
           { `OP_VEC_R, `VECR_MOVMV }:
             w_vcmp_mask_arg <= r_vcmp_mask;
         endcase

         if (w_opcode == `OP_VEC_I) begin
            w_vram_wdata <= r_vec_tmp;
            case (w_funct3)
              `VECI_LV:
                w_vram_we <= (r_vec_counter >= 8);
              `VECI_SV:
                w_vram_rindex1 <= w_rd;
              `VECI_LM: begin
                 w_vram_we <= (r_vec_counter >= 8);
                 w_vram_wmatrix <= 1;
                 w_vram_wrow <= r_mat_counter;
              end
            endcase
         end
         else if (w_opcode == `OP_VEC_R) begin
            case (w_funct7)
              `VECR_DOTV: ;
              `VECR_MULV: begin
                 w_vram_wdata <= w_vmul_mul;
                 w_vram_we <= 1;
              end
              `VECR_ADDV: begin
                 w_vram_wdata <= w_vmul_add;
                 w_vram_we <= 1;
              end
              `VECR_CMPV, `VECR_CMPMV:  ;
              `VECR_MOVV, `VECR_MOVMV: begin
                 w_vram_rindex2 <= w_rd;
                 w_vram_we <= 1;
                 for (int i = 0; i < 16; i++) begin
                    w_vram_wdata[i] <= w_vcmp_mask_arg[i] ? w_vram_rdata1[i] : w_vram_rdata2[i];
                 end
              end
              `VECR_MULMV: begin
                 w_vram_rrow1 <= r_vec_counter;
                 w_vram_rmatrix1 <= 1;
                 w_vram_wdata <= r_vec_tmp16;
                 w_vram_we <= (r_vec_counter == `VEC_DIM);
              end
            endcase
         end
      end
   end

   task VECR_SEQ();
      case (w_funct7)
         `VECR_DOTV:
            SAVE_INT_RESULT(w_vmul_dot);
         `VECR_MULV, `VECR_ADDV:  ;
         `VECR_CMPV, `VECR_CMPMV:
            r_vcmp_mask <= w_vcmp_mask_res;
         `VECR_MOVV, `VECR_MOVMV: ;
         `VECR_MULMV: begin
            r_vec_counter <= r_vec_counter + 1;
            if (r_vec_counter < `VEC_DIM)
               r_vec_tmp16[r_vec_counter] <= w_vmul_dot;
            if (r_vec_counter >= `VEC_DIM + 1)
               r_vec_counter <= 0;
         end
      endcase
   endtask

   // Drive memory interface for STORE and LOAD.
   always_comb begin
      { o_wr_valid, o_rd_ready, o_data, o_addr, mem_transfer_done } <= 0;

      case (w_funct3)
        `SB, `LB, `LBU: o_wr_width <= 1;
        `SH, `LH, `LHU: o_wr_width <= 2;
        `SW, `LW: o_wr_width <= 4;
        default: o_wr_width <= 0;
      endcase

      casez ({w_opcode, w_funct3})
         { `STORE, 3'b??? }: begin
            mem_transfer_done <= (o_wr_valid && i_wr_ready);
            o_wr_valid <= 1;
            o_addr <= r_alu_result;
            o_data <= X_rs2;
         end
         { `LOAD, 3'b??? }: begin
            mem_transfer_done <= (i_rd_valid && o_rd_ready);
            o_rd_ready <= 1;
            o_addr <= r_alu_result;
         end
         { `OP_VEC_I, `VECI_LV }: begin
            o_rd_ready <= 1;
            o_addr <= r_alu_result;
         end
         { `OP_VEC_I, `VECI_SV }: begin
            o_wr_valid <= 1;
            o_addr <= r_alu_result;
            o_data <= w_vram_rdata1_32[r_vec_counter];
         end
        { `OP_VEC_I, `VECI_LM }: begin
            o_rd_ready <= 1;
            o_addr <= r_alu_result;
         end
      endcase
   end

   /*
    * ========= LAST INSTRUCTION CYCLE DETECTION
    * This signal tells user to latch new instruction.
    */
   always_comb begin
      casez ({w_opcode, w_funct3, w_funct7})
         { `LOAD, {10{1'b?}} },
        { `STORE, {10{1'b?}} }:
           r_last_cycle <= mem_transfer_done;
         { `OP_VEC_I, `VECI_LV, {7{1'b?}} }:
            r_last_cycle <= r_vec_counter == `VEC_DIM / 2 + 1;
         { `OP_VEC_I, `VECI_SV, {7{1'b?}} }:
            r_last_cycle <= r_vec_counter == `VEC_DIM / 2 - 1;
         { `OP_VEC_I, `VECI_LM, {7{1'b?}} }:
            r_last_cycle <= (r_vec_counter == `VEC_DIM / 2 + 1) && r_mat_counter == (`VEC_DIM - 1);
         { `OP_VEC_R, {3{1'b?}}, `VECR_MULMV}:
            r_last_cycle <= r_vec_counter > `VEC_DIM;
         default:
            r_last_cycle <= (w_next_cycle >= 1);
      endcase
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
           r_alu_op1 <= X_rs1;   // base address
           r_alu_op2 <= w_I_se;  // imm offset
        end
        `OP_VEC_I: begin
           case (w_funct3)
             `VECI_LV, `VECI_SV: begin
                r_alu_operation <= `ALU_ADD;
                r_alu_op1 <= X_rs1;  // base address
                r_alu_op2 <= w_I_se; // imm offset
                r_alu_op3 <= r_vec_counter * 4;
             end
             `VECI_LM: begin
                r_alu_operation <= `ALU_ADD;
                r_alu_op1 <= X_rs1;  // base address
                r_alu_op2 <= w_I_se; // imm offset
                r_alu_op3 <= r_vec_counter * 4 + r_mat_counter * `VEC_DIM * 2;
             end
            endcase
         end
        `STORE: begin
           r_alu_operation <= `ALU_ADD;
           r_alu_op1 <= X_rs1;
           r_alu_op2 <= w_S_se;
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
           r_alu_op1 <= X_rs1;
           r_alu_op2 <= w_I_se;
        end
        `AUIPC: begin
           r_alu_operation <= `ALU_ADD;
           r_alu_op1 <= i_pc;
           r_alu_op2 <= { w_U, 12'b0 };
        end
        `OP_IMM: begin
           r_alu_op1 <= X_rs1;
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
           r_alu_op1 <= X_rs1;
           r_alu_op2 <= X_rs2;
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
      SAVE_INT_RESULT(r_alu_result);
   endtask

   task LUI_SEQ();
      SAVE_INT_RESULT({ w_U, 12'b0 });
   endtask

   task AUIPC_SEQ();
      SAVE_INT_RESULT(r_alu_result);
   endtask

   /*
    * ========= REGISTER-REGISTER INSTRUCTIONS
    */
   task OP_REG_SEQ();
      SAVE_INT_RESULT(r_alu_result);
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
             `BEQ: if (X_rs1 == X_rs2) begin
                o_new_pc <= r_alu_result;
                o_pc_change <= 1;
             end
             `BNE: if (X_rs1 != X_rs2) begin
                o_new_pc <= r_alu_result;
                o_pc_change <= 1;
             end
             `BLT: if ($signed(X_rs1) < $signed(X_rs2)) begin
                o_new_pc <= r_alu_result;
                o_pc_change <= 1;
             end
             `BLTU: if (X_rs1 < X_rs2) begin
                o_new_pc <= r_alu_result;
                o_pc_change <= 1;
             end
             `BGE: if ($signed(X_rs1) >= $signed(X_rs2)) begin
                o_new_pc <= r_alu_result;
                o_pc_change <= 1;
             end
             `BGEU: if (X_rs1 >= X_rs2) begin
                o_new_pc <= r_alu_result;
                o_pc_change <= 1;
             end
             default: ; // Invalid inst
           endcase
        end
      endcase
   end

   task JAL_SEQ();
      SAVE_INT_RESULT(i_pc+4);
   endtask

   task JALR_SEQ();
      SAVE_INT_RESULT(i_pc+4);
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

     .i_read_index_a(w_vram_rindex1),
     .i_read_row_a(w_vram_rrow1),
     .i_read_matrix_a(w_vram_rmatrix1),
     .o_read_data_a(w_vram_rdata1),

     .i_read_index_b(w_vram_rindex2),
     .i_read_row_b(w_vram_rrow2),
     .i_read_matrix_b(w_vram_rmatrix2),
     .o_read_data_b(w_vram_rdata2),

     .i_write_enable(w_vram_we),
     .i_write_index(w_vram_windex),
     .i_write_row(w_vram_wrow),
     .i_write_matrix(w_vram_wmatrix),
     .i_write_data(w_vram_wdata)
   );

   vec_mul #(
     .VEC_SIZE(16)
   ) vec_mul (
     .i_vec_a(w_vram_rdata1),
     .i_vec_b(w_vram_rdata2),

     .o_dot(w_vmul_dot),
     .o_vec_mul(w_vmul_mul),
     .o_vec_add(w_vmul_add)
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
