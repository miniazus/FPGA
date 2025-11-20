Unbiased Rounding: UnbiasedRounding.sv
  Performs unbiased rounding (round-half-to-even) for fixed-point 
  numbers. The module truncates the lower bits of the input, applies 
  rounding based on the truncated portion, and saturates the output 
  if rounding causes overflow. Supports both signed and unsigned 
  inputs, and handles fractional or integer rounding modes.

Multi Input Adder: MultiInputAdder.sv
  This module performs the summation of multiple input values 
  using a balanced binary adder tree.  Key capabilities: Pipelining: 
  The module automatically inserts pipeline  registers between adder
  stages to meet a target latency (OUTPUT_DELAY).

