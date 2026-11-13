PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
BLOCK := CPU
TESTS := CPU32bit
RTL := $(PROJECT_ROOT)/CPU/CPU32bit.sv $(wildcard $(PROJECT_ROOT)/ALU/blocks/*.sv) \
       $(PROJECT_ROOT)/ALU/ALU32bit.sv \
       $(PROJECT_ROOT)/ControlUnit/CU32bit.sv \
       $(PROJECT_ROOT)/DataMemory/DataMemory.sv \
       $(PROJECT_ROOT)/EarlyBranchingAdder/EarlyBranchingAdder.sv \
       $(PROJECT_ROOT)/ImmediateGenerator/ImmediateGenerator.sv \
       $(PROJECT_ROOT)/InstructionAdder/InstructionAdder.sv \
       $(PROJECT_ROOT)/InstructionMemory/InstructionMemory.sv \
       $(PROJECT_ROOT)/PC/PC32bit.sv \
       $(PROJECT_ROOT)/RegisterFile/RegFile32bit.sv

include $(PROJECT_ROOT)/mk/simulation.mk

$(OBJ)/CPU32bit.vvp: $(RTL)

.PHONY: synth
synth:
	cd "$(PROJECT_ROOT)" && $(YOSYS) -Q -p 'read_verilog -sv $(RTL); hierarchy -check -top CPU32bit; proc; memory_collect; opt_clean; check -assert; select -assert-none t:*LATCH*; stat'
