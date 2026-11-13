PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
BLOCK := InstructionAdder
TESTS := InstructionAdder
RTL := $(PROJECT_ROOT)/InstructionAdder/InstructionAdder.sv

RANDOM_TESTS ?= 100000

include $(PROJECT_ROOT)/mk/simulation.mk

$(OBJ)/InstructionAdder.vvp: $(RTL)

.PHONY: synth
synth:
	cd "$(PROJECT_ROOT)" && $(YOSYS) -Q -p 'read_verilog -sv $(RTL); hierarchy -check -top InstructionAdder; synth -flatten -top InstructionAdder -noabc; check -assert; select -assert-none t:*LATCH*; stat'
