module konamiacceptor (
  clk,
  reset_,

  up_,
  down_,
  left_,
  right_,

  segment_,
  digit_enable_
  );

  input clk;
  input reset_;
  input up_;
  input down_;
  input left_;
  input right_;

  output [6:0] segment_;
  output [3:0] digit_enable_;

  // Konami code acceptor states
  parameter START   = 4'd0;     // Initial state; waiting for first input
  parameter UP_1    = 4'd1;     // User pressed (and released) d-pad up
  parameter UP_2    = 4'd2;
  parameter DOWN_1  = 4'd3;
  parameter DOWN_2  = 4'd4;
  parameter LEFT_1  = 4'd5;
  parameter RIGHT_1 = 4'd6;
  parameter LEFT_2  = 4'd7;
  parameter ACCEPT  = 4'd9;     // Input sequence accepted; user gets 40 lives
  parameter REJECT  = 4'd10;    // Input sequence rejected; user gets 3 lives

  reg [3:0]  state;             // FSM state value (one of the above values)
  reg [24:0] timeout_ctr;       // If no input for a while, then we REJECT
  reg [1:0]  down_shift;        // Down key shift register to capture key-press events
  reg [1:0]  up_shift;
  reg [1:0]  left_shift;
  reg [1:0]  right_shift;

  wire       down_debounced;    // Debounced d-pad down
  wire       up_debounced;      // Debounced d-pad up
  wire       left_debounced;    // Debounced d-pad left
  wire       right_debounced;   // Debounced d-pad right

  wire [6:0] digit_0;           // 7-segment digit values
  wire [6:0] digit_1;
  wire [6:0] digit_2;
  wire [6:0] digit_3;

  assign timeout        = &timeout_ctr;   // Same as timeout_ctr == 8'hff_ffff

  // Key-up event when key was down (1) now is up (0)
  assign down_released  = down_shift == 2'b10;
  assign up_released    = up_shift == 2'b10;
  assign left_released  = left_shift == 2'b10;
  assign right_released = right_shift == 2'b10;

  // Debouncers for d-pad inputs (prevents microscopic changes to key values
  // from causing errors--see notes)
  debouncer down_debouncer(
    .clk(clk),
    .reset_(reset_),
    .raw(~down_),
    .debounced(down_debounced)
  );

  debouncer up_debouncer(
    .clk(clk),
    .reset_(reset_),
    .raw(~up_),
    .debounced(up_debounced)
  );

  debouncer left_debouncer(
    .clk(clk),
    .reset_(reset_),
    .raw(~left_),
    .debounced(left_debounced)
  );

  debouncer right_debouncer(
    .clk(clk),
    .reset_(reset_),
    .raw(~right_),
    .debounced(right_debounced)
  );

  // Digit coder converts state to a 7-segment displayed value
  konamicoder coder (
    .digit_0(digit_3),
    .digit_1(digit_2),
    .digit_2(digit_1),
    .digit_3(digit_0),
    .state(state)
  );

  // Drives the seven segment display with digit values (see notes)
  displaydriver display (
    .clk(clk),
    .reset_(reset_),
    .digit_0(digit_0),
    .digit_1(digit_1),
    .digit_2(digit_2),
    .digit_3(digit_3),
    .segment_(segment_),
    .digit_enable_(digit_enable_)
  );

  // Timeout counter generation; REJECT on timout
  always@ (posedge clk or negedge reset_)
    if (!reset_)
      timeout_ctr <= 25'd0;
    else if (up_released || down_released || left_released || right_released)
      timeout_ctr <= 25'd0;
    else
      timeout_ctr <= timeout_ctr + 25'd1;

  // Down key shift register (for key press event generation)
  always@ (posedge clk or negedge reset_)
    if (!reset_)
      down_shift <= 2'd0;
    else
      down_shift <= {down_shift[0], down_debounced};

  // Up key shift register (for key press event generation)
  always@ (posedge clk or negedge reset_)
    if (!reset_)
      up_shift <= 2'd0;
    else
      up_shift <= {up_shift[0], up_debounced};

  // Left key shift register (for key press event generation)
  always@ (posedge clk or negedge reset_)
    if (!reset_)
      left_shift <= 2'd0;
    else
      left_shift <= {left_shift[0], left_debounced};

  // Right key shift register (for key press event generation)
  always@ (posedge clk or negedge reset_)
    if (!reset_)
      right_shift <= 2'd0;
    else
      right_shift <= {right_shift[0], right_debounced};

  // State transition register
  always@ (posedge clk or negedge reset_)
    if (!reset_)
      state <= START;

    // Initial state; wait for user to press UP
    else if (state == START && up_released)
      state <= UP_1;

    // Up pressed once; wait for user to press up again
    else if (state == UP_1 && up_released)
      state <= UP_2;
    else if (state == UP_1 && (timeout || down_released || left_released || right_released))
      state <= REJECT;

    // Up pressed twice; wait for user to press down
    else if (state == UP_2 && down_released)
      state <= DOWN_1;
    else if (state == UP_2 && (timeout || up_released || left_released || right_released))
      state <= REJECT;

    // Down pressed once; wait for user to press down again
    else if (state == DOWN_1 && down_released)
      state <= DOWN_2;
    else if (state == DOWN_1 && (timeout || up_released || left_released || right_released))
      state <= REJECT;

    // Down pressed twice; wait for user to press left
    else if (state == DOWN_2 && left_released)
      state <= LEFT_1;
    else if (state == DOWN_2 && (timeout || up_released || down_released || right_released))
      state <= REJECT;

    // Left pressed once; wait for user to press right
    else if (state == LEFT_1 && right_released)
      state <= RIGHT_1;
    else if (state == LEFT_1 && (timeout || left_released || up_released || down_released))
      state <= REJECT;

    // Right pressed once; wait for user to press left
    else if (state == RIGHT_1 && left_released)
      state <= LEFT_2;
    else if (state == RIGHT_1 && (timeout || up_released || down_released || right_released))
      state <= REJECT;

    // Left pressed again; wait for user to press right again
    else if (state == LEFT_2 && right_released)
      state <= ACCEPT;
    else if (state == LEFT_2 && (timeout || up_released || down_released || left_released))
      state <= REJECT;

    // In the ACCEPT or REJECT state; wait for user to press any direction, then return to start
    else if ((state == ACCEPT || state == REJECT) && (up_released || down_released || left_released || right_released))
      state <= START;

endmodule
