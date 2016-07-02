BinaryClock
===========

[Computer Architecture - Fall 2013 Olin College] Creating a clock that tells the time in binary with Verilog, a Spartan 3 FPGA, and pretty lights. ;D

Files in this repository:
* .gitignore (self explanatory)
* BinaryClock.v (contains all of the necessary verilog modules for the binary clock)
* BinaryClockConstraints.ucf (a file which helps map inputs/outputs in the code to the hardware locations on the Spartan 3 FPGA - necessary for working with Xilinx ISE webpack)

Additional instructions:
* For simplicity (and because of file nuances Xilinx's program creates that can't be shown in the repository), 
this respository only contains the verilog modules and the configurations file).
* To use this code in Xilinx for the first time, create a new project in Xilinx ISE Webpack, and add the 
appropriate code files in the approriate categories by either the "add source" button (if it works) or copying/pasting the contents. BinaryClock should be the top module.
