import os
from vunit.verilog import VUnit
from pathlib import Path

if __name__ == "__main__":
    ROOT = Path(__file__).parent
    print(ROOT)

    vu = VUnit.from_argv()

    lib = vu.add_library("lib")
    lib.add_source_files(ROOT / "tb" / "*.sv")


    blklst = [
        "LEG.sv"
    ]

    for fname in os.listdir(ROOT / "src"):
        if fname.endswith(".sv") and not fname in blklst:
            lib.add_source_files(ROOT / "src" / fname)


    vu.main()
