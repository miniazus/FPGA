**A One-Shot Pulse Generator / Startup Sequencer:** PulseSignal.sv

  This module waits for a specified number of clock cycles ('DELAY')
  after reset is released, then asserts the output 'dout'.
  It is commonly used to sequence the startup of multiple modules
  (e.g., turn on Block A, wait 10 cycles, turn on Block B).

​	* RZ: Return-To-Zero Mode: When (delay) to return to 0?



**Delay Line:** DelayLine.sv

  A universal, parameterizable signal delay block implementing
  a z^-n transfer function.
