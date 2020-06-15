`include "common.svh"

module uartwriter
 (
  input                   clk,
  input                   rst,

  input                   rx,
  output                  tx,

  input                   fifo_empty,
  input [`DATA_WIDTH-1:0] fifo_data,
  output reg              fifo_read_en = 0
 );

   localparam STATE_SIZE = 3;
   localparam
     IDLE = 3'h0,
     FETCHING = 3'h1,
     SEND_START_WAIT = 3'h2,
     SENDING = 3'h3;

   reg [STATE_SIZE-1:0]   state = IDLE;
   reg                    transmit = 0;
   reg [7:0]              transmit_byte = 0;
   wire                   transmitting;

   always @(posedge clk) begin
      if (rst) begin
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
              transmit_byte <= fifo_data;
              fifo_read_en <= 0;
              state <= SEND_START_WAIT;
              transmit <= 1;
           end
           SEND_START_WAIT: begin
              if (!transmitting) begin
                 transmit <= 1;
              end
              else begin
                 transmit <= 0;
                 state <= SENDING;
              end
           end
           SENDING: begin
              if (!transmitting) begin
                 state <= IDLE;
                 transmit_byte <= 0;
              end
           end
      endcase
      end
   end

   uart uart
     (
      .clk(clk),
      .rst(rst),
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
