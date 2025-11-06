# -----------------------------------------------
# QuestaSim/ModelSim DO file to compile and run
# MultiInputAdderWithRounding testbench
# -----------------------------------------------

# 1. Create work library
vlib work
vmap work work

# 2. Compile design files
vlog ../utils/numbers/MultiInputAdder.sv
vlog ../utils/numbers/UnbiasedRounding.sv
vlog ../utils/numbers/MultiInputAdderWithRounding.sv
vlog ./tb_MultiInputAdderWithRounding.sv

# 3. Load testbench
vsim tb_MultiInputAdderWithRounding -voptargs="+acc"

# 4. Open waveform window
add wave *

# 5. Run simulation (adjust time as needed)
run 200ns

# 6. End simulation (optional)
quit
