**Unbiased Rounding:** UnbiasedRounding.sv

  Performs unbiased rounding (round-half-to-even) for fixed-point 
  numbers. The module truncates the lower bits of the input, applies 
  rounding based on the truncated portion, and saturates the output 
  if rounding causes overflow. Supports both signed and unsigned 
  inputs, and handles fractional or integer rounding modes.

​	* Fixed input din's precision.



**Unbiased Rounding with Input Precision setting:** UnbiasedRounding_wCurrentPrecision.sv

  Performs unbiased rounding (round-half-to-even) for fixed-point 
  numbers. The module truncates the lower bits of the input, applies 
  rounding based on the truncated portion, and saturates the output 
  if rounding causes overflow. Supports both signed and unsigned 
  inputs, and handles fractional or integer rounding modes.

​	* dynamic din's precision : The actual valid bit-width of the current 'din'.



**Multi Input Adder:** MultiInputAdder.sv

  This module performs the summation of multiple input values 
  using a balanced binary adder tree.  Key capabilities: Pipelining: 
  The module automatically inserts pipeline  registers between adder
  stages to meet a target latency (OUTPUT_DELAY).

​	* NO bitmask to control participation in the sum.



**MultiInputAdder with Input Enable setting:** MultiInputAdder_wInputEnable.sv

  This module performs the summation of multiple input values 
  using a balanced binary adder tree.  Key capabilities: Pipelining: 
  The module automatically inserts pipeline  registers between adder
  stages to meet a target latency (OUTPUT_DELAY).

​	* WITH bitmask to control participation in the sum.
