`timescale 1ns / 1ps

module random_logic #(parameter WL = 4)
                     (input RST, CLK, mode, // Control signals
                      one, two, three, // Scoring signals
                      output reg [3:0] anodes, // 4-digit anodes control
                      output reg [6:0] cathodes, // 7-segment cathodes control
                      output reg [15:0] winner_flag // 16-bit LEDs for winner indication
                      );
             
   // Finite-state Machine for Binary Coded Decimal Decoder               
   localparam ZERO =  0, ONE = 1, TWO = 2, THREE = 3, 
              FOUR = 4, FIVE = 5, SIX = 6, SEVEN = 7, 
              EIGHT = 8, NINE = 9;
           
   //-----------------Random Logic Variables-----------------         
   reg [WL-2:0] p1_seed = 3'b001; // P1 random seed
   reg [WL-2:0] p2_seed = 3'b111; // P2 random seed
   reg [WL-2:0] p1_temp = 0; // P1 placeholder for LFSR & XOR
   reg [WL-2:0] p2_temp = 0; // P2 placeholder for LFSR & XOR
   reg [WL-1:0] p1_total, p2_total; //P1&P2 current points counters
   
   //-----------------BCD Decoder Variables-----------------                 
   reg [26:0] clk_counter; //Clock counter up to one tenth of a second (one second is '100,000,000')
   wire tenth_second_flag; //One tenth of a second flag || '10,000,000' or hit '9,999,999'
   wire [1:0] LED_activate; // LED digit select flag (2-bit for 4 LEDs)
   reg [WL:0] total_select; // Selecting which digit to display
   reg [19:0] refresh_period; //20-bit for 10.5 ms refresh period => 2.6 ms each digit
   
   // Clock counter: will count up to one tenth of a second and reset 
   always @(posedge CLK or posedge RST) begin
   if (RST) clk_counter <= 0;
   else begin
        if(clk_counter >= 9999999) clk_counter <= 0;
        else clk_counter = clk_counter + 1'b1;
        end
   end
   
   // When the clock hits one tenth of a second,this flag is raised!
   assign tenth_second_flag = (clk_counter == 9999999) ? 1'b1 : 1'b0;
  
  //Seeds XORing and Points Checking
    always @(posedge CLK or posedge RST) begin
    if (RST) begin 
        p1_total <= 0; // Player 1 total points counter reset
        p2_total <= 0; // Player 2 total points counter reset
        p1_temp <= p1_seed; // 001
        p2_temp <= p2_seed; // 111
        winner_flag <= 16'h0000; // LEDs reset
        end
    else begin
        if(tenth_second_flag)begin // When the one tenth of a second flag is raised
            if(mode == 0) begin // Player 1
            p1_temp <= {p1_temp[1] ^ p1_temp[0], p1_temp[2], p1_temp[1]}; // XOR & right shifting 
                if(one) begin
                    if(p1_temp == 3'b010 || p1_temp == 3'b100 || p1_temp == 3'b110) begin // if 2,4,6
                        p1_total <= p1_total + 1'b1; end // Rewards 1 point
                        else p1_total <= p1_total; end // If not matched => current points stay the same
                if(two) begin
                    if(p1_temp == 3'b011 || p1_temp == 3'b110) begin //if 3,6
                        p1_total <= p1_total + 2'b10; end // Rewards 2 points
                        else p1_total <= p1_total; end // If not matched => current points stay the same
                if(three) begin
                    if(p1_temp == 3'b100) begin // if 4
                        p1_total <= p1_total + 2'b11; end // Rewards 3 points
                        else p1_total <= p1_total; end // If not matched => current points stay the same
            end
            if(mode == 1) begin // Player 2
            p2_temp <= {p2_temp[1] ^ p2_temp[0], p2_temp[2], p2_temp[1]}; // XOR & right shifting  
                if(one) begin
                    if(p2_temp == 3'b010 || p2_temp == 3'b100 || p2_temp == 3'b110) begin // if 2,4,6
                        p2_total <= p2_total + 1'b1; end // Reward 1 point
                        else p2_total <= p2_total; end // If not matched => current points stay the same
                if(two) begin
                    if(p2_temp == 3'b011 || p2_temp == 3'b110) begin //if 3,6
                        p2_total <= p2_total + 2'b10; end // Reward 2 points
                        else p2_total <= p2_total; end // If not matched => current points stay the same
                if(three) begin
                    if(p2_temp == 3'b100) begin // if 4
                        p2_total <= p2_total + 2'b11; end // Reward 3 points
                        else p2_total <= p2_total; end // If not matched => current points stay the same
             end       
        end
        // If total points reach 11,12 or 13 => points reset & all 16 LEDS light up!
        if((p1_total == 11 || p1_total == 12 || p1_total == 13) && (p2_total >=0)) begin
             p1_total <= 0; 
             winner_flag <= 16'hffff; 
             end
        if((p2_total == 11 || p2_total == 12 || p2_total == 13) && (p1_total >=0)) begin 
             p2_total <= 0; 
             winner_flag <= 16'hffff; 
             end     
        end
    end
    
    // Period Refreshing for 4 digits
    always @(posedge CLK or posedge RST) begin
    if (RST) refresh_period <= 0;
    else begin
        refresh_period = refresh_period + 1;
        end
    end

    assign LED_activate = refresh_period[19:18]; // Digit select flag
    
    // Each digit will take turn to assign a value to display
    always @(*) begin
        case(LED_activate)
        2'b00: begin
                anodes = 4'b1110; // First digit: 0-9
                total_select <= p2_total % 10; 
                end     
        2'b01: begin
                anodes = 4'b1101; // Second Digit 0-1
                total_select <= p2_total / 10; 
                end
        2'b10: begin
                anodes = 4'b1011; // Third Digit 0-9
                total_select <= p1_total % 10; 
                end
        2'b11: begin
                anodes = 4'b0111; // Fourth Digit 0-1
                total_select <= p1_total / 10; 
                end
        endcase
    end
    
    // Each digit will display according to its assign value
    always @(*) begin 
        case(total_select) 
            ZERO: cathodes = 7'b0000001; // Displaying 0 (4'b0000)
            ONE: cathodes = 7'b1001111; // Displaying 1 (4'b0001)
            TWO: cathodes = 7'b0010010; // Displaying 2 (4'b0010)
            THREE: cathodes = 7'b0000110; // Displaying 3 (4'b0011)
            FOUR: cathodes = 7'b1001100; // Displaying 4 (4'b0100)
            FIVE: cathodes = 7'b0100100; // Displaying 5 (4'b0101)
            SIX: cathodes = 7'b0100000; // Displaying 6 (4'b0110)
            SEVEN: cathodes = 7'b0001111; // Displaying 7 (4'b0111)
            EIGHT: cathodes = 7'b0000000; // Displaying 8 (4'b1000)
            NINE: cathodes = 7'b0000100; // Displaying 9 (4'b1001)
            default: cathodes = 7'b0000001; // Displaying 0 (4'b0000)
        endcase
    end
               
endmodule

