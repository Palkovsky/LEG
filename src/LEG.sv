module LEG(
	input  i_clk
);
   localparam S_FETCH = 2'b00;
   localparam S_EXEC = 2'b01;

   reg[1:0] r_state;
   reg[7:0] r_inst;

   wire[3:0] w_opcode;
   wire[1:0] w_reg_1;
   wire[1:0] w_reg_2;

   assign w_opcode = r_inst[7:4];
   assign w_reg_1 = r_inst[3:2];
   assign w_reg_2 = r_inst[1:0];

   reg[3:0] r_pc;
   reg[31:0] r_regs[0:3];
   reg[7:0]  r_memory[0:15];
	
	integer i;
   initial begin
      r_state = S_FETCH;
      r_inst = '0;
      r_pc = '0;
		for (i=0; i<4; i = i+1)  begin r_regs[i] = 'h00; end
		for (i=0; i<16; i = i+1) begin r_memory[i] = 'h00; end
		// LD reg1, 2
		r_memory[0] = {4'h5, 4'b0111};
		// LD reg0, 1
		r_memory[1] = {4'h5, 4'b0001};
		// ADD reg1, reg0
      r_memory[2] = 'h21;
		// SUB reg1, reg0
      r_memory[3] = 'h31;
		// MUL reg1, reg0
      r_memory[4] = 'h41;
   end

   always @(posedge i_clk) begin
      case(r_state)
        S_FETCH: begin
           r_inst <= r_memory[r_pc];
           r_pc   <= r_pc + 1;
           r_state <= S_EXEC;
        end
        S_EXEC: begin
           r_state <= S_FETCH;
           case(w_opcode)
              4'h2: r_regs[w_reg_1] <= r_regs[w_reg_1]+r_regs[w_reg_2];
              4'h3: r_regs[w_reg_1] <= r_regs[w_reg_1]-r_regs[w_reg_2];
              4'h4: r_regs[w_reg_1] <= r_regs[w_reg_1]*r_regs[w_reg_2];
				  4'h5: r_regs[w_reg_1] <= w_reg_2;
           endcase
        end
      endcase
	 end

endmodule
