`include "common.svh"

module execute (
	input                            i_clk,
	input                            i_rst,

  // Instruction
  input [31:0]                     i_inst,

  // Memory interface
  output reg [31:0]                o_addr = 0,
  // Writes
  output reg [`DATA_WIDTH-1:0]     o_data = 0,
  output reg                       o_wr_valid = 0,
  input                            i_wr_ready,
  output logic [`DATA_WIDTH/8-1:0] o_byte_write_enable,
  // Reads
  input [`DATA_WIDTH-1:0]          i_data,
  input                            i_rd_valid,
  output reg                       o_rd_ready = 0,

  // Control unit interface
  input [31:0]                     i_pc,
  output reg                       o_pc_change = 0,
  output reg [31:0]                o_new_pc = 0,
  output reg                       o_finished,
  output reg                       o_invalid_inst
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

   /*
    * ========= MEMORY ACCESS INSTRUCTIONS
    */
   reg                       mem_transfer_done;

   task LOAD_SEQ();
      if (o_rd_ready && i_rd_valid) begin
         case (w_funct3)
           `LBU:
             case (r_alu_result[1:0])
               0:
                 X[w_rd] <= { 24'b0, i_data[7:0] };
               1:
                 X[w_rd] <= { 24'b0, i_data[15:8] };
               2:
                 X[w_rd] <= { 24'b0, i_data[23:16] };
               3:
                 X[w_rd] <= { 24'b0, i_data[31:24] };
             endcase
           `LB:
             case (r_alu_result[1:0])
               0:
                 X[w_rd] = { {24{i_data[7]}}, i_data[7:0] };
               1:
                 X[w_rd] = { {24{i_data[15]}}, i_data[15:8] };
               2:
                 X[w_rd] = { {24{i_data[23]}}, i_data[23:16] };
               3:
                 X[w_rd] = { {24{i_data[31]}}, i_data[31:24] };
             endcase
           `LHU:
             case (r_alu_result[1:0])
               0:
                 X[w_rd] <= { 16'b0, i_data[15:0] };
               2:
                 X[w_rd] <= { 16'b0, i_data[31:16] };
             endcase
           `LH:
             case (r_alu_result[1:0])
               0:
                 X[w_rd] <= { {16{i_data[15]}}, i_data[15:0] };
               2:
                 X[w_rd] <= { {16{i_data[31]}}, i_data[31:16] };
             endcase
           `LW:
             X[w_rd] <= i_data[31:0];
         endcase
      end
   endtask

   task STORE_SEQ();
   endtask

   // Drive memory interface for STORE and LOAD.
   always_comb begin
      o_wr_valid <= 0;
      o_rd_ready <= 0;
      o_data <= 0;
      o_addr <= 0;
      mem_transfer_done <= 0;
      o_byte_write_enable <= 0;

      if (w_opcode == `STORE) begin
         mem_transfer_done <= (o_wr_valid && i_wr_ready);
         o_wr_valid <= 1;
         o_addr <= r_alu_result;
         case (w_funct3)
           `SB: begin
              o_data <= { 4{X[w_rs2][7:0]} };
              o_byte_write_enable <= 1 << r_alu_result[1:0];
           end
           `SH: begin
              o_data <= { 2{X[w_rs2][15:0]} };
              o_byte_write_enable <= 'b11 << (r_alu_result[1] * 2);
           end
           `SW: begin
              o_data <= X[w_rs2][31:0];
              o_byte_write_enable <= 'b1111;
           end
         endcase
      end
      else if (w_opcode == `LOAD) begin
         mem_transfer_done <= (i_rd_valid && o_rd_ready);
         o_rd_ready <= 1;
         o_addr <= r_alu_result;
      end
   end

   /*
    * ========= LAST INSTRUCTION CYCLE DETECTION
    * This signal tells user to latch new instruction.
    */
   always_comb begin
      if (w_opcode == `LOAD || w_opcode == `STORE)
        r_last_cycle <= mem_transfer_done;
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
           r_alu_op1 <= X[w_rs1];
           r_alu_op2 <= w_I;
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
      o_new_pc = 0;
      o_pc_change = 0;
      case (w_opcode)
        `JAL: begin
           o_new_pc = r_alu_result;
           o_pc_change = 1;
        end
        `JALR: begin
           o_new_pc = r_alu_result & ~(32'b1);
           o_pc_change = 1;
        end
        `BRANCH: begin
           o_pc_change = 0;
           case (w_funct3)
             `BEQ: if (X[w_rs1] == X[w_rs2]) begin
                o_new_pc = r_alu_result;
                o_pc_change = 1;
             end
             `BNE: if (X[w_rs1] != X[w_rs2]) begin
                o_new_pc = r_alu_result;
                o_pc_change = 1;
             end
             `BLT: if ($signed(X[w_rs1]) < $signed(X[w_rs2])) begin
                o_new_pc = r_alu_result;
                o_pc_change = 1;
             end
             `BLTU: if (X[w_rs1] < X[w_rs2]) begin
                o_new_pc = r_alu_result;
                o_pc_change = 1;
             end
             `BGE: if ($signed(X[w_rs1]) > $signed(X[w_rs2])) begin
                o_new_pc = r_alu_result;
                o_pc_change = 1;
             end
             `BGEU: if (X[w_rs1] > X[w_rs2]) begin
                o_new_pc = r_alu_result;
                o_pc_change = 1;
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
           `NOP: ;
         endcase
      end
   end
endmodule
