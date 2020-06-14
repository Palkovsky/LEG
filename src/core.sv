`include "common.svh"

module core (
	input                        i_clk,
	input                        i_rst,

  // Memory interface
  output reg [31:0]            o_mem_addr,
  output reg [`DATA_WIDTH-1:0] o_mem_data,
  input [`DATA_WIDTH-1:0]      i_mem_data,
  output reg                   o_mem_write,

  // Control information
  output                       o_invalid_inst
);
   localparam SIZE = 3;
   localparam FETCH_STATE = 3'b000, EXECUTE_STATE = 3'b001;

   // PC register.
   reg [31:0]             pc = 0;

   // Currently fetched/executed instruction.
   reg [31:0]             inst;

   // Control signals.
   reg [SIZE-1:0]         state = FETCH_STATE;
   wire                   pc_change;
   wire [31:0]            pc_change_new;

   wire                   fetch_ready;
   wire                   fetch_started;
   wire                   fetch_rst;
   wire [31:0]            fetch_mem_addr;
   reg [`DATA_WIDTH-1:0]  fetch_mem_in;

   wire                   execute_ready;
   wire                   execute_rst;
   wire [31:0]            execute_mem_addr;
   reg [`DATA_WIDTH-1:0]  execute_mem_in;
   wire [`DATA_WIDTH-1:0] execute_mem_out;
   wire                   execute_mem_write;

   assign fetch_rst   = i_rst || state != FETCH_STATE;
   assign execute_rst = i_rst || state != EXECUTE_STATE;

   task FETCH_SEQ();
      if (fetch_ready && fetch_started)
        state <= EXECUTE_STATE;
   endtask

   task EXECUTE_SEQ();
      if (execute_ready) begin
         state <= FETCH_STATE;
         pc <= (pc_change) ? pc_change_new : pc+4;
      end
   endtask

   always_comb begin
      case (state)
        FETCH_STATE: begin
           execute_mem_in = 0;
           fetch_mem_in = i_mem_data;
           o_mem_addr = fetch_mem_addr;
           o_mem_data = 0;
           o_mem_write = 0;
        end
        EXECUTE_STATE: begin
           fetch_mem_in = 0;
           execute_mem_in = i_mem_data;
           o_mem_addr = execute_mem_addr;
           o_mem_data = execute_mem_out;
           o_mem_write = execute_mem_write;
        end
      endcase
   end

   always @(posedge i_clk) begin
      if (i_rst) begin
         pc <= 0;
         state <= FETCH_STATE;
      end
      else begin
         case (state)
           FETCH_STATE:   FETCH_SEQ();
           EXECUTE_STATE: EXECUTE_SEQ();
         endcase
      end
   end

   fetch fetch
     (
      .i_clk(i_clk),
      .i_rst(fetch_rst),

      .i_pc(pc),

      .o_mem_addr(fetch_mem_addr),
      .i_mem_data(fetch_mem_in),

      .o_inst(inst),
      .o_ready(fetch_ready),
      .o_started(fetch_started)
     );

   execute execute
     (
	    .i_clk(i_clk),
	    .i_rst(execute_rst),

      .i_inst(inst),

      .o_mem_addr(execute_mem_addr),
      .i_mem_data(execute_mem_in),
      .o_mem_write(execute_mem_write),
      .o_mem_data(execute_mem_out),

      .i_pc(pc),
      .o_pc_change(pc_change),
      .o_new_pc(pc_change_new),
      .o_ready(execute_ready),
      .o_invalid_inst(o_invalid_inst)
    );
endmodule

/*
 bram #(
 .DATA_WIDTH(`DATA_WIDTH),
 .ADDR_WIDTH(12)
 ) bram (
 .i_clk_a(i_clk),
 .i_clk_b(i_clk),

 .i_data_a(bram_input_a),
 .i_addr_a(bram_addr_a),
 .i_write_a(bram_write_a),
 .o_data_a(bram_output_a),

 .i_data_b(bram_input_b),
 .i_addr_b(bram_addr_b),
 .i_write_b(bram_write_b),
 .o_data_b(bram_output_b)
 );
 */
