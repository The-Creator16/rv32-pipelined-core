PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
BLOCK := EarlyBranchingAdder
TESTS := EarlyBranchingAdder
RTL := $(PROJECT_ROOT)/EarlyBranchingAdder/EarlyBranchingAdder.sv $(PROJECT_ROOT)/ALU/blocks/CLA4bit.sv

include $(PROJECT_ROOT)/mk/simulation.mk

$(OBJ)/EarlyBranchingAdder.vvp: $(RTL)

.PHONY: synth
synth:
	cd "$(PROJECT_ROOT)" && $(YOSYS) -Q -p 'read_verilog -sv $(RTL); hierarchy -check -top EarlyBranchingAdder; synth -flatten -top EarlyBranchingAdder -noabc; check -assert; select -assert-none t:*LATCH*; stat'
