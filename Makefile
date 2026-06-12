RTL := rtl/schedule_controller.sv rtl/analog_array_if.sv rtl/dma_engine.sv rtl/sram_controller.sv rtl/quantize_unit.sv rtl/heterocore_top.sv
PYTHON ?= python3

.PHONY: test lint schedule clean

test:
	mkdir -p build
	iverilog -g2012 -s heterocore_top_tb -o build/heterocore_top_tb $(RTL) tb/heterocore_top_tb.sv
	vvp build/heterocore_top_tb
	$(PYTHON) -m unittest discover -s tests

lint:
	verilator --lint-only --Wall -Wno-DECLFILENAME --top-module heterocore_top $(RTL)

schedule:
	$(PYTHON) tools/generate_schedule.py examples/sample.plan.json -o build/schedule.hex --manifest build/schedule.json

clean:
	rm -rf build obj_dir
