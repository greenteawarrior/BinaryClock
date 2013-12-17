`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Olin College of Engineering, Computer Architecture
// Engineer: Emily Wang and Sophia Seitz
// 
// Create Date:    00:12:57 12/15/2013 
// Design Name: 
// Module Name:    BinaryClock
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


//Original code for specifically OutputTwoHzSignal 
//from http://www.electro-tech-online.com/threads/fpga-led-help-w-verilog.106139/ forum post 
//was modified for our specific purposes
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


//All the code from BinaryClock onwards was written entirely by Emily and Sophia
module BinaryClock(SetTime, Hours, Minutes, Seconds, Buttons, Switches, clk); 
  //insert frequency divider and set/enable shenanigans
  
  //defining outputs and inputs
  output [5:0] SetTime;
  output reg [4:0] Hours;
  output reg [5:0] Minutes;  
  output reg [5:0] Seconds;
  input [2:0] Buttons;
  input [5:0] Switches;
  input clk;


  //some intermediate stuff
  wire TwoHzSignal;
  wire [4:0] IncrementedHours;
  wire [4:0] NewHours;
  wire HoursEqualTwentyThree;
  wire [5:0] IncrementedMinutes;
  wire [5:0] NewMinutes;
  wire MinutesEqualFiftyNine;
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
  SixBitXNOR MinutesXNOR (MinutesEqualFiftyNine, Minutes, FiftyNine);
  and ResetMinutesAnd(ResetMinutes,MinutesEqualFiftyNine, ResetSeconds);
  SixBitMux MinutesMux (NewMinutes, IncrementedMinutes, ResetMinutes);

  //hours shenanigans
  FiveBitIncrement HoursFBI (IncrementedHours, Hours, ResetMinutes);
  FiveBitXNOR HoursXNOR (HoursEqualTwentyThree, Hours, TwentyThree);
  and ResetHoursAnd(ResetHours, HoursEqualTwentyThree, ResetMinutes);
  FiveBitMux HoursMux (NewHours, IncrementedHours, ResetHours);
  
  OutputTwoHzSignal GeneratingTwoHzSignal (TwoHzSignal, clk);
  
  always @ (posedge TwoHzSignal) begin
    Seconds <= NewSeconds;
    Minutes <= NewMinutes;
    Hours <= NewHours;
    
    //reset the seconds by pressing a button!              
    if (Buttons[0] == 1) begin
      Seconds <= 'b0;
    end
  
    //setting the minutes with the pull switches and a certain button press!
    if (Buttons[1] == 1) begin
      Minutes <= Switches;
    end
  
    //setting the hours with the pull switches and a certain button press!
    if (Buttons[2] == 1) begin
      Hours <= Switches;
    end
  end

assign SetTime = Switches;
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
