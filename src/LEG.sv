`include "common.svh"

module LEG(
	input  i_clk,
  input  i_rst,

  // UART
  input  rx,
  output tx,

  // Error signals
  output o_invalid_inst,
  output o_invalid_addr
);
   wire [31:0] cpu_addr;
   wire [`DATA_WIDTH-1:0] cpu_data_out;
   reg [`DATA_WIDTH-1:0]  cpu_data_in;
   wire                   cpu_write;

   core core
     (
	    .i_clk(i_clk),
      .i_rst(i_rst),

      .o_mem_addr(cpu_addr),
      .o_mem_data(cpu_data_out),
      .i_mem_data(cpu_data_in),
      .o_mem_write(cpu_write),

      .o_invalid_inst(o_invalid_inst)
     );

   reg [`DATA_WIDTH-1:0]  bram_data_in;
   reg                    bram_write;
   reg [`DATA_WIDTH-1:0]  bram_data_out;
   reg [31:0]             bram_addr;
   wire [`BRAM_WIDTH-1:0] bram_addr_low = bram_addr[`BRAM_WIDTH-1:0];

   bram
     #(
       .DATA_WIDTH(`DATA_WIDTH),
       .ADDR_WIDTH(`BRAM_WIDTH)
     ) bram
     (
      .i_clk(i_clk),
      .i_data(bram_data_in),
      .i_addr(bram_addr_low),
      .i_write(bram_write),
      .o_data(bram_data_out)
     );

   reg [`DATA_WIDTH-1:0]  fifo_data_out;
   reg                    fifo_empty;
   reg                    fifo_read_enabled;

   reg [`DATA_WIDTH-1:0]  fifo_data_in;
   reg                    fifo_full;
   reg                    fifo_write_enabled;

   fifo
     #(
       .DATA_WIDTH(`DATA_WIDTH),
       .ADDR_WIDTH(4)
       ) fifo
       (
        .clk(i_clk),
        .rst(i_rst),

        // Read port
        .data_out(fifo_data_out),
        .empty_out(fifo_empty),
        .read_en_in(fifo_read_enabled),

        // Write port
        .data_in(fifo_data_in),
        .full_out(fifo_full),
        .write_en_in(fifo_write_enabled)
       );

   memmap memmap
     (
      // CPU interface
      .cpu_addr(cpu_addr),
      .cpu_write(cpu_write),
      .cpu_data_in(cpu_data_in),
      .cpu_data_out(cpu_data_out),

      // BRAM interface
      .bram_addr(bram_addr),
      .bram_write(bram_write),
      .bram_data_in(bram_data_in),
      .bram_data_out(bram_data_out),

      // FIFO write
      .fifo_data_in(fifo_data_in),
      .fifo_full(fifo_full),
      .fifo_write_enabled(fifo_write_enabled),

      // Control signals
      .invalid_addr(o_invalid_addr)
     );
endmodule
