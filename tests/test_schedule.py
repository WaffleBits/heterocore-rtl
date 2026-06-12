import importlib.util
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).parents[1] / "tools" / "generate_schedule.py"
SPEC = importlib.util.spec_from_file_location("generate_schedule", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class ScheduleTests(unittest.TestCase):
    def test_encodes_target_and_tiles(self):
        operator = {
            "id": "linear",
            "type": "linear",
            "target": "analog",
            "dimensions": {"m": 129, "k": 256, "n": 1},
        }
        word = MODULE.encode_operator(operator)
        self.assertEqual((word >> 31) & 1, 1)
        self.assertEqual((word >> 16) & 0x7FF, 2)
        self.assertEqual((word >> 8) & 0xFF, 2)
        self.assertEqual(word & 0xFF, 1)

    def test_unknown_operator_uses_extension_opcode(self):
        operator = {
            "id": "custom",
            "type": "custom",
            "target": "digital",
            "dimensions": {"m": 1, "k": 1, "n": 1},
        }
        word = MODULE.encode_operator(operator)
        self.assertEqual((word >> 27) & 0xF, 15)


if __name__ == "__main__":
    unittest.main()

