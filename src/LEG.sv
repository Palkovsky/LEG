`include "common.svh"

module LEG(
  input  i_clk,
  input  i_rst,

  // UART
  input  rx,
  output tx,

  // Error signals
  output o_invalid_inst,
  output o_invalid_addr,

  output o_buzzer
);

   wire [31:0] cpu_addr;
   wire [`DATA_WIDTH-1:0] cpu_data_out;
   wire [`DATA_WIDTH-1:0]  cpu_data_in;
   wire                   cpu_write;
	wire [31:0]            pc;

	assign o_buzzer = 1;

   core core
     (
	    .i_clk(i_clk),
      .i_rst(i_rst),

      .o_mem_addr(cpu_addr),
      .o_mem_data(cpu_data_out),
      .i_mem_data(cpu_data_in),
      .o_mem_write(cpu_write),

      .o_invalid_inst(o_invalid_inst),
		  .o_pc(pc)
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

   reg [4:0]              fifo_free;

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
        .write_en_in(fifo_write_enabled),

        .free(fifo_free)
       );

   reg                    mmio_access;
   reg [31:0]             mmio_addr;
   reg                    mmio_write;
   reg [`DATA_WIDTH-1:0]  mmio_data_in = 0;
   reg [`DATA_WIDTH-1:0]  mmio_data_out;

   reg                    uart_rx_read = 0;
   wire                   uart_rx_avail;
   wire [`DATA_WIDTH-1:0] uart_rx_data;

   always_comb begin
      // Defaults
      fifo_write_enabled <= 0;
      fifo_data_in <= 0;
      uart_rx_read <= 0;
		  mmio_data_in <= 0;

      if (mmio_access) begin
         // UART FIFO
         case (mmio_addr)
           32'hFFFFFFFF: begin
              if (mmio_write) begin
                 if (!fifo_full) begin
                    fifo_write_enabled <= 1;
                    fifo_data_in <= mmio_data_out;
                 end
              end
              else begin
                 mmio_data_in <= { 3'b0, fifo_free };
              end
           end
           32'hFFFFFFFE: begin
              if (!mmio_write && uart_rx_avail) begin
                 mmio_data_in <= uart_rx_data;
                 uart_rx_read <= 1;
              end
           end
           32'hFFFFFFFD: begin
              if (!mmio_write) begin
                 mmio_data_in <= { 7'b0, uart_rx_avail };
              end
           end
         endcase
      end
   end

   memmap memmap
     (
      .clk(i_clk),

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

      // MMIO access
      .mmio_access(mmio_access),
      .mmio_addr(mmio_addr),
      .mmio_write(mmio_write),
      .mmio_data_in(mmio_data_in),
      .mmio_data_out(mmio_data_out),

      // Control signals
      .invalid_addr(o_invalid_addr)
     );

	  uartwriter uartwriter
		(
		 .clk(i_clk),
		 .rst(i_rst),

		 .rx(rx),
		 .tx(tx),

		 .fifo_empty(fifo_empty),
		 .fifo_data(fifo_data_out),
		 .fifo_read_en(fifo_read_enabled),

     .rx_read(uart_rx_read),
     .rx_available(uart_rx_avail),
     .rx_data(uart_rx_data)
		);
endmodule
