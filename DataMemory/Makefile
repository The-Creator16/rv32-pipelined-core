PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
BLOCK := DataMemory
TESTS := DataMemory
RTL := $(PROJECT_ROOT)/DataMemory/DataMemory.sv

include $(PROJECT_ROOT)/mk/simulation.mk

$(OBJ)/DataMemory.vvp: $(RTL)

.PHONY: synth
synth:
	cd "$(PROJECT_ROOT)" && $(YOSYS) -Q -p 'read_verilog -sv $(RTL); hierarchy -check -top DataMemory; synth -flatten -top DataMemory -noabc; check -assert; select -assert-none t:*LATCH*; stat'
