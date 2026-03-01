#!/usr/bin/env python3
"""Convert SRT captions to cleaner text by removing rolling-caption overlap."""

from __future__ import annotations

import re
import sys
from pathlib import Path


BLOCK_RE = re.compile(
    r"\d+\s*\n"
    r"(\d{2}:\d{2}:\d{2},\d{3}\s+-->\s+\d{2}:\d{2}:\d{2},\d{3})\s*\n"
    r"(.+?)(?=\n{2,}|\Z)",
    re.DOTALL,
)


def clean_caption_text(text: str) -> str:
    text = re.sub(r"<[^>]+>", "", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def parse_srt(path: Path) -> list[str]:
    raw = path.read_text(encoding="utf-8", errors="ignore")
    out: list[str] = []
    for _, body in BLOCK_RE.findall(raw):
        caption = clean_caption_text(body)
        if caption:
            out.append(caption)
    return out


def dedupe_rolling(captions: list[str], max_overlap_words: int = 24) -> str:
    out_words: list[str] = []
    prev_caption = ""

    for cap in captions:
        if cap == prev_caption:
            continue
        prev_caption = cap

        words = cap.split()
        if not words:
            continue

        # Drop overlap between already-emitted suffix and new caption prefix.
        max_k = min(max_overlap_words, len(words), len(out_words))
        overlap = 0
        for k in range(max_k, 0, -1):
            if out_words[-k:] == words[:k]:
                overlap = k
                break
        out_words.extend(words[overlap:])

    text = " ".join(out_words)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: srt-to-clean-text.py <srt_file>", file=sys.stderr)
        return 1
    srt_path = Path(sys.argv[1])
    captions = parse_srt(srt_path)
    print(dedupe_rolling(captions))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
