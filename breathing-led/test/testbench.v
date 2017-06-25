// Directive indicates that 1ns is the time period used when specifying delays
// (i.e., #10 means 10ns); 100ps is the smallest unit of time precision that
// will be simulated (100ps = .1ns; thus #.1 is meaningful, #.00001 is equivalent
// to #0)
`timescale 1ns / 100ps

module testbench ();

   reg clk;
   reg reset_;
   wire [7:0] led;

   // Create an instance of the circuit under test
   breathingled breathingled_0 (
				.clk(clk),
				.reset_(reset_),
				.led(led)
				);

   // Initialize the clock signal to zero; drive reset_ active (low) for the
   // first 100ns of the simulation.
   initial begin
      clk = 1'b0;
      reset_ = 1'b0;
      #100 reset_ = 1'b1;
   end

   // Stop the simulation after 400ms; note that simulations can run indefinitely
   // (with waveforms loaded incrementally in the viewer.) Press ctrl-c to break
   // iverilog, then enter '$finish' to stop the simulation.
   initial begin
      #400000000 $finish;   // 400ms
   end

   // Toggle the clock every 31.25ns (32 MHz frequency)
   initial begin forever
     #31.25 clk = ~clk;
   end

   // Produce a waveform output of this simulation
   initial begin
      $dumpfile("waveform.vcd");
      $dumpvars();
   end

endmodule
