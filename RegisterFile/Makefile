PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
BLOCK := RegisterFile
TESTS := RegFile32bit
RTL := $(PROJECT_ROOT)/RegisterFile/RegFile32bit.sv

RANDOM_TESTS ?= 1000

include $(PROJECT_ROOT)/mk/simulation.mk

$(OBJ)/RegFile32bit.vvp: $(RTL)

.PHONY: synth
synth:
	$(YOSYS) -Q -p 'read_verilog -sv $(RTL); hierarchy -check -top RegFile32bit; synth -flatten -top RegFile32bit -noabc; check -assert; select -assert-none t:*LATCH*; stat'
