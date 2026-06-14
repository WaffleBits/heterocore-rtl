RTL := rtl/schedule_controller.sv rtl/analog_array_if.sv rtl/dma_engine.sv rtl/sram_controller.sv rtl/quantize_unit.sv rtl/int8_matmul_engine.sv rtl/packed_int4_dot_product.sv rtl/topk_unit.sv rtl/kv_block_selector.sv rtl/attention_value_accumulator.sv rtl/heterocore_top.sv
PYTHON ?= python3

.PHONY: test lint schedule clean

test:
	mkdir -p build
	iverilog -g2012 -s heterocore_top_tb -o build/heterocore_top_tb $(RTL) tb/heterocore_top_tb.sv
	vvp build/heterocore_top_tb
	iverilog -g2012 -s int8_matmul_engine_tb -o build/int8_matmul_engine_tb rtl/int8_matmul_engine.sv tb/int8_matmul_engine_tb.sv
	vvp build/int8_matmul_engine_tb
	iverilog -g2012 -s packed_int4_dot_product -o build/packed_int4_dot_product rtl/packed_int4_dot_product.sv
	iverilog -g2012 -s kv_block_selector -o build/kv_block_selector rtl/topk_unit.sv rtl/kv_block_selector.sv
	iverilog -g2012 -s attention_value_accumulator -o build/attention_value_accumulator rtl/attention_value_accumulator.sv
	$(PYTHON) -m unittest discover -s tests

lint:
	verilator --lint-only --Wall -Wno-DECLFILENAME --top-module heterocore_top $(RTL)

schedule:
	$(PYTHON) tools/generate_schedule.py examples/sample.plan.json -o build/schedule.hex --manifest build/schedule.json

clean:
	rm -rf build obj_dir
