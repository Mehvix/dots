#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""apo2peace — convert Equalizer APO parametric EQ .txt files to Peace presets.

Handles AutoEQ / oratory1990 style files, including comma decimal separators:

  Preamp: -10,0 dB
  Filter 1: ON PK Fc 23 Hz Gain 2,6 dB Q 1,6

Usage: ./apo2peace.py IN.txt [IN.txt ...] [-o OUTDIR]
Writes "<stem>.peace" next to each input (or into OUTDIR).
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# Peace [Filters] codes = 0-based index in its filter picker.
# Peak (0) is the default and is omitted.
FILTER_CODES = {
    ("PK", True): 0,
    ("LPQ", True): 1,
    ("HPQ", True): 2,
    ("BP", True): 3,
    ("LS", False): 4,
    ("HS", False): 5,
    ("NO", True): 6,
    ("AP", True): 7,
    ("LSC", False): 8,
    ("HSC", False): 9,
    ("LS", True): 14,
    ("HS", True): 15,
    ("LSC", True): 16,
    ("HSC", True): 17,
}

NUM = r"(-?\d+(?:[.,]\d+)?)"
PREAMP_RE = re.compile(rf"^Preamp:\s*{NUM}\s*dB", re.I)
FILTER_RE = re.compile(
    rf"^Filter\s*\d*:\s*(ON|OFF)\s+([A-Z]+)\s+Fc\s+{NUM}\s*Hz"
    rf"(?:\s+Gain\s+{NUM}\s*dB)?(?:\s+Q\s+{NUM})?",
    re.I,
)


def num(s: str | None) -> float | None:
    return None if s is None else float(s.replace(",", "."))


def fmt(x: float) -> str:
    return f"{x:g}"


def convert(text: str) -> str:
    preamp = 0.0
    filters: list[tuple[int, float, float, float]] = []
    for line in text.splitlines():
        line = line.strip()
        if m := PREAMP_RE.match(line):
            preamp = num(m[1])
        elif m := FILTER_RE.match(line):
            state, kind, fc, gain, q = m.groups()
            if state.upper() != "ON":
                continue
            key = (kind.upper(), q is not None)
            if key not in FILTER_CODES:
                raise ValueError(f"unsupported filter: {line}")
            filters.append((FILTER_CODES[key], num(fc), num(gain) or 0.0, num(q) or 1.41))
        elif line and not line.startswith("#"):
            raise ValueError(f"unrecognised line: {line}")
    if not filters:
        raise ValueError("no filters found")

    out = ["[Frequencies]"]
    out += [f"Frequency{i}={fmt(f[1])}" for i, f in enumerate(filters, 1)]
    out.append("[Gains]")
    out += [f"Gain{i}={fmt(f[2])}" for i, f in enumerate(filters, 1)]
    out.append("[Qualities]")
    out += [f"Quality{i}={fmt(f[3])}" for i, f in enumerate(filters, 1)]
    out.append("[Filters]")
    out += [f"Filter{i}={f[0]}" for i, f in enumerate(filters, 1) if f[0]]
    out += [
        "[General]",
        "Configuration Icon=1",
        f"PreAmp={fmt(preamp)}",
        "[Speakers]",
        "SpeakerId0=0",
        "SpeakerTargets0=all",
        "SpeakerName0=All",
    ]
    return "\n".join(out) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("inputs", nargs="+", type=Path)
    ap.add_argument("-o", "--outdir", type=Path)
    args = ap.parse_args()
    rc = 0
    for src in args.inputs:
        try:
            body = convert(src.read_text(encoding="utf-8-sig"))
        except ValueError as e:
            print(f"{src}: {e}", file=sys.stderr)
            rc = 1
            continue
        dst = (args.outdir or src.parent) / f"{src.stem}.peace"
        dst.write_text(body, encoding="utf-8", newline="\n")
        print(f"{src} -> {dst}")
    return rc


if __name__ == "__main__":
    sys.exit(main())
