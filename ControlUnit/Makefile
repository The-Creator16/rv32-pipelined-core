PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
BLOCK := ControlUnit
TESTS := CU32bit
RTL := $(PROJECT_ROOT)/ControlUnit/CU32bit.sv

include $(PROJECT_ROOT)/mk/simulation.mk

$(OBJ)/CU32bit.vvp: $(RTL)

.PHONY: synth
synth:
	cd "$(PROJECT_ROOT)" && $(YOSYS) -Q -p 'read_verilog -sv $(RTL); hierarchy -check -top CU32bit; synth -flatten -top CU32bit -noabc; check -assert; select -assert-none t:*LATCH*; stat'
