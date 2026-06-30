module spi_top_tb;

reg clk1;
reg rst1;
reg enable1;
reg rst2;
reg start1;
reg miso1;

reg [7:0] data1;

wire cs1;
wire mosi1;

// Internal wires from DUT
wire sck1;
wire sck_pos1;
wire sck_neg1;

// Instantiate DUT
spi_top uut (
    .clk1(clk1),
    .rst1(rst1),
    .enable1(enable1),
    .rst2(rst2),
    .start1(start1),
    .data1(data1),
    .miso1(miso1),
    .cs1(cs1),
    .mosi1(mosi1)
);

// Access internal signals for monitoring
assign sck1     = uut.sck1;
assign sck_pos1 = uut.sck_pos1;
assign sck_neg1 = uut.sck_neg1;

// Clock generation
initial begin
    clk1 = 0;
    forever #10 clk1 = ~clk1;
end

// Test stimulus
initial begin

    rst1    = 1;
    rst2    = 1;
    enable1 = 0;
    start1  = 1;
    miso1   = 0;
    data1   = 8'b11010101;

    #40;

    rst1    = 0;
    rst2    = 0;
    enable1 = 1;

    #20;

    start1 = 1;
    @(posedge clk1);

    @(posedge clk1);
    miso1 = 1'b1;
  

    @(negedge sck1);
     miso1 = 1'b1;

    @(negedge sck1);
     miso1 = 1'b0;

    @(negedge sck1);
     miso1 = 1'b1;

    @(negedge sck1);
     miso1 = 1'b0;

    @(negedge sck1);
    miso1 = 1'b1;

    @(negedge sck1);
    miso1 = 1'b0;

    @(negedge sck1);
    miso1 = 1'b1;

  
    #100000;

    $finish;
end

// Monitor
initial begin
    $monitor("Time=%0t clk=%b sck=%b sck_pos=%b sck_neg=%b cs=%b mosi=%b miso=%b count=%0d state=%0d",
              $time,
              clk1,
              sck1,
              sck_pos1,
              sck_neg1,
              cs1,
              mosi1,
              miso1,
              uut.S2.count,
              uut.S2.state);
end

endmodule
