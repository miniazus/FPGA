Unbiased Rounding: UnbiasedRounding.sv
  Performs unbiased rounding (round-half-to-even) for fixed-point 
  numbers. The module truncates the lower bits of the input, applies 
  rounding based on the truncated portion, and saturates the output 
  if rounding causes overflow. Supports both signed and unsigned 
  inputs, and handles fractional or integer rounding modes.

Multi Input Adder: MultiInputAdder.sv
  This module performs signed addition of multiple input values. The number of inputs is parameterizable. 
  The output width is automatically extended by $clog2(NUM_INPUT) bits to prevent  overflow. 
  Designed for use in arithmetic datapaths or DSP pipelines where accumulation of several fixed-point signals is required.

