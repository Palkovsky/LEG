`include "common.svh"

module memmap
  (
   // CPU interface
   input [31:0]                 cpu_addr,
   input                        cpu_write,
   output reg [`DATA_WIDTH-1:0] cpu_data_in,
   input [`DATA_WIDTH-1:0]      cpu_data_out,

   // BRAM interface
   output reg [31:0]            bram_addr,
   output reg                   bram_write,
   output reg [`DATA_WIDTH-1:0] bram_data_in,
   input [`DATA_WIDTH-1:0]      bram_data_out,

   // FIFO write
   output reg [`DATA_WIDTH-1:0] fifo_data_in,
   input                        fifo_full,
   output reg                   fifo_write_enabled,

   // Control signals
   output reg                   invalid_addr
 );

   localparam BRAM_SIZE = 1<<`BRAM_WIDTH;
   localparam FIFO_ADDR = 32'hFFFFFFFF;

   localparam BAD_ACCESS = 2'b00, BRAM_ACCESS = 2'b01, FIFO_ACCESS = 2'b10;
   reg [1:0]                    access_ty;

   always_comb begin
      // Defaults
      bram_addr <= 0;
      bram_write <= 0;
      bram_data_in <= 0;
      fifo_data_in <= 0;
      fifo_write_enabled <= 0;
      invalid_addr <= 0;
      access_ty <= BAD_ACCESS;
      cpu_data_in <= 0;

      // BRAM access
      if (cpu_addr < BRAM_SIZE) begin
         access_ty <= BRAM_ACCESS;
         { bram_addr, bram_write, bram_data_in } <= { cpu_addr, cpu_write, cpu_data_out };
         if (cpu_write)
           cpu_data_in <= bram_data_out;
      end
      // FIFO access. It accepts only writes from the CPU.
      else if (cpu_addr == FIFO_ADDR) begin
         access_ty <= FIFO_ACCESS;
         if (!fifo_full && cpu_write)
           { fifo_data_in, fifo_write_enabled } <= { cpu_data_out, 1'b1 };
      end
      // Unmaped area access
      else begin
         invalid_addr <= 1;
      end
   end
endmodule
