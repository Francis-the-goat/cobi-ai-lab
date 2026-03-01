#!/usr/bin/env python3
"""Scrapling-based web monitor for high-signal source pages."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


@dataclass
class SourceSpec:
    name: str
    url: str
    selector: str | None
    priority: str
    focus: str


def parse_args() -> argparse.Namespace:
    script_dir = Path(__file__).resolve().parent
    radar_dir = script_dir.parent
    queue_dir = radar_dir / "queue"
    ts = datetime.now().strftime("%Y%m%d-%H%M")
    parser = argparse.ArgumentParser(description="Monitor web pages with Scrapling and detect content changes.")
    parser.add_argument("--config", default=str(radar_dir / "config" / "web-sources.txt"))
    parser.add_argument("--state", default=str(queue_dir / "web-seen.json"))
    parser.add_argument("--output", default=str(queue_dir / f"web-signals-{ts}.json"))
    parser.add_argument("--timeout", type=int, default=25)
    parser.add_argument("--retries", type=int, default=2)
    parser.add_argument(
        "--emit-initial",
        action="store_true",
        help="Emit first-seen items as signals (default: false for clean baseline)",
    )
    return parser.parse_args()


def load_specs(path: Path) -> list[SourceSpec]:
    specs: list[SourceSpec] = []
    if not path.exists():
        raise FileNotFoundError(f"config file not found: {path}")

    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = [p.strip() for p in line.split("|")]
        parts += [""] * (5 - len(parts))
        name, url, selector, priority, focus = parts[:5]
        if not name or not url:
            continue
        specs.append(
            SourceSpec(
                name=name,
                url=url,
                selector=selector or None,
                priority=priority or "medium",
                focus=focus or "",
            )
        )
    return specs


def normalize_text(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def load_state(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def save_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")


def main() -> int:
    args = parse_args()
    config_path = Path(args.config).expanduser().resolve()
    state_path = Path(args.state).expanduser().resolve()
    output_path = Path(args.output).expanduser().resolve()

    try:
        from scrapling.fetchers import Fetcher
        from scrapling.core.shell import Convertor
    except Exception:
        sys.stderr.write(
            "Scrapling runtime not available. Install with:\n"
            "  bash ~/.openclaw/workspace/scripts/install_scrapling_runtime.sh\n"
        )
        return 2

    specs = load_specs(config_path)
    previous_state: dict[str, Any] = load_state(state_path)
    now = datetime.now(timezone.utc).isoformat()

    signals: list[dict[str, Any]] = []
    errors: list[dict[str, str]] = []
    next_state: dict[str, Any] = dict(previous_state)

    for spec in specs:
        try:
            page = Fetcher.get(
                spec.url,
                timeout=args.timeout,
                retries=args.retries,
                impersonate="chrome",
                follow_redirects=True,
                stealthy_headers=True,
            )
            chunks = list(
                Convertor._extract_content(
                    page,
                    extraction_type="text",
                    css_selector=spec.selector,
                    main_content_only=True,
                )
            )
            text = normalize_text("".join(chunks))
            digest = hashlib.sha256(text.encode("utf-8")).hexdigest()
            title = normalize_text((page.css("title::text").get() or "").strip())
            excerpt = text[:400]

            previous = previous_state.get(spec.url, {})
            prev_hash = previous.get("hash")
            changed = prev_hash is not None and prev_hash != digest
            first_seen = prev_hash is None

            next_state[spec.url] = {
                "name": spec.name,
                "hash": digest,
                "title": title,
                "priority": spec.priority,
                "focus": spec.focus,
                "selector": spec.selector,
                "last_checked": now,
                "last_excerpt": excerpt,
            }

            if changed or (first_seen and args.emit_initial):
                signals.append(
                    {
                        "timestamp": now,
                        "name": spec.name,
                        "url": spec.url,
                        "priority": spec.priority,
                        "focus": spec.focus,
                        "change_type": "first_seen" if first_seen else "content_changed",
                        "title": title,
                        "excerpt": excerpt,
                        "content_hash": digest,
                        "previous_hash": prev_hash,
                    }
                )

        except Exception as exc:  # broad catch: one bad source should not kill the monitor
            errors.append({"name": spec.name, "url": spec.url, "error": str(exc)})

    payload = {
        "timestamp": now,
        "source": "web-scrapling",
        "checked": len(specs),
        "changed": len(signals),
        "errors": errors,
        "signals": signals,
    }

    save_json(state_path, next_state)
    save_json(output_path, payload)
    print(json.dumps({"output": str(output_path), "changed": len(signals), "errors": len(errors)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
