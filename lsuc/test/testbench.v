`timescale 1ns/100ps

module testbench;

   reg        clk;
   reg        reset_;
   wire [7:0] led;
   reg  [6:0] switches;
   wire       serdata;
   reg        up_;
   reg        down_;
   reg        left_;
   reg        right_;

   initial clk = 1;
   always #(31.25 / 2) clk = ~clk ;

   initial begin
      $dumpfile("waveform.vcd");
      $dumpvars();
   end

   initial begin
      // Initialize switch and d-pad input
      switches = 7'h55;
      up_ = 1'b1;
      down_ = 1'b1;
      left_ = 1'b1;
      right_ = 1'b1;

      // Reset the chip
      reset_ = 1;
      #10;
      reset_ = 0;
      #110;      
      reset_ = 1;

      // Wait a while and then finish
      #250000;     
      $finish;
  end

   // Press the d-pad left key
   initial begin
      #1000;
      left_ = 1;
      #(31.25 * 500);
      left_ = 0;
   end

   lsuc_top uut (
		 .clk(clk),
		 .reset_(reset_),
		 .led(led),
		 .switches(switches),
		 .segment_(),
		 .digit_enable_(),
		 .up_(up_),
		 .down_(down_),
		 .left_(left_),
		 .right_(right_),
		 .tx(serdata),
		 .rx(serdata)
		 );
   
endmodule
