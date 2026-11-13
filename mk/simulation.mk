# Shared simulation rules. Each block supplies BLOCK, TESTS and RTL dependencies.
.DEFAULT_GOAL := test
.DELETE_ON_ERROR:

IVERILOG ?= iverilog
VVP ?= vvp
YOSYS ?= yosys
IVFLAGS ?= -g2012 -Wall
RANDOM_TESTS ?= 200000
WAVE_TESTS ?= 16

OBJ := $(PROJECT_ROOT)/build/obj/$(BLOCK)
VCD := $(PROJECT_ROOT)/build/vcd/$(BLOCK)

.PHONY: all build test wave clean help $(addprefix test-,$(TESTS)) $(addprefix wave-,$(TESTS))

all: test
build: $(addprefix $(OBJ)/,$(addsuffix .vvp,$(TESTS)))
test: $(addprefix test-,$(TESTS))
wave: $(addprefix wave-,$(TESTS))

$(OBJ)/%.vvp: $(PROJECT_ROOT)/$(BLOCK)/tb/%_tb.sv $(MAKEFILE_LIST) | $(OBJ)
	$(IVERILOG) $(IVFLAGS) -s tb_$* -o $@ $(filter %.sv,$^)

$(addprefix test-,$(TESTS)): test-%: $(OBJ)/%.vvp
	cd "$(PROJECT_ROOT)" && $(VVP) $< +random_tests=$(RANDOM_TESTS)

$(addprefix wave-,$(TESTS)): wave-%: $(OBJ)/%.vvp | $(VCD)
	cd "$(PROJECT_ROOT)" && $(VVP) $< +waves +random_tests=$(WAVE_TESTS)

$(OBJ) $(VCD):
	mkdir -p $@

clean:
	$(RM) -r "$(OBJ)" "$(VCD)"

help:
	@echo 'make build | test | wave | test-MODULE | wave-MODULE | synth | clean'
	@echo 'Modules: $(TESTS)'
	@echo 'Random iterations: RANDOM_TESTS=$(RANDOM_TESTS) (randomized tests), WAVE_TESTS=$(WAVE_TESTS) (wave)'
