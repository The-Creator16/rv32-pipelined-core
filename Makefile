.DEFAULT_GOAL := test
BLOCKS := ControlUnit CPU ALU PC RegisterFile InstructionMemory InstructionAdder EarlyBranchingAdder ImmediateGenerator DataMemory
ACTIONS := build test wave synth clean
.PHONY: all $(ACTIONS) help
all: test

build: $(addprefix build-,$(BLOCKS))
	@echo
	@echo "PASS: all simulation programs compiled successfully"

test: $(addprefix test-,$(BLOCKS))
	@echo
	@echo "PASS: all block and CPU tests completed successfully"

wave: $(addprefix wave-,$(BLOCKS))
	@echo
	@echo "PASS: all waveform tests completed successfully"
	@echo "Waveforms saved in build/vcd/"

synth: $(addprefix synth-,$(BLOCKS))
	@echo
	@echo "PASS: all component synthesis and CPU structural checks completed successfully"

.PHONY: $(addsuffix -ALU,$(ACTIONS))
$(addsuffix -ALU,$(ACTIONS)): %-ALU:
	$(MAKE) -C ALU $*

.PHONY: test-OverflowDetector test-SRL_SRA32bit test-CLA32bit test-ALU32bit test-SLL32bit test-CLA4bit wave-OverflowDetector wave-SRL_SRA32bit wave-CLA32bit wave-ALU32bit wave-SLL32bit wave-CLA4bit
test-OverflowDetector test-SRL_SRA32bit test-CLA32bit test-ALU32bit test-SLL32bit test-CLA4bit wave-OverflowDetector wave-SRL_SRA32bit wave-CLA32bit wave-ALU32bit wave-SLL32bit wave-CLA4bit:
	$(MAKE) -C ALU $@

.PHONY: $(addsuffix -PC,$(ACTIONS))
$(addsuffix -PC,$(ACTIONS)): %-PC:
	$(MAKE) -C PC $*

.PHONY: test-PC32bit wave-PC32bit
test-PC32bit wave-PC32bit:
	$(MAKE) -C PC $@

.PHONY: $(addsuffix -RegisterFile,$(ACTIONS))
$(addsuffix -RegisterFile,$(ACTIONS)): %-RegisterFile:
	$(MAKE) -C RegisterFile $*

.PHONY: test-RegFile32bit wave-RegFile32bit
test-RegFile32bit wave-RegFile32bit:
	$(MAKE) -C RegisterFile $@

.PHONY: $(addsuffix -InstructionMemory,$(ACTIONS))
$(addsuffix -InstructionMemory,$(ACTIONS)): %-InstructionMemory:
	$(MAKE) -C InstructionMemory $*

.PHONY: $(addsuffix -InstructionAdder,$(ACTIONS))
$(addsuffix -InstructionAdder,$(ACTIONS)): %-InstructionAdder:
	$(MAKE) -C InstructionAdder $*

.PHONY: $(addsuffix -EarlyBranchingAdder,$(ACTIONS))
$(addsuffix -EarlyBranchingAdder,$(ACTIONS)): %-EarlyBranchingAdder:
	$(MAKE) -C EarlyBranchingAdder $*

.PHONY: $(addsuffix -ImmediateGenerator,$(ACTIONS))
$(addsuffix -ImmediateGenerator,$(ACTIONS)): %-ImmediateGenerator:
	$(MAKE) -C ImmediateGenerator $*

.PHONY: $(addsuffix -DataMemory,$(ACTIONS))
$(addsuffix -DataMemory,$(ACTIONS)): %-DataMemory:
	$(MAKE) -C DataMemory $*

clean:
	$(RM) -r build

help:
	@echo 'make build | test | wave | synth | clean'
	@echo 'Block targets: ACTION-BLOCK. Blocks: $(BLOCKS)'
	@echo 'Use make -C BLOCK help for module names.'

.PHONY: $(addsuffix -CPU,$(ACTIONS)) test-CPU32bit wave-CPU32bit
$(addsuffix -CPU,$(ACTIONS)): %-CPU:
	$(MAKE) -C CPU $*

test-CPU32bit wave-CPU32bit:
	$(MAKE) -C CPU $@

.PHONY: $(addsuffix -ControlUnit,$(ACTIONS)) test-CU32bit wave-CU32bit
$(addsuffix -ControlUnit,$(ACTIONS)): %-ControlUnit:
	$(MAKE) -C ControlUnit $*

test-CU32bit wave-CU32bit:
	$(MAKE) -C ControlUnit $@
