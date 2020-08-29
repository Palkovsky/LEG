`include "common.svh"

module core (
	input                        i_clk,
	input                        i_rst,

  // Memory interface
  output reg [31:0]            o_addr,
  // Writes
  output reg [`DATA_WIDTH-1:0] o_data,
  output reg                   o_wr_valid,
  input                        i_wr_ready,
  output [2:0]                 o_wr_width,
  // Reads
  input [`DATA_WIDTH-1:0]      i_data,
  input                        i_rd_valid,
  output reg                   o_rd_ready,

  // Control information
  output                       o_invalid_inst
);
   localparam
     STATE_SZ = 3,
     FETCH_STATE = 3'b000,
     EXEC_STATE = 3'b001;

   // PC register.
   reg [31:0]                  pc = 0;

   // Control signals.
   reg [STATE_SZ-1:0]     state = FETCH_STATE;
   wire                   pc_change;
   wire [31:0]            pc_change_new;

   wire                   fetch_rst;
   wire                   fetch_stall;
   wire [31:0]            fetch_addr;
   reg                    fetch_valid;
   wire                   fetch_ready;
   reg [`DATA_WIDTH-1:0]  fetch_data_in;
   wire                   fetch_finished;

   wire                   exec_rst;
   wire                   exec_inst_valid;
   wire [31:0]            exec_addr;
   reg [`DATA_WIDTH-1:0]  exec_data_in;
   reg                    exec_rd_valid;
   wire                   exec_rd_ready;
   wire [`DATA_WIDTH-1:0] exec_data_out;
   wire                   exec_wr_valid;
   reg                    exec_wr_ready;
   wire                   exec_finished;

   reg [31:0]             inst;

   assign fetch_rst = i_rst;
   assign fetch_stall = state != FETCH_STATE;
   assign exec_rst = i_rst || state != EXEC_STATE;
   assign exec_inst_valid = state == EXEC_STATE;

   task FETCH_SEQ();
      if (fetch_finished)
         state <= EXEC_STATE;
   endtask

   task EXEC_SEQ();
      if (exec_finished) begin
         state <= FETCH_STATE;
         pc <= (pc_change) ? pc_change_new : pc+4;
      end
   endtask

   // TODO: Address line multiplexer.
   always_comb begin
      { o_addr,
        o_rd_ready,
        o_data,
        o_wr_valid,
        fetch_valid,
        fetch_data_in,
        exec_data_in,
        exec_rd_valid,
        exec_wr_ready
      } <= 0;

      case (state)
        FETCH_STATE: begin
           o_addr <= fetch_addr;
           // Read
           { fetch_data_in, fetch_valid, o_rd_ready } <= { i_data, i_rd_valid, fetch_ready };
           // Write
           { o_data, o_wr_valid } <= 0;
        end
        EXEC_STATE: begin
           o_addr <= exec_addr;
           // Read
           { exec_data_in, exec_rd_valid, o_rd_ready } <= { i_data, i_rd_valid, exec_rd_ready };
           // Write
           { o_data, o_wr_valid, exec_wr_ready } <= { exec_data_out, exec_wr_valid, i_wr_ready };
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
           FETCH_STATE: FETCH_SEQ();
           EXEC_STATE:  EXEC_SEQ();
         endcase
      end
   end

   fetch fetch
     (
      .i_clk(i_clk),
      .i_rst(fetch_rst),
      .i_stall(fetch_stall),
      .i_pc(pc),

      .o_addr(fetch_addr),
      .i_data(fetch_data_in),
      .i_valid(fetch_valid),
      .o_ready(fetch_ready),

      .o_inst(inst),
      .o_finished(fetch_finished)
     );

   execute execute
     (
	   .i_clk(i_clk),
	   .i_rst(exec_rst),

      .i_inst(inst),
      .i_inst_valid(exec_inst_valid),

      .o_addr(exec_addr),
      .o_data(exec_data_out),
      .o_wr_valid(exec_wr_valid),
      .i_wr_ready(exec_wr_ready),
      .o_wr_width(o_wr_width),
      .i_data(exec_data_in),
      .i_rd_valid(exec_rd_valid),
      .o_rd_ready(exec_rd_ready),

      .i_pc(pc),
      .o_pc_change(pc_change),
      .o_new_pc(pc_change_new),
      .o_finished(exec_finished),
      .o_invalid_inst(o_invalid_inst)
    );
endmodule
