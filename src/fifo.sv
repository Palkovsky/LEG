module fifo
  #(DATA_WIDTH,
    ADDR_WIDTH,
    FIFO_DEPTH = (1 << ADDR_WIDTH)
   )(
     input wire                  clk,
     input wire                  rst,

     // Read port
     output reg [DATA_WIDTH-1:0] data_out,
     output reg                  empty_out,
     input wire                  read_en_in,

     // Write port
     input wire [DATA_WIDTH-1:0] data_in,
     output reg                  full_out,
     input wire                  write_en_in,

     // Control
     output reg [ADDR_WIDTH:0]   free
  );

   /////Internal connections & variables//////
  reg   [DATA_WIDTH-1:0]              memory [FIFO_DEPTH-1:0];
   wire [ADDR_WIDTH-1:0]              pNextWordToWrite, pNextWordToRead;
   wire                               EqualAddresses;
   wire                               NextWriteAddressEn, NextReadAddressEn;

   reg [ADDR_WIDTH:0]                 counter = 0;

   assign empty_out = (counter == 0);
   assign full_out = (counter == FIFO_DEPTH);

   wire                               read_req;
   wire                               write_req;
   assign read_req = read_en_in & !empty_out;
   assign write_req  = write_en_in & !full_out;

   assign free = FIFO_DEPTH-counter;

    //////////////Code///////////////
    //Data ports logic:
    always @ (posedge clk) begin
        if (read_req)
            data_out <= memory[pNextWordToRead];

       if (write_req)
           memory[pNextWordToWrite] <= data_in;

       if (read_req && write_req) begin end
       else if (read_req)
          counter <= counter-1;
       else if (write_req)
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
        .Clk(clk)
       );

   GrayCounter #(.COUNTER_WIDTH(ADDR_WIDTH)) GrayCounter_pRd
     (.GrayCount_out(pNextWordToRead),
      .Enable_in(NextReadAddressEn),
      .Clear_in(rst),
      .Clk(clk)
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
