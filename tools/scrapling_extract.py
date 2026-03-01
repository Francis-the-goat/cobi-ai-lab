#!/usr/bin/env python3
"""Minimal Scrapling extraction utility for OpenClaw workflows."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Fetch a URL with Scrapling and extract content."
    )
    parser.add_argument("--url", required=True, help="Target URL")
    parser.add_argument(
        "--selector",
        default=None,
        help="Optional CSS selector. If unset, entire main content is used.",
    )
    parser.add_argument(
        "--format",
        choices=("markdown", "html", "text"),
        default="markdown",
        help="Output format (default: markdown)",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=30,
        help="Request timeout in seconds (default: 30)",
    )
    parser.add_argument(
        "--retries",
        type=int,
        default=3,
        help="Retry attempts (default: 3)",
    )
    parser.add_argument(
        "--impersonate",
        default="chrome",
        help="Browser fingerprint profile (default: chrome)",
    )
    parser.add_argument(
        "--output",
        default=None,
        help="Optional output file. Use .json for metadata+content payload.",
    )
    return parser.parse_args()


def main() -> int:
    args = _parse_args()

    try:
        from scrapling.fetchers import Fetcher
        from scrapling.core.shell import Convertor
    except Exception:
        sys.stderr.write(
            "Scrapling runtime not found. Install it with:\n"
            "  bash ~/.openclaw/workspace/scripts/install_scrapling_runtime.sh\n"
        )
        return 2

    page = Fetcher.get(
        args.url,
        timeout=args.timeout,
        retries=args.retries,
        impersonate=args.impersonate,
        follow_redirects=True,
        stealthy_headers=True,
    )

    chunks = list(
        Convertor._extract_content(
            page,
            extraction_type=args.format,
            css_selector=args.selector,
            main_content_only=True,
        )
    )
    content = "".join(chunks).strip()
    title = (page.css("title::text").get() or "").strip()

    payload = {
        "url": page.url,
        "status": page.status,
        "title": title,
        "selector": args.selector,
        "format": args.format,
        "content": content,
    }

    if args.output:
        out_path = Path(args.output).expanduser().resolve()
        out_path.parent.mkdir(parents=True, exist_ok=True)
        if out_path.suffix.lower() == ".json":
            out_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        else:
            out_path.write_text(content, encoding="utf-8")
        print(str(out_path))
        return 0

    if args.format == "text":
        print(content)
    else:
        print(json.dumps(payload, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
