import argparse
import json
from math import ceil
from pathlib import Path

OPCODES = {
    "embedding": 0,
    "linear": 1,
    "matmul": 2,
    "softmax": 3,
    "layer_norm": 4,
    "gelu": 5,
}


def encode_operator(operator: dict, array_size: int = 128) -> int:
    dimensions = operator["dimensions"]
    m_tiles = min(0x7FF, ceil(dimensions["m"] / array_size))
    k_tiles = min(0xFF, ceil(dimensions["k"] / array_size))
    n_tiles = min(0xFF, ceil(dimensions["n"] / array_size))
    target = 1 if operator["target"] == "analog" else 0
    opcode = OPCODES.get(operator["type"], 15)
    return (target << 31) | (opcode << 27) | (m_tiles << 16) | (k_tiles << 8) | n_tiles


def main() -> None:
    parser = argparse.ArgumentParser(description="Encode a HeteroCore execution plan.")
    parser.add_argument("plan", type=Path)
    parser.add_argument("-o", "--output", type=Path, required=True)
    parser.add_argument("--manifest", type=Path)
    args = parser.parse_args()

    plan = json.loads(args.plan.read_text(encoding="utf-8"))
    encoded = [
        {"id": operator["id"], "word": encode_operator(operator)}
        for operator in plan["operators"]
    ]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        "\n".join(f"{item['word']:08x}" for item in encoded) + "\n",
        encoding="ascii",
    )
    if args.manifest:
        args.manifest.parent.mkdir(parents=True, exist_ok=True)
        args.manifest.write_text(json.dumps(encoded, indent=2) + "\n", encoding="utf-8")
    print(f"encoded {len(encoded)} operations to {args.output}")


if __name__ == "__main__":
    main()

