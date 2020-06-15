module fifo
  #(DATA_WIDTH,
    ADDR_WIDTH,
    FIFO_DEPTH = (1 << ADDR_WIDTH)
   )(
     // Read port
     output reg [DATA_WIDTH-1:0] data_out,
     output reg                  empty_out,
     input wire                  read_en_in,
     input wire                  read_clk,

     // Write port
     input wire [DATA_WIDTH-1:0] data_in,
     output reg                  full_out,
     input wire                  write_en_in,
     input wire                  write_clk,

     input wire                  rst
   );

   /////Internal connections & variables//////
  reg   [DATA_WIDTH-1:0]              memory [FIFO_DEPTH-1:0];
   wire [ADDR_WIDTH-1:0]              pNextWordToWrite, pNextWordToRead;
   wire                               EqualAddresses;
   wire                               NextWriteAddressEn, NextReadAddressEn;

   reg [ADDR_WIDTH:0]                 counter = 0;

   assign empty_out = (counter == 0);
   assign full_out = (counter == FIFO_DEPTH);

    //////////////Code///////////////
    //Data ports logic:
    //(Uses a dual-port RAM).
    //'data_out' logic:
    always @ (posedge read_clk)
        if (read_en_in & !empty_out) begin
            data_out <= memory[pNextWordToRead];
           counter <= counter-1;
        end

    //'data_in' logic:
    always @ (posedge write_clk)
        if (write_en_in & !full_out) begin
           memory[pNextWordToWrite] <= data_in;
           counter <= counter+1;
        end

    //Fifo addresses support logic:
    //'Next Addresses' enable logic:
    assign NextWriteAddressEn = write_en_in & ~full_out;
    assign NextReadAddressEn  = read_en_in  & ~empty_out;

    //Addreses (Gray counters) logic:
    GrayCounter #(.COUNTER_WIDTH(ADDR_WIDTH)) GrayCounter_pWr
       (.GrayCount_out(pNextWordToWrite),
        .Enable_in(NextWriteAddressEn),
        .Clear_in(rst),
        .Clk(write_clk)
       );

   GrayCounter #(.COUNTER_WIDTH(ADDR_WIDTH)) GrayCounter_pRd
     (.GrayCount_out(pNextWordToRead),
      .Enable_in(NextReadAddressEn),
      .Clear_in(rst),
      .Clk(read_clk)
     );
endmodule


module GrayCounter
   #(parameter   COUNTER_WIDTH = 4)

    (output reg  [COUNTER_WIDTH-1:0]    GrayCount_out,  //'Gray' code count output.

     input wire                         Enable_in,  //Count enable.
     input wire                         Clear_in,   //Count reset.

     input wire                         Clk);

    /////////Internal connections & variables///////
    reg    [COUNTER_WIDTH-1:0]         BinaryCount;

    /////////Code///////////////////////

    always @ (posedge Clk)
        if (Clear_in) begin
            BinaryCount   <= {COUNTER_WIDTH{1'b 0}} + 1;  //Gray count begins @ '1' with
            GrayCount_out <= {COUNTER_WIDTH{1'b 0}};      // first 'Enable_in'.
        end
        else if (Enable_in) begin
            BinaryCount   <= BinaryCount + 1;
            GrayCount_out <= {BinaryCount[COUNTER_WIDTH-1],
                              BinaryCount[COUNTER_WIDTH-2:0] ^ BinaryCount[COUNTER_WIDTH-1:1]};
        end
endmodule
