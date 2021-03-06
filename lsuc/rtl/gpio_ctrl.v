module gpio_ctrl (
   clk,
   reset_,
   leds,
   switches,
   up,
   down,
   left,
   right,
   addr,
   cs,
   req,
   rnw,
   wr_data,
   rd_data,
   rdy
);

   input        clk;
   input        reset_;
   output [7:0] leds;         // 8 LEDs
   input  [6:0] switches;     // 7 toggle switches (eighth is tied to reset_)
   input        up;           // d-pad up
   input        down;         // d-pad down
   input        left;         // d-pad left
   input        right;        // d-pad right

   // This circuit provides general purpose IO control over the switches, LEDs
   // and d-pad inputs. It provides three software-controllable registers,
   // described below:
   //
   // LED control reg (read/write):
   //   [7:0]   Each bit in this register corresponds with an LEDs state. A one
   //           in results in the LED assocaited with the bit position turning
   //           on. For example, 7'b0100_0110 reults in LEDs 1,2 and 6 on; the
   //           rest off.
   //
   // Switch control reg (read only):
   //   [6:0]   Returns the state of each toggle switch (switch seven is
   //           configured as reset).
   //
   // D-Pad control reg (read only);
   //   [7]     A one indicates that up was pressed. Write any value to clear.
   //   [6]     A one indicates that down was pressed. Write any value to clear.
   //   [5]     A one indicates that left was pressed. Write any value to clear.
   //   [4]     A one indicates that right was pressed. Write any value to clear.
   //   [3]     A one indicates that up was released. Write any value to clear.
   //   [2]     A one indicates that down was released. Write any value to clear.
   //   [1]     A one indicates that left was released. Write any value to clear.
   //   [0]     A one indicates that right was released. Write any value to clear.

   // Local IO bus
   input  [7:0] addr;       // CPU address
   input        cs;         // Chip select (when high, request is for this module)
   input        req;        // CPU request
   inout        rnw;        // Request is a read, not write.
   input  [7:0] wr_data;    // Write data from CPU
   output [7:0] rd_data;    // Read data from this module to CPU
   output       rdy;        // Ready (request is complete)

   reg [7:0]    dpads;
   reg [7:0]    leds;
   reg          rdy;
   reg [7:0]    rd_data;

   wire    up_debounced;
   wire    down_debounced;
   wire    left_debounced;
   wire    right_debounced;

   wire    wr_enable;
   wire    rd_enable;
   wire    up_released;
   wire    down_released;
   wire    left_released;
   wire    right_released;
   wire    up_pressed;
   wire    down_pressed;
   wire    left_pressed;
   wire    right_pressed;

   reg [1:0]    up_shift;
   reg [1:0]    down_shift;
   reg [1:0]    left_shift;
   reg [1:0]    right_shift;

   // Software addressable registers
   parameter LED_CTRL_REG    = 8'd0;
   parameter SWITCH_CTRL_REG = 8'd1;
   parameter DPAD_CTRL_REG   = 8'd2;

   assign wr_enable = cs && !rnw && req;
   assign rd_enable = cs && rnw && req;

   // Press/release event indications
   assign left_released  = left_shift == 2'b10;
   assign right_released = right_shift == 2'b10;
   assign up_released    = up_shift == 2'b10;
   assign down_released  = down_shift == 2'b10;
   assign left_pressed   = left_shift == 2'b01;
   assign right_pressed  = right_shift == 2'b01;
   assign up_pressed     = up_shift == 2'b01;
   assign down_pressed   = down_shift == 2'b01;

   // LED control register write
   always@ (posedge clk or negedge reset_)
     if (!reset_)
       leds <= 8'h00;
     else if (addr == LED_CTRL_REG && wr_enable)
       leds <= wr_data[7:0];

   // Directional pad event register
   always@ (posedge clk or negedge reset_)
     if (!reset_)
       dpads <= 8'd0;
     else if (wr_enable && addr == DPAD_CTRL_REG)
       dpads <= 8'd0;
     else
       dpads <= {dpads[7] || up_pressed,
                 dpads[6] || down_pressed,
                 dpads[5] || left_pressed,
                 dpads[4] || right_pressed,
                 dpads[3] || up_released,
                 dpads[2] || down_released,
                 dpads[1] || left_released,
                 dpads[0] || right_released};

   // Register readback
   always@ (posedge clk or negedge reset_)
     if (!reset_)
       rd_data <= 8'h00;
     else if (addr == LED_CTRL_REG && rd_enable)
       rd_data <= leds;
     else if (addr == SWITCH_CTRL_REG && rd_enable)
       rd_data <= {switches[6:0], 1'b0};
     else if (addr == DPAD_CTRL_REG && rd_enable)
       rd_data <= dpads;

   // Module ready generation
   always@ (posedge clk or negedge reset_)
     if (!reset_)
       rdy <= 1'b0;
     else
       rdy <= req;

   // Debounced up key shift register (to capture press/release events)
   always@ (posedge clk or negedge reset_)
     if (!reset_)
       up_shift <= 2'd0;
     else
       up_shift <= {up_shift[0], up_debounced};

   // Debounced down key shift register (to capture press/release events)
   always@ (posedge clk or negedge reset_)
     if (!reset_)
       down_shift <= 2'd0;
     else
       down_shift <= {down_shift[0], down_debounced};

   // Debounced left key shift register (to capture press/release events)
   always@ (posedge clk or negedge reset_)
     if (!reset_)
       left_shift <= 2'd0;
     else
       left_shift <= {left_shift[0], left_debounced};

   // Debounced right key shift register (to capture press/release events)
   always@ (posedge clk or negedge reset_)
     if (!reset_)
       right_shift <= 2'd0;
     else
       right_shift <= {right_shift[0], right_debounced};

   // D-pad key debouncer instantions
   debouncer up_debouncer (
     .clk(clk),
     .reset_(reset_),
     .raw(up),
     .debounced(up_debounced)
   );

   debouncer down_debouncer (
     .clk(clk),
     .reset_(reset_),
     .raw(down),
     .debounced(down_debounced)
   );

   debouncer left_debouncer (
     .clk(clk),
     .reset_(reset_),
     .raw(left),
     .debounced(left_debounced)
   );

   debouncer right_debouncer (
     .clk(clk),
     .reset_(reset_),
     .raw(right),
     .debounced(right_debounced)
   );

endmodule
