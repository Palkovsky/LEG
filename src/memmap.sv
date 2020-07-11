`include "common.svh"

module memmap
  (
   input                        i_clk,
   input                        i_rst,
   // CPU interface
   input [31:0]                 i_cpu_addr,
   // Writing
   input [`DATA_WIDTH-1:0]      i_cpu_data,
   input                        i_wr_valid,
   input logic [2:0]            i_wr_width,
   output reg                   o_wr_ready,
   // Reading
   output reg [`DATA_WIDTH-1:0] o_cpu_data,
   output reg                   o_rd_valid,
   input                        i_rd_ready,

   // MMIO
   output reg [31:0]            o_mmio_addr,
   // Reading
   input [`DATA_WIDTH-1:0]      i_mmio_data,
   input                        i_mmio_rd_valid,
   output reg                   o_mmio_rd_ready,
   // Writing
   output reg [`DATA_WIDTH-1:0] o_mmio_data,
   output reg                   o_mmio_wr_valid,
   input                        i_mmio_wr_ready,

   // Control signals
   output reg                   o_invalid_addr
 );
   localparam
     BRAM_SIZE = 1<<`BRAM_WIDTH,
     MMIO_MIN_ADDR = 32'hFFFF0000,
     MMIO_MAX_ADDR = 32'hFFFFFFFF;

   reg [31:0]                   bram_addr = 0;
   wire [`BRAM_WIDTH-1:0]       bram_addr_low = bram_addr[`BRAM_WIDTH-1:0];
   reg [`DATA_WIDTH-1:0]        bram_data_in = 0;
   reg                          bram_wr_valid = 0;
   wire                         bram_wr_ready;
   wire [`DATA_WIDTH-1:0]       bram_data_out;
   wire                         bram_rd_valid;
   reg                          bram_rd_ready = 0;
   logic [`DATA_WIDTH/8-1:0]    bram_byte_write_enable = 0;

   always_comb begin
      {
       o_invalid_addr,
       bram_addr,
       bram_data_in,
       bram_wr_valid,
       bram_byte_write_enable,
       bram_rd_ready,
       o_mmio_addr,
       o_mmio_data,
       o_mmio_rd_ready,
       o_mmio_wr_valid,
       o_wr_ready,
       o_cpu_data,
       o_rd_valid
      } <= 0;

      if (i_cpu_addr >= MMIO_MIN_ADDR && i_cpu_addr <= MMIO_MAX_ADDR) begin
         // MMIO access
         o_mmio_addr <= i_cpu_addr;
         // Reading
         { o_cpu_data, o_rd_valid, o_mmio_rd_ready } <= { i_mmio_data, i_mmio_rd_valid, i_rd_ready };
         // Writing
         { o_mmio_data, o_mmio_wr_valid, o_wr_ready } <= { i_cpu_data, i_wr_valid, i_mmio_wr_ready };
      end
      else if (i_cpu_addr >= 0 && i_cpu_addr < BRAM_SIZE) begin
         // BRAM access
         bram_addr <= (i_cpu_addr >> 2);
         case (i_wr_width)
           1:
             bram_byte_write_enable <= 4'b0001 << i_cpu_addr[1:0];
           2: begin
              bram_byte_write_enable <= 4'b0011 << i_cpu_addr[1:0];
              if (i_cpu_addr[0] != 0) begin
                 o_invalid_addr <= 1;
              end
           end
           4: begin
              bram_byte_write_enable <= 4'b1111;
              if (i_cpu_addr[1:0] != 0) begin
                 o_invalid_addr <= 1;
              end
           end
         endcase
         bram_data_in <= i_cpu_data << (8 * i_cpu_addr[1:0]);
         o_cpu_data <= bram_data_out >> (8 * i_cpu_addr[1:0]);
         { o_rd_valid, bram_rd_ready } <= { bram_rd_valid, i_rd_ready };
         { bram_wr_valid, o_wr_ready } <= { i_wr_valid, bram_wr_ready };
      end
      else begin
         o_invalid_addr <= 1;
      end
   end

   bram_rv
     #(
       .DATA_WIDTH(`DATA_WIDTH),
       .ADDR_WIDTH(`BRAM_WIDTH)
     ) bram
     (
	    .i_clk(i_clk),
      .i_rst(i_rst),
      .i_addr(bram_addr_low),

      .i_data(bram_data_in),
      .i_byte_write_enable(bram_byte_write_enable),
      .i_wr_valid(bram_wr_valid),
      .o_wr_ready(bram_wr_ready),

      .o_data(bram_data_out),
      .o_rd_valid(bram_rd_valid),
      .i_rd_ready(bram_rd_ready)
     );

endmodule
