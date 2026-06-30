module spi_top(clk1,rst1,enable1,rst2,start1,data1,miso1,cs1,mosi1);
input clk1,rst1,enable1,rst2,start1,miso1;
input [7:0]data1;

output cs1,mosi1;
wire sck1,sck_neg1,sck_pos1;

spiclock S1(clk1,rst1,enable1,sck1,sck_pos1,sck_neg1);
spifsm   S2(clk1,rst2,start1,data1,miso1,sck_pos1,sck_neg1,cs1,mosi1);

endmodule


module spiclock #(
    parameter DIVIDER = 8
)(
    input  wire clk,
    input  wire rst,
    input  wire enable,
    
    output reg  sck,
    output wire sck_pos, // Edge detection pulse (rising)
    output wire sck_neg  // Edge detection pulse (falling)
);

    // Calculate max count: (8 / 2) - 1 = 3
    localparam MAX_COUNT = (DIVIDER / 2) - 1; 
    
    // Calculate required width for the counter register
    // For MAX_COUNT = 3, we need 2 bits: reg [1:0] counter;
    reg [$clog2(DIVIDER/2)-1:0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            sck     <= 1'b0;
        end else if (enable) begin
            if (counter == MAX_COUNT) begin
                counter <= 0;
                sck     <= ~sck; // Toggle the clock to get a 50% duty cycle
            end else begin
                counter <= counter + 1;
            end
        end else begin
            counter <= 0;
            sck     <= 1'b0; // Default idle state (CPOL = 0)
        end
    end

    // Edge generation logic (essential for driving your SPI State Machine)
    assign sck_pos = (enable && (counter == MAX_COUNT) && (sck == 1'b0));
    assign sck_neg = (enable && (counter == MAX_COUNT) && (sck == 1'b1));

endmodule


module spifsm(
    input clk,
    input rst,
    input start,
    input [7:0] data,
    input miso,
    input sck_pos,
    input sck_neg,

    output reg cs,
    output reg mosi
);

localparam IDLE     = 2'b00;
localparam LEAD     = 2'b01;
localparam TRANSFER = 2'b10;
localparam TRAIL    = 2'b11;

reg [7:0] tx_data;
reg [7:0] rx_data;

reg [1:0] state;
reg [1:0] nextstate;

reg [3:0] count;


//----------------------------------------------
// State Register
//----------------------------------------------
always @(posedge clk) begin
    if (rst)
        state <= IDLE;
    else
        state <= nextstate;
end


//----------------------------------------------
// Bit Counter
//----------------------------------------------
always @(posedge clk) begin
    if (rst)
        count <= 4'd0;

    else if (state == TRANSFER) begin
        if (sck_neg)
            count <= count + 1'b1;
    end

    else
        count <= 4'd0;
end


//----------------------------------------------
// Data Transfer
//----------------------------------------------
always @(posedge clk) begin

    if (rst) begin
        tx_data <= 8'd0;
        rx_data <= 8'd0;
        mosi    <= 1'b0;
    end

    else begin

        // Load transmit data
        if (state == IDLE && start)
            tx_data <= data;
            

        // Present first bit before clock starts
        else if (state == LEAD)
            mosi <= tx_data[7];

        // Transfer Data
        else if (state == TRANSFER) begin

            // Sample MISO
            if (sck_pos)
                rx_data[6-count] <= miso;

            // Update MOSI
            else if (sck_neg)
                mosi <= tx_data[6-count];

        end
    end
end


//----------------------------------------------
// Next State Logic & CS
//----------------------------------------------
always @(*) begin

    nextstate = state;
    cs = 1'b1;

    case (state)

        IDLE: begin
            cs = 1'b1;

            if (start)
                nextstate = LEAD;
        end

        LEAD: begin
            cs = 1'b0;
            nextstate = TRANSFER;
        end

        TRANSFER: begin
            cs = 1'b0;

            if (count == 4'd8)
                nextstate = TRAIL;
            else
                nextstate = TRANSFER;
        end

        TRAIL: begin
            cs = 1'b1;
            nextstate = IDLE;
        end

        default: begin
            cs = 1'b1;
            nextstate = IDLE;
        end

    endcase

end

endmodule
