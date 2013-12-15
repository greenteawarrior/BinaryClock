`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:12:57 12/15/2013 
// Design Name: 
// Module Name:    OutputTwoHzSignal 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////


//Original code from http://www.electro-tech-online.com/threads/fpga-led-help-w-verilog.106139/ forum post 
//and modified (i.e. the counter chunk of code) it for our purposes :[

module OutputTwoHzSignal(Fout, CLK_50M);

                input CLK_50M;
                
                output reg Fout;
                reg [26:0] counter;

                initial begin
                counter='b0;
                end

                always @(posedge CLK_50M) begin
                   counter <= counter+1;
                                
                                if (counter == 'b1011111010111100001000000) begin //chopped off two of the zeroes to divide by 2
                                                Fout = ~Fout;
                                                counter <= 'b0;
                                end 
                   
                end
                
endmodule 


//minimum deliverable - stopwatch.
module Stopwatch(ResetSeconds, Hours, Minutes, Seconds, clk); 
  //insert frequency divider and set/enable shenanigans
  
  //defining outputs and inputs
  output reg [4:0] Hours;
  output reg [5:0] Minutes;  
  output reg [5:0] Seconds;
  input clk;

  //debugging
  output ResetSeconds; 

  //some intermediate stuff
  wire TwoHzSignal;
  wire [4:0] IncrementedHours;
  wire [4:0] NewHours;
  wire [5:0] IncrementedMinutes;
  wire [5:0] NewMinutes;
  wire [5:0] IncrementedSeconds;
  wire [5:0] NewSeconds;
  reg One;
  reg [4:0] TwentyThree;
  reg [5:0] FiftyNine;


  //initializing!
  initial begin
    Hours = 'b0;
    Minutes = 'b0;
    Seconds = 'b0;
    //forcing these constants to be the proper width... grr.
    One = 'b1;
    TwentyThree = 'b10111;
    FiftyNine = 'b111011;
  end

  //seconds shenanigans
  SixBitIncrement SecondsSBI (IncrementedSeconds, Seconds, One);
  SixBitXNOR SecondsXNOR (ResetSeconds, Seconds, FiftyNine);
  SixBitMux SecondsMux (NewSeconds, IncrementedSeconds, ResetSeconds);

  //minutes shenanigans
  SixBitIncrement MinutesSBI (IncrementedMinutes, Minutes, ResetSeconds);
  SixBitXNOR MinutesXNOR (ResetMinutes, Minutes, FiftyNine);
  SixBitMux MinutesMux (NewMinutes, IncrementedMinutes, ResetMinutes);

  //hours shenanigans
  FiveBitIncrement HoursFBI (IncrementedHours, Hours, ResetMinutes);
  FiveBitXNOR HoursXNOR (ResetHours, Hours, TwentyThree);
  FiveBitMux HoursMux (NewHours, IncrementedHours, ResetHours);
  
  OutputTwoHzSignal GeneratingTwoHzSignal (TwoHzSignal, clk);
  
  always @ (posedge TwoHzSignal) begin
    Seconds <= NewSeconds;
    Minutes <= NewMinutes;
    Hours <= NewHours;
  end
endmodule


//register module for storing the minutes and seconds
//six bits because d60 is a 6-bit number
module SixBitRegister(Dout, Din, clk);
  //defining outputs and inputs
  output reg [5:0] Dout;
  input [5:0] Din;
  input clk;
  
  //le registers
  always @ (posedge clk)
    Dout = Din;
endmodule

//register module for storing the hours 
//five bits because d24 is a 5-bit number
module FiveBitRegister(Dout, Din, clk);
  //defining outputs and inputs
  output reg [4:0] Dout;
  input [4:0] Din;
  input clk;
  
  //le registers
  always @ (posedge clk)
    Dout = Din;
endmodule


//six bit adder! for the minutes and seconds folks
//we're doing this in behavioral because we already know how to 
//make adders in structural and would like to save some typing...
module SixBitIncrement(SBIOut, A, Cin);
  //defining outputs and inputs
  output reg [5:0] SBIOut;
  input [5:0] A;
  input Cin;

  //clarifying some adder-esque things
  //B is always 0
  //Cout will never be a thing because we won't go above 60

  //le add
  always @ *
    SBIOut = A + Cin;
endmodule


//five bit adder! for the hours
//we're doing this in behavioral because we already know how to 
//make adders in structural and would like to save some typing...
module FiveBitIncrement(FBIOut, A, Cin);
  //defining outputs and inputs
  output reg [4:0] FBIOut;
  input [4:0] A;
  input Cin;

  //clarifying some adder-esque things
  //B is always 0
  //Cout will never be a thing because we won't go above 60

  //le add
  always @ *
    FBIOut = A + Cin;
endmodule

//two input six bit mux! for the minutes and seconds (what a surprise)
//we're doing this in behavioral because we already know how to
//make muxes in structural and would like to save some typing...
module SixBitMux(SBMOut, A, Select);
  //defining ouputs and inputs
  output reg [5:0] SBMOut;
  input [5:0] A; //signal A
  //signal B is always zero
  input Select;

  always @ * begin
    if (Select == 0) begin
      SBMOut = A;
    end else if (Select == 1) begin
      SBMOut = 'b0;
    end
  end
endmodule


//two input five bit mux! for the hours (what a surprise)
//we're doing this in behavioral because we already know how to
//make muxes in structural and would like to save some typing...
module FiveBitMux(FBMOut, A, Select);
  //defining outputs and inputs
  output reg [4:0] FBMOut;
  input [4:0] A; //signal A
  //signal B is always zero
  input Select;

  always @ * begin
    if (Select == 0) begin
      FBMOut = A;
    end else if (Select == 1) begin
      FBMOut = 'b0;
    end
  end
endmodule


//six bit xnor. for those minute and second things
module SixBitXNOR(SBXNOROut, A, B);
  //defining outputs and inputs
  output reg SBXNOROut; //gotta be one bit
  input [5:0] A;
  input [5:0] B;
  //reg [5:0] leXNOROut;

  //xnor leXNOR (leXNOROut, A, B);
  //behavioral to save typing
  always @ * begin
    SBXNOROut = ~(A[0]^B[0]) & ~(A[1]^B[1]) & ~(A[2]^B[2]) & ~(A[3]^B[3]) & ~(A[4]^B[4]) & ~(A[5]^B[5]);  
  end
endmodule


//five bit xnor. for that hour thing
module FiveBitXNOR(FBXNOROut, A, B);
  //defining outputs and inputs
  output reg FBXNOROut; //gotta be one bit
  input [4:0] A;
  input [4:0] B;
  //reg [4:0] leXNOROut;

  //xnor leXNOR (leXNOROut, A, B);
  //behavioral to save typing
  always @ * begin
    FBXNOROut = ~(A[0]^B[0]) & ~(A[1]^B[1]) & ~(A[2]^B[2]) & ~(A[3]^B[3]) & ~(A[4]^B[4]);  
  end
endmodule


/*module OutputTwoHzSignal (TheFout, TheFin);
  //this assumes a 25 MHz signal from the FPGA
  //The reason why it's 2Hz and not 1Hz because there's already a frequency divider in our clock code (see clock.v)
  
  //defining outputs and inputs
  output TheFout;
  input TheFin;
  
  //more intermediate stuff
  //for the eight DivideBy5 instances
  wire IntermediateF0;
  wire IntermediateF1;
  wire IntermediateF2;
  wire IntermediateF3;
  wire IntermediateF4;
  wire IntermediateF5;
  wire IntermediateF6;
  wire IntermediateF7;
  
  //for the five DivideBy2 instances  
  wire IntermediateF8;
  wire IntermediateF9;
  wire IntermediateF10;
  wire IntermediateF11;
  //the final DivideBy2 instance's output is Fout :P  
  
  //do stuff : a combination of the other modules gives us the desired signal
  
  //eight DivideBy5 instances will divide the signal by 5^8 
  DivideBy5 F0 (IntermediateF0, TheFin);
  DivideBy5 F1 (IntermediateF1, IntermediateF0);
  DivideBy5 F2 (IntermediateF2, IntermediateF1);
  DivideBy5 F3 (IntermediateF3, IntermediateF2);
  DivideBy5 F4 (IntermediateF4, IntermediateF3);
  DivideBy5 F5 (IntermediateF5, IntermediateF4);
  DivideBy5 F6 (IntermediateF6, IntermediateF5);
  DivideBy5 F7 (IntermediateF7, IntermediateF6);
  
  //five DivideBy2 instances will divide the signal by 2^5
  DivideBy2 F8  (IntermediateF8, IntermediateF7);
  DivideBy2 F9  (IntermediateF9, IntermediateF8);
  DivideBy2 F10 (IntermediateF10, IntermediateF9);
  DivideBy2 F11 (IntermediateF11, IntermediateF10);
  DivideBy5 F12 (TheFout, IntermediateF11);
  
endmodule


module DivideBy2(Fout2, Fin);
  //define outputs and inputs
  output reg Fout2;
  input Fin;
  
  //do stuff: chain DFFout to the clock input of FF
  initial begin
    Fout2=0;
  end
  
  always @(posedge Fin) // Hold value except at edge
    Fout2 = ~Fout2;
endmodule


module DivideBy5(Fout5, Fin);
  //define outputs and inputs
  output reg Fout5;
  input Fin;
  reg [2:0] counter; //because 5 is not a power of 2
  
  //do stuff: chain DFFout to the clock input of FF
  initial begin
    Fout5=0;
    counter='b0;
  end
  
  //we're using behavioral verilog to save some typing
  //see the documentation for a block diagram/conceptual description of the structural equivalent
  always @(posedge Fin) begin // Hold value except at edge
    if (counter == 5) begin
      Fout5 = ~Fout5;
      counter = 'b0;
    end
    
    counter = counter + 'b1;
  end 
  
endmodule

module DivideBy10(Fout10, Fin);
  output Fout10;
  input Fin;
  wire IntermediateF;

  DivideBy5 Div5submodule(IntermediateF, Fin);
  DivideBy2 Div2submodule(Fout10, IntermediateF);
  
endmodule
*/
