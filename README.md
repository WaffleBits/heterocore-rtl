# HeteroCore RTL

[![CI](https://github.com/WaffleBits/heterocore-rtl/actions/workflows/ci.yml/badge.svg)](https://github.com/WaffleBits/heterocore-rtl/actions/workflows/ci.yml)

Synthesizable SystemVerilog controller and data-movement blocks for the
HeteroCore mixed analog-digital inference architecture.

> The RTL is simulated and linted in CI. There are no measured frequency,
> power, area, or silicon claims.

## Included Blocks

- Analog/digital schedule controller with ready/valid command input.
- Analog-array request/response interface.
- Streaming DMA engine.
- Inferred single-port SRAM controller.
- Saturating quantization unit.
- Signed INT8 matrix engine with writable activation/weight memories and INT32 accumulation.
- Cycle and operation performance counters.
- Compiler-plan to 32-bit schedule generator.
- OpenLane 2 configuration for the controller top.

## Verify

On Ubuntu:

```bash
sudo apt-get install iverilog verilator make
make test
make lint
make schedule
```

The self-checking testbench fails on handshake, tile-count, completion, or
counter regressions.

The controller testbench completes one analog and one digital operation in
eight busy cycles. A separate self-checking datapath test executes a 2x4 by
4x2 signed INT8 multiplication, verifies all four INT32 outputs, and accounts
for exactly 16 MACs in 16 compute cycles.

`results/tiny_char_transformer_schedule.hex` is the 27-operation schedule
generated from the checked-in ONNX transformer execution plan.

## Generate a Schedule

```bash
python tools/generate_schedule.py examples/sample.plan.json \
  -o build/schedule.hex \
  --manifest build/schedule.json
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for the instruction format and block
diagram.

## OpenLane

With OpenLane 2 and a supported PDK installed:

```bash
openlane openlane/config.json
```

This repository intentionally does not check in invented synthesis or layout
numbers. Publish generated reports only after a reproducible flow completes.
