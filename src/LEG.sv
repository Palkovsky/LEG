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

   // CPU bus
   wire [31:0] cpu_addr;
   // Writing
   wire [`DATA_WIDTH-1:0]   cpu_data_out;
   wire                     cpu_wr_valid;
   reg                      cpu_wr_ready;
   wire [`DATA_WIDTH/8-1:0] cpu_bwe;
   // Reading
   reg [`DATA_WIDTH-1:0]  cpu_data_in;
   reg                    cpu_rd_valid;
   wire                   cpu_rd_ready;

   core core
     (
	    .i_clk(i_clk),
      .i_rst(i_rst),

      .o_addr(cpu_addr),
      .o_data(cpu_data_out),
      .o_wr_valid(cpu_wr_valid),
      .i_wr_ready(cpu_wr_ready),
      .o_byte_write_enable(cpu_bwe),
      .i_data(cpu_data_in),
      .i_rd_valid(cpu_rd_valid),
      .o_rd_ready(cpu_rd_ready),

      .o_invalid_inst(o_invalid_inst)
     );

   reg [7:0]              uart_in;
   reg                    uart_wr_valid;
   wire                   uart_wr_ready;
   wire [`TX_FIFO_DEPTH:0] uart_tx_free;

   wire                      uart_rx_present;
   wire [7:0]                uart_out;
   wire                      uart_rd_valid;
   reg                       uart_rd_ready;

   uartwriter #(.TX_FIFO_DEPTH(`TX_FIFO_DEPTH)) uart
     (
      .i_clk(i_clk),
      .i_rst(i_rst),

      .i_rx(rx),
      .o_tx(tx),

      .i_data_in(uart_in),
      .i_wr_valid(uart_wr_valid),
      .o_wr_ready(uart_wr_ready),
      .o_tx_free(uart_tx_free),

      .o_rx_present(uart_rx_present),
      .o_data_out(uart_out),
      .o_rd_valid(uart_rd_valid),
      .i_rd_ready(uart_rd_ready)
     );

   // MMIO
   wire [31:0]            mmio_addr;
   // Writing
   wire [`DATA_WIDTH-1:0] mmio_data_out;
   wire                   mmio_wr_valid;
   reg                    mmio_wr_ready = 0;
   // Reading
   reg [`DATA_WIDTH-1:0]  mmio_data_in = 0;
   reg                    mmio_rd_valid = 0;
   wire                   mmio_rd_ready;

   always_comb begin
      {
       mmio_data_in,
       mmio_rd_valid,
       mmio_wr_ready,
       uart_in,
       uart_wr_valid,
       uart_rd_ready
       } <= 0;

      case (mmio_addr[15:0])
        // UART TX
        'hFFFF: begin
           // On write, pass signals to uart TX.
           if (mmio_wr_valid)
             { uart_in, uart_wr_valid, mmio_wr_ready } <= { mmio_data_out[7:0], 1'b1, uart_wr_ready };

           // On read return free space in FIFO
           if (mmio_rd_ready) begin
              mmio_rd_valid <= 1;
              mmio_data_in <= uart_tx_free;
           end
        end
        // UART RX -> Read byte
        'hFFFE: begin
           if (mmio_rd_ready) begin
              mmio_data_in <= uart_out;
              { mmio_rd_valid, uart_rd_ready } <= { uart_rd_valid, 1'b1 };
           end
        end
        // UART RX -> Check if byte present
        'hFFFD: begin
           if (mmio_rd_ready) begin
              mmio_rd_valid <= 1;
              mmio_data_in <= uart_rx_present;
           end
        end
      endcase
   end

   memmap memmap
     (
      .i_clk(i_clk),
      .i_rst(i_rst),

      .i_cpu_addr(cpu_addr),
      .i_cpu_data(cpu_data_out),
      .i_wr_valid(cpu_wr_valid),
      .o_wr_ready(cpu_wr_ready),
      .i_cpu_bwe(cpu_bwe),
      .o_cpu_data(cpu_data_in),
      .o_rd_valid(cpu_rd_valid),
      .i_rd_ready(cpu_rd_ready),

      // MMIO
      .o_mmio_addr(mmio_addr),
      .i_mmio_data(mmio_data_in),
      .i_mmio_rd_valid(mmio_rd_valid),
      .o_mmio_rd_ready(mmio_rd_ready),
      .o_mmio_data(mmio_data_out),
      .o_mmio_wr_valid(mmio_wr_valid),
      .i_mmio_wr_ready(mmio_wr_ready),

      // Control
      .o_invalid_addr(o_invalid_addr)
     );
endmodule
