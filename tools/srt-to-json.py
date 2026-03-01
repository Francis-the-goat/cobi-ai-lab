#!/usr/bin/env python3
import json
import re
import sys

def parse_srt(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
    
    # Parse SRT: number, time range, text blocks
    pattern = r'\d+\s+([\d:,]+)\s+-+>\s+([\d:,]+)\s+(.+?)(?=\n\d+\s|\Z)'
    matches = re.findall(pattern, content, re.DOTALL)
    
    entries = []
    for start, end, text in matches:
        entries.append({
            "start": start,
            "end": end,
            "text": text.replace('\n', ' ').strip()
        })
    
    return entries

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: srt-to-json.py <srt_file>", file=sys.stderr)
        sys.exit(1)
    
    entries = parse_srt(sys.argv[1])
    print(json.dumps(entries, indent=2))
