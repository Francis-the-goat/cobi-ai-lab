#!/usr/bin/env python3
"""Convert Deepgram JSON transcription output to SRT."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


def fmt_ts(seconds: float) -> str:
    total_ms = int(round(max(0.0, seconds) * 1000))
    hours = total_ms // 3_600_000
    rem = total_ms % 3_600_000
    minutes = rem // 60_000
    rem %= 60_000
    secs = rem // 1000
    ms = rem % 1000
    return f"{hours:02d}:{minutes:02d}:{secs:02d},{ms:03d}"


def build_segments(payload: dict[str, Any]) -> list[tuple[float, float, str]]:
    results = payload.get("results") or {}
    utterances = results.get("utterances") or []
    segments: list[tuple[float, float, str]] = []

    for u in utterances:
        start = float(u.get("start") or 0.0)
        end = float(u.get("end") or start)
        text = str(u.get("transcript") or "").strip()
        if text:
            segments.append((start, max(end, start + 0.01), text))

    if segments:
        return segments

    channels = results.get("channels") or []
    if channels:
        alts = channels[0].get("alternatives") or []
        if alts:
            alt = alts[0]
            paragraphs = (((alt.get("paragraphs") or {}).get("paragraphs")) or [])
            for p in paragraphs:
                text = str(p.get("sentences", [{}])[0].get("text", "")).strip()
                start = float(p.get("start") or 0.0)
                end = float(p.get("end") or start)
                if text:
                    segments.append((start, max(end, start + 0.01), text))

            if segments:
                return segments

            transcript = str(alt.get("transcript") or "").strip()
            if transcript:
                duration = 2.0
                segments.append((0.0, duration, transcript))
                return segments

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
        print("Usage: deepgram-to-srt.py <input_json> <output_srt>", file=sys.stderr)
        return 1

    input_path = Path(sys.argv[1])
    out_path = Path(sys.argv[2])
    payload = json.loads(input_path.read_text(encoding="utf-8"))
    segments = build_segments(payload)
    if not segments:
        print("No transcript segments found in Deepgram response", file=sys.stderr)
        return 1

    out_path.write_text(to_srt(segments), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
