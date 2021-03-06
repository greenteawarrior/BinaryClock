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

/*
OutputTwoHzSignal

This module outputs a Two Hz signal when given a 50 M Hz clock signal as an input. The reason
that we want a 2 Hz signal and not a 1 Hz signal is that there is 1 2X frequency divder in our 
clock code. This would be implemented using 8 5X frequency divders, and 6 2X frequency dividers. 
The 5X frequency divider is made out of two registers, one is a counter that increments on each
positive edge of the clock. When the counter equals 4, the counter resets on the next positive 
clock edge. The other register contains the ouput signal. Each time the counter resets, the 
output is inverted. Unfortuantely, becuase the FPGA does not like coded flip flops, we can't 
implement the frequency divider that way. Instead, we've created one giant 25 * 10^6 X frequency 
diveder, and the ouput signal resets every time the counter = 25 * 10^6 - 1. 

OUTPUTS:
Fout:   1 bit   The output frequency. A 2Hz signal.  

INPUTS: 
CLK_50M: 1 bit  The input clock signal. On our FPGA this is 50MHz
*/
module OutputTwoHzSignal(Fout, CLK_50M);
  //Declare inputs and outputs
  input CLK_50M;            
  output reg Fout;
  
  //Intermediate Variables
  reg [26:0] counter;

  //Set the counter to 0, if we are just starting
  initial begin
    counter='b0;
  end
  //Increment the counter
  always @(posedge CLK_50M) begin
    counter <= counter+1;
    
    //Reset the counter and flip output signal                           
    if (counter == 'b10111110101111000000111111) begin 
    Fout = ~Fout;
    counter <= 'b0;
    end 
  end
  
endmodule 


//All the code from BinaryClock onwards was written entirely by Emily and Sophia

/*
BinaryClock

This is the module where we knit everything together in our clock. This module is done
predominantly  in structural verilog. The only behavioral verilog comes with assigning 
the outputs. This would be done using a flip-flop acting as a register in structural.
We also use behavioral verilog to check which, if any buttons are pressed. If we
implemented this in structural verilog, we would use an XNOR gate with all of the outputs
anded together, much like we've done for the five and 6 bit XNORS. For calculating the new
hours, minutes, and seconds, we increment seconds, check if the old seconds value was equal
to 59, and reset the seconds if it was. The same is true for minute and hours, except for
hours we check if hours = 23, not 59. For hours and minutes, we also only reset back to zero
if minutes = 59 or hours = 23 AND we should be incrementing minutes or hours.

OUTPUTS:
SetTime:  6 bits  The value that the clock will be set to. Displayed on the LEDs above the switches on the FPGA
Hours:    5 bits  The hours of the time
Minutes:  6 bits  The minutes of the time
Seconds:  6 bits  The seconds of the time

INPUTS: 
Buttons:  3 bits  The value of the buttons used to set hours and minutes and reset seconds on the FPGA
Switches: 6 bits  The value of the six switches used to set hours and minutes on the FPGA
clk:      1 bit   The 50 MHz clock signal from the FPGA
*/
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
  
  //generate two hz singal
  OutputTwoHzSignal GeneratingTwoHzSignal (TwoHzSignal, clk);
  
  //update on the two hz signal, not the clock
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

// output the time that you're going to be setting the clock to
assign SetTime = Switches;
endmodule



/*
SixBitIncrement

This is for incrementing the minutes and seconds. This module takes in a 6bit number and increments that 
number if Cin = 1. Otherwise, it returns the same 6-bit number. We've done this in behavioral verilog to 
save some typing, but if we wanted to implement this in structural verilog, we would use 6, 1-bit adders 
chained together by their carry bits. The reason that we do not have a B input or a carry out output is 
that B is always zero, and we won't ever have to carry anythinig out because our highest number for the 
adder to ever compute is 60.

OUTPUTS:
SBIOut:   6 bits  The incremented A value

INPUTS: 
A:        6 bits  The value that we are incrementing
Cin:      1 bit   Whether we are incrementing or not. 
*/
module SixBitIncrement(SBIOut, A, Cin);
  //defining outputs and inputs
  output reg [5:0] SBIOut;
  input [5:0] A;
  input Cin;

  //le add
  always @ *
    SBIOut = A + Cin;
endmodule


/*
FiveBitIncrement

This is for incrementing the hours register. This module takes in a 5 bit number and increments that 
number if Cin = 1. Otherwise, it returns the same 6-bit number. We've done this in behavioral verilog to 
save some typing, but if we wanted to implement this in structural verilog, we would use 5, 1-bit adders 
chained together by their carry bits. The reason that we do not have a B input or a carry out output is 
that B is always zero, and we won't ever have to carry anythinig out because our highest number for the 
adder to ever compute is 24.

OUTPUTS:
FBIOut:   5 bits  The incremented A value

INPUTS: 
A:        5 bits  The value that we are incrementing
Cin:      1 bit   Whether we are incrementing or not. 
*/
module FiveBitIncrement(FBIOut, A, Cin);
  //defining outputs and inputs
  output reg [4:0] FBIOut;
  input [4:0] A;
  input Cin;

  //le add
  always @ *
    FBIOut = A + Cin;
endmodule


/*
SixBitMux

This is for deciding what value to assign to mintues and seconds. We either set 
the new value to the incremented value or whether to reset to zero. Therefore,
we only have one input into our mux. We've done this bit in behavioral verilog 
to save some typing, but this is just a simple mux , and could be implemented
using two and gates, one or gate, and one not gate. 

OUTPUTS:
SBMOut:   6 bits  The value we'll be setting minutes or seconds to

INPUTS: 
A:        6 bits  The value that we are incrementing
Select:   1 bit   Whether we are resetting or not. 
*/
module SixBitMux(SBMOut, A, Select);
  //defining ouputs and inputs
  output reg [5:0] SBMOut;
  input [5:0] A; //signal A

  input Select;
  
  //Muxing
  always @ * begin
    if (Select == 0) begin
      SBMOut = A;
    end else if (Select == 1) begin
      SBMOut = 'b0;
    end
  end
endmodule


/*
FiveBitMux

This is for deciding what value to assign to hours register. We either set 
the new value to the incremented value or whether to reset to zero. Therefore,
we only have one input into our mux. We've done this bit in behavioral verilog 
to save some typing, but this is just a simple mux , and could be implemented
using two and gates, one or gate, and one not gate. 

OUTPUTS:
FBMOut:   5 bits  The value we'll be setting hours to

INPUTS: 
A:        5 bits  The value that we are incrementing
Select:   1 bit   Whether we are resetting or not. 
*/

module FiveBitMux(FBMOut, A, Select);
  //defining outputs and inputs
  output reg [4:0] FBMOut;
  input [4:0] A; //signal A
  input Select;

  //Muxing
  always @ * begin
    if (Select == 0) begin
      FBMOut = A;
    end else if (Select == 1) begin
      FBMOut = 'b0;
    end
  end
endmodule


/*
SixBitXNOR

This module is for seconds and minutes. It takes in two inputs, and returns 1 if the 
two inputs are equal and 0 if they are not. we've done this in behavioral verilog 
to save some typing, but this would be implemented in structural verilog with taking
the bit-wise XNOR of A and B and then feeding each of those bits into a 6-input AND
gate and returning the output of that and gate.
OUTPUTS:
SBXNOROut:  1 bit  Does A==B?

INPUTS: 
A:          6 bits  Value 1 (Comparing this value to Value 2)
B:          6 bit   Value 2 (Comparint this value to Value 1) 
*/
module SixBitXNOR(SBXNOROut, A, B);
  //defining outputs and inputs
  output reg SBXNOROut; //gotta be one bit
  input [5:0] A;
  input [5:0] B;

  //behavioral to save typing
  always @ * begin
    SBXNOROut = ~(A[0]^B[0]) & ~(A[1]^B[1]) & ~(A[2]^B[2]) & ~(A[3]^B[3]) & ~(A[4]^B[4]) & ~(A[5]^B[5]);  
  end
endmodule


/*
FiveBitXNOR

This module is for hours. It takes in two inputs, and returns 1 if the two inputs are 
equal and 0 if they are not. we've done this in behavioral verilog to save some typing, 
but this would be implemented in structural verilog with taking the bit-wise XNOR of A 
and B and then feeding each of those bits into a 5-input AND gate and returning the
output of that and gate.
OUTPUTS:
SBXNOROut:  1 bit  Does A==B?

INPUTS: 
A:          5 bits  Value 1 (Comparing this value to Value 2)
B:          5 bit   Value 2 (Comparint this value to Value 1) 
*/

module FiveBitXNOR(FBXNOROut, A, B);
  //defining outputs and inputs
  output reg FBXNOROut; //gotta be one bit
  input [4:0] A;
  input [4:0] B;

  //behavioral to save typing
  always @ * begin
    FBXNOROut = ~(A[0]^B[0]) & ~(A[1]^B[1]) & ~(A[2]^B[2]) & ~(A[3]^B[3]) & ~(A[4]^B[4]);  
  end
endmodule
