`timescale 1ns / 1ps

module LFSR_test (input CLK, RST,
              output reg [2:0] out);
  
     always @(posedge CLK) begin
         if(RST) out <= 3'b111; // Assign seed
         else out <= {out[1]^out[0], out[2], out[1]}; //Right shifting
     end
   
endmodule
