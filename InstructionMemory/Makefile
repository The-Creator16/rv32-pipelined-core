PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
BLOCK := InstructionMemory
TESTS := InstructionMemory
RTL := $(PROJECT_ROOT)/InstructionMemory/InstructionMemory.sv

include $(PROJECT_ROOT)/mk/simulation.mk

$(OBJ)/InstructionMemory.vvp: $(RTL)

.PHONY: synth
synth:
	cd "$(PROJECT_ROOT)" && $(YOSYS) -Q -p 'read_verilog -sv $(RTL); hierarchy -check -top InstructionMemory; synth -flatten -top InstructionMemory -noabc; check -assert; select -assert-none t:*LATCH*; stat'
