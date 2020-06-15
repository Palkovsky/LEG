`include "common.svh"

module uartwriter
 (
  input                   i_clk,
  input                   i_rst,

  input                   rx,
  output                  tx,

  input                   fifo_empty,
  input [`DATA_WIDTH-1:0] fifo_data,
  output reg              fifo_read_en
 );

   localparam STATE_SIZE = 2;
   localparam IDLE = 2'h0, FETCHING = 2'h1, SENDING = 2'h2;

   reg [STATE_SIZE-1:0]   state = IDLE;
   reg                    transmit = 0;
   reg [7:0]              transmit_byte;
   wire                   transmitting;

   always @(posedge i_clk) begin
      if (i_rst) begin
         state <= IDLE;
         transmit <= 0;
         transmit_byte <= 0;
      end
      else begin
         case (state)
           IDLE: begin
              if (!fifo_empty) begin
                 state <= FETCHING;
                 fifo_read_en <= 1;
              end
           end
           FETCHING: begin
              fifo_read_en <= 0;
              transmit_byte <= fifo_data;
              transmit <= 1;
              state <= SENDING;
           end
           SENDING: begin
              transmit <= 0;
              if (!transmitting) begin
                 state <= IDLE;
              end
           end
      endcase
      end
   end

   uart uart
     (
      .clk(i_clk),
      .rst(i_rst),
      .rx(rx),
      .tx(tx),
      .transmit(transmit),
      .tx_byte(transmit_byte),
      .received(),
      .rx_byte(),
      .is_receiving(),
      .is_transmitting(transmitting),
      .recv_error()
     );
endmodule
