PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
BLOCK := ImmediateGenerator
TESTS := ImmediateGenerator
RTL := $(PROJECT_ROOT)/ImmediateGenerator/ImmediateGenerator.sv

RANDOM_TESTS ?= 10000

include $(PROJECT_ROOT)/mk/simulation.mk

$(OBJ)/ImmediateGenerator.vvp: $(RTL)

.PHONY: synth
synth:
	cd "$(PROJECT_ROOT)" && $(YOSYS) -Q -p 'read_verilog -sv $(RTL); hierarchy -check -top ImmediateGenerator; synth -flatten -top ImmediateGenerator -noabc; check -assert; select -assert-none t:*LATCH*; stat'
