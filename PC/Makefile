PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
BLOCK := PC
TESTS := PC32bit
PC_RTL := $(PROJECT_ROOT)/PC/PC32bit.sv

include $(PROJECT_ROOT)/mk/simulation.mk

$(OBJ)/PC32bit.vvp: $(PC_RTL)

.PHONY: synth
synth:
	$(YOSYS) -Q -p 'read_verilog -sv $(PC_RTL); hierarchy -check -top PC32bit; synth -flatten -top PC32bit -noabc; check -assert; select -assert-none t:*LATCH*; stat'
