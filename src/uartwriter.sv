`include "common.svh"

module uartwriter
 #(
   TX_FIFO_DEPTH
 )
 (
  input                        i_clk,
  input                        i_rst,

  input                        i_rx,
  output                       o_tx,

  // TX
  input [7:0]                  i_data_in,
  input                        i_wr_valid,
  output reg                   o_wr_ready,
  output reg [TX_FIFO_DEPTH:0] o_tx_free,

  // RX
  output reg                   o_rx_present,
  output reg [7:0]             o_data_out,
  output reg                   o_rd_valid,
  input                        i_rd_ready
 );
   localparam
     TX_STATE_SIZE = 3,
     TX_IDLE = 3'h0,
     TX_FETCHING = 3'h1,
     TX_SENDING = 3'h2;

   reg [TX_STATE_SIZE-1:0]     tx_state = TX_IDLE;

   // TX FIFO
   // Reading
   wire [7:0]                  tx_fifo_out;
   wire                        tx_fifo_empty;
   reg                         tx_fifo_rd;
   // Writing
   reg [7:0]                   tx_fifo_in = 0;
   wire                        tx_fifo_full;
   reg                         tx_fifo_wr = 0;

   // UART TX
   reg                         tx_valid = 0;
   reg [7:0]                   tx_byte = 0;
   wire                        tx_ack;

   /*
    * TX and FIFO reading
    */
   assign tx_fifo_rd = (tx_state == TX_IDLE && !tx_fifo_empty);

   always @(posedge i_clk) begin
      if (i_rst) begin
         tx_state <= TX_IDLE;
         {
          tx_byte,
          tx_valid
         } <= 0;
      end
      else begin
         // TX
         case (tx_state)
           TX_IDLE: begin
              // tx_fifo_rd will be pulled high when fifo non-empty
              if (tx_fifo_rd) begin
                 tx_state <= TX_FETCHING;
              end
           end
           TX_FETCHING: begin
              tx_byte <= tx_fifo_out;
              tx_valid <= 1;
              tx_state <= TX_SENDING;
           end
           TX_SENDING: begin
              tx_valid <= 1;
              if (tx_ack) begin
                 tx_valid <= 0;
                 tx_state <= TX_IDLE;
              end
           end
      endcase
      end
   end

   /*
    * FIFO writing
    */
   always @(posedge i_clk) begin
      if (i_rst) begin
         o_wr_ready <= 0;
      end
      else begin
         o_wr_ready <= tx_fifo_wr;
      end
   end

   always_comb begin
      { tx_fifo_in, tx_fifo_wr } <= 0;
      // Valid high, not yet ACKnowledged with ready and space available.
      if (i_wr_valid && !o_wr_ready && !tx_fifo_full) begin
         tx_fifo_in <= i_data_in;
         tx_fifo_wr <= 1;
      end
   end

   // UART RX
   wire [7:0]                  rx_byte;
   reg [7:0]                   rx_buff = 0;
   reg                         rx_present = 0;
   wire                        rx_received;
   assign o_rx_present = rx_present;

   /*
    * RX
    */
   always @(posedge i_clk) begin
      if (i_rst) begin
         { rx_buff, rx_present } <= 0;
      end
      else begin
         if (i_rd_ready && o_rd_valid)
           { rx_buff, rx_present } <= 0;

         // New byte received. This will overwrite the buffer.
         if (rx_received)
            { rx_buff, rx_present } <= { rx_byte, 1'b1 };
      end
   end

   always_comb begin
      { o_data_out, o_rd_valid } <= { rx_buff, rx_present };
   end


   // 16x8 TX FIFO
   fifo
     #(.FIFO_WIDTH(8), .FIFO_DEPTH(TX_FIFO_DEPTH))
   tx_fifo
     (
      .clk(i_clk),
      .reset(i_rst),

      .data_out(tx_fifo_out),
      .fifo_empty(tx_fifo_empty),
      .read(tx_fifo_rd),

      .data_in(tx_fifo_in),
      .fifo_full(tx_fifo_full),
      .write(tx_fifo_wr),

      .fifo_counter(),
      .fifo_free(o_tx_free)
     );

   uart uart
     (
      .clk(i_clk),
      .rst(i_rst),

      .txd(o_tx),
      .tx_data(tx_byte),
      .tx_data_valid(tx_valid),
      .tx_data_ack(tx_ack),

      .rxd(i_rx),
      .rx_data_fresh(rx_received),
      .rx_data(rx_byte)
     );
endmodule
