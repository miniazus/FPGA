# -----------------------------------------------
# QuestaSim/ModelSim DO file to compile and run
# UnbiasedRounding testbench
# -----------------------------------------------

# 1. Create work library
vlib work
vmap work work

# 2. Compile design files
vlog ../utils/numbers/UnbiasedRounding.sv
vlog ./tb_UnbiasedRounding.sv

# 3. Load testbench
vsim tb_UnbiasedRounding -voptargs="+acc"

# 4. Open waveform window
add wave *

# 5. Run simulation (adjust time as needed)
run -all

# 6. End simulation (optional)
# quit
