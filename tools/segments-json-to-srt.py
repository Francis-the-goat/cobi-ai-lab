#!/usr/bin/env python3
"""Convert segment-style JSON payloads to SRT."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


def fmt_ts(seconds: float) -> str:
    total_ms = int(round(max(0.0, seconds) * 1000))
    h = total_ms // 3_600_000
    rem = total_ms % 3_600_000
    m = rem // 60_000
    rem %= 60_000
    s = rem // 1000
    ms = rem % 1000
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"


def find_segments(payload: dict[str, Any]) -> list[tuple[float, float, str]]:
    segments: list[tuple[float, float, str]] = []

    raw_segments = payload.get("segments")
    if isinstance(raw_segments, list):
        for seg in raw_segments:
            if not isinstance(seg, dict):
                continue
            text = str(seg.get("text") or "").strip()
            if not text:
                continue
            start = float(seg.get("start") or 0.0)
            end = float(seg.get("end") or start)
            segments.append((start, max(end, start + 0.01), text))

    if segments:
        return segments

    text = str(payload.get("text") or "").strip()
    if text:
        return [(0.0, 3600.0, text)]
    return []


def to_srt(segments: list[tuple[float, float, str]]) -> str:
    lines: list[str] = []
    for idx, (start, end, text) in enumerate(segments, start=1):
        lines.append(str(idx))
        lines.append(f"{fmt_ts(start)} --> {fmt_ts(end)}")
        lines.append(text)
        lines.append("")
    return "\n".join(lines).strip() + "\n"


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: segments-json-to-srt.py <input_json> <output_srt>", file=sys.stderr)
        return 1
    inp = Path(sys.argv[1])
    out = Path(sys.argv[2])
    payload = json.loads(inp.read_text(encoding="utf-8"))
    segments = find_segments(payload)
    if not segments:
        print("No usable segments/text in payload", file=sys.stderr)
        return 1
    out.write_text(to_srt(segments), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
