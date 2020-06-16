`include "common.svh"

module memmap
  (
   input                        clk,
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


   // MMIO outputs
   output                       mmio_access,
   output reg [31:0]            mmio_addr,
   output reg                   mmio_write,
   input [`DATA_WIDTH-1:0]      mmio_data_in,
   output reg [`DATA_WIDTH-1:0] mmio_data_out,

   // Control signals
   output reg                   invalid_addr
 );

   localparam BRAM_SIZE = 1<<`BRAM_WIDTH;
   localparam MMIO_MIN_ADDR = 32'hFFFF0000;
   localparam MMIO_MAX_ADDR = 32'hFFFFFFFF;

   localparam BAD_ACCESS = 2'b00, BRAM_ACCESS = 2'b01, MMIO_ACCESS = 2'b10;
   reg [1:0]                    access_ty;

   assign mmio_access = (access_ty == MMIO_ACCESS);

   reg                          mmio_read_prev = 0;
   reg [`DATA_WIDTH-1:0]        mmio_data_prev = 0;

   always_comb begin
      // Defaults
      bram_addr <= 0;
      bram_write <= 0;
      bram_data_in <= 0;
      mmio_data_out <= 0;
      mmio_addr <= 0;
      mmio_write <= 0;
      access_ty <= BAD_ACCESS;
      cpu_data_in <= 0;
      invalid_addr <= 0;

      // MMIO access. It accepts only writes from the CPU.
      if (mmio_read_prev) begin
         cpu_data_in <= mmio_data_prev;
      end
      else if (cpu_addr >= MMIO_MIN_ADDR && cpu_addr <= MMIO_MAX_ADDR) begin
         access_ty <= MMIO_ACCESS;
         { mmio_addr, mmio_write, mmio_data_out} <= { cpu_addr, cpu_write, cpu_data_out };
         if (!cpu_write)
           cpu_data_in <= mmio_data_in;
      end
      // BRAM access
      else if (cpu_addr < BRAM_SIZE) begin
         access_ty <= BRAM_ACCESS;
         { bram_addr, bram_write, bram_data_in } <= { cpu_addr, cpu_write, cpu_data_out };
         if (!cpu_write)
           cpu_data_in <= bram_data_out;
      end
      // Unmaped area access
      else
         invalid_addr <= 1;
   end

   always @(posedge clk) begin
      mmio_read_prev <= (access_ty == MMIO_ACCESS && !cpu_write);
      mmio_data_prev <= mmio_data_in;
   end
endmodule
