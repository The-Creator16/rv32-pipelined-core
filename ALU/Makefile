PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
BLOCK := ALU
TESTS := ALU32bit CLA32bit CLA4bit SLL32bit SRL_SRA32bit OverflowDetector
BLOCKS := $(PROJECT_ROOT)/ALU/blocks
ALU_RTL := $(PROJECT_ROOT)/ALU/ALU32bit.sv $(wildcard $(BLOCKS)/*.sv)

include $(PROJECT_ROOT)/mk/simulation.mk

$(OBJ)/ALU32bit.vvp: $(ALU_RTL)
$(OBJ)/CLA32bit.vvp: $(BLOCKS)/CLA4bit.sv
BLOCK_OBJECTS := $(addprefix $(OBJ)/,$(addsuffix .vvp,$(filter-out ALU32bit,$(TESTS))))
$(BLOCK_OBJECTS): $(OBJ)/%.vvp: $(BLOCKS)/%.sv

.PHONY: synth
synth:
	$(YOSYS) -Q -p 'read_verilog -sv $(ALU_RTL); hierarchy -check -top ALU32bit; synth -flatten -top ALU32bit -noabc; check -assert; select -assert-none t:*DFF* t:*LATCH*; stat'
