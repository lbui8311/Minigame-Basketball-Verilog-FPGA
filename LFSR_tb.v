`timescale 1ns / 1ps

module LFSR_tb;

    reg CLK, RST;
    wire [2:0] out;
    
   LFSR_test TES0 (.CLK (CLK),.RST (RST),.out (out));
   
   always begin
       CLK = 1;
       #5; CLK = 0;
       #5;
   end
   
   initial begin
       RST = 1;
       @(posedge CLK); RST = 0;
       repeat (10) @(posedge CLK);
   $finish;
   end 
endmodule
