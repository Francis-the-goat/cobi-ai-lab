#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import json
import math
import re
import subprocess
from collections import Counter
from pathlib import Path
from typing import Any


STOPWORDS = {
    "about",
    "after",
    "again",
    "agent",
    "agents",
    "all",
    "also",
    "and",
    "any",
    "are",
    "because",
    "been",
    "before",
    "being",
    "between",
    "both",
    "build",
    "building",
    "business",
    "can",
    "content",
    "convert",
    "data",
    "decision",
    "each",
    "evidence",
    "find",
    "for",
    "from",
    "good",
    "have",
    "high",
    "how",
    "into",
    "just",
    "like",
    "more",
    "most",
    "need",
    "not",
    "one",
    "only",
    "output",
    "over",
    "same",
    "should",
    "signal",
    "smb",
    "source",
    "systems",
    "that",
    "the",
    "their",
    "them",
    "then",
    "there",
    "these",
    "they",
    "this",
    "through",
    "today",
    "use",
    "using",
    "value",
    "what",
    "when",
    "with",
    "work",
    "your",
}

ANCHOR_TERMS = {
    "ai",
    "agentic",
    "automation",
    "founder",
    "entrepreneurship",
    "operations",
    "personal",
    "brand",
    "distribution",
    "execution",
}

DEFAULT_PREFERENCES: dict[str, Any] = {
    "preferredUploaders": [],
    "seedQueries": [],
    "officialDocs": [],
    "maxPerUploader": 2,
}


def run_json_lines(cmd: list[str]) -> list[dict]:
    proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if proc.returncode != 0:
        return []
    rows: list[dict] = []
    for line in proc.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            rows.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return rows


def load_preferences(path: Path) -> dict[str, Any]:
    prefs = dict(DEFAULT_PREFERENCES)
    if not path.exists():
        return prefs
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return prefs
    if not isinstance(data, dict):
        return prefs
    prefs.update(data)
    return prefs


def slugify(text: str, fallback: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return (slug[:48] or fallback).strip("-")


def extract_keywords(text: str, limit: int = 16) -> list[str]:
    tokens = re.findall(r"[a-zA-Z][a-zA-Z0-9\-]{2,}", text.lower())
    counts = Counter(t for t in tokens if t not in STOPWORDS and len(t) >= 3)
    for term in ANCHOR_TERMS:
        if term in text.lower():
            counts[term] += 3
    return [w for w, _ in counts.most_common(limit)]


def parse_upload_date(raw: str) -> dt.date | None:
    if not raw or len(raw) != 8:
        return None
    try:
        return dt.datetime.strptime(raw, "%Y%m%d").date()
    except ValueError:
        return None


def score_item(item: dict, keywords: set[str], preferred_uploaders: list[str]) -> tuple[float, list[str], list[str]]:
    title = (item.get("title") or "").lower()
    uploader = (item.get("uploader") or "").lower()
    title_tokens = set(re.findall(r"[a-zA-Z][a-zA-Z0-9\-]{2,}", title))
    overlap = sorted(title_tokens.intersection(keywords))
    reasons: list[str] = []

    score = len(overlap) * 2.5
    if overlap:
        reasons.append(f"keyword_overlap:{','.join(overlap[:2])}")
    if any(t in title for t in ("ai", "agent", "automation", "workflow", "founder", "business", "brand")):
        score += 2
        reasons.append("topic_fit")

    views = item.get("view_count") or 0
    score += min(4.0, math.log10(max(views, 1)))

    d = parse_upload_date(item.get("upload_date") or "")
    if d is not None:
        age_days = (dt.date.today() - d).days
        if age_days <= 14:
            score += 3
            reasons.append("recent")
        elif age_days <= 60:
            score += 1.5
        elif age_days > 365:
            score -= 1

    for preferred in preferred_uploaders:
        pl = preferred.lower().strip()
        if pl and pl in uploader:
            score += 3.5
            reasons.append(f"preferred_uploader:{preferred}")
            break

    return score, overlap[:4], reasons[:3]


def build_queries(keywords: list[str], seed_queries: list[str]) -> list[str]:
    queries = [
        "agent engineering production workflows",
        "openai agents production workflows",
        "ai entrepreneurship case study",
        "ai founder systems execution",
        "personal brand ai business strategy",
    ]
    queries.extend(seed_queries[:8])
    for kw in keywords[:8]:
        queries.append(f"{kw} ai automation business")
    deduped: list[str] = []
    seen = set()
    for q in queries:
        key = q.lower().strip()
        if key in seen:
            continue
        seen.add(key)
        deduped.append(q)
    return deduped[:12]


def enforce_uploader_diversity(items: list[dict[str, Any]], max_per_uploader: int) -> list[dict[str, Any]]:
    if max_per_uploader < 1:
        return items
    picked: list[dict[str, Any]] = []
    counts: dict[str, int] = {}
    for item in items:
        uploader = (item.get("uploader") or "").strip().lower() or "unknown"
        if counts.get(uploader, 0) >= max_per_uploader:
            continue
        picked.append(item)
        counts[uploader] = counts.get(uploader, 0) + 1
    return picked


def main() -> int:
    p = argparse.ArgumentParser(description="Recommend high-signal sources from recent source cards.")
    p.add_argument("--workspace", default=str(Path.home() / ".openclaw" / "workspace"))
    p.add_argument("--latest", type=int, default=5, help="How many latest source cards to use.")
    p.add_argument("--per-query", type=int, default=6, help="YouTube results per query.")
    p.add_argument("--max-results", type=int, default=12)
    p.add_argument("--queue", type=int, default=2, help="How many recommendations to queue for transcription.")
    p.add_argument(
        "--preferences",
        default="config/source_preferences.json",
        help="Preferences JSON (relative to workspace or absolute path).",
    )
    args = p.parse_args()

    ws = Path(args.workspace)
    sources_dir = ws / "memory" / "sources"
    research_dir = ws / "memory" / "research"
    state_dir = research_dir / ".state"
    queue_script = ws / "scripts" / "transcription_queue.sh"
    seen_file = state_dir / "seen_videos.txt"
    pref_path = Path(args.preferences)
    if not pref_path.is_absolute():
        pref_path = ws / pref_path
    prefs = load_preferences(pref_path)
    preferred_uploaders = [str(x) for x in prefs.get("preferredUploaders", []) if str(x).strip()]
    seed_queries = [str(x) for x in prefs.get("seedQueries", []) if str(x).strip()]
    official_docs = [x for x in prefs.get("officialDocs", []) if isinstance(x, dict)]
    max_per_uploader = int(prefs.get("maxPerUploader", 2) or 2)

    research_dir.mkdir(parents=True, exist_ok=True)
    state_dir.mkdir(parents=True, exist_ok=True)
    seen_file.touch(exist_ok=True)
    seen_ids = {line.strip() for line in seen_file.read_text().splitlines() if line.strip()}

    dated_sources = [
        f
        for f in sources_dir.glob("*.md")
        if re.match(r"^\d{4}-\d{2}-\d{2}-.*\.md$", f.name)
    ]
    pool = dated_sources if dated_sources else list(sources_dir.glob("*.md"))
    source_files = sorted(pool, key=lambda x: x.stat().st_mtime, reverse=True)[: args.latest]
    if not source_files:
        print("no_source_cards_found")
        return 0

    source_text = "\n\n".join(f.read_text(errors="ignore") for f in source_files)
    keywords = extract_keywords(source_text, limit=16)
    keyword_set = set(keywords)
    queries = build_queries(keywords, seed_queries)

    items_by_id: dict[str, dict] = {}
    for q in queries:
        cmd = [
            "yt-dlp",
            "--dump-json",
            "--flat-playlist",
            "--quiet",
            f"ytsearch{args.per_query}:{q}",
        ]
        for row in run_json_lines(cmd):
            vid = row.get("id") or ""
            title = row.get("title") or ""
            if not vid or not title:
                continue
            item = {
                "id": vid,
                "title": title,
                "uploader": row.get("uploader") or "",
                "upload_date": row.get("upload_date") or "",
                "view_count": row.get("view_count") or 0,
                "url": f"https://www.youtube.com/watch?v={vid}",
                "query": q,
            }
            score, overlap, reasons = score_item(item, keyword_set, preferred_uploaders)
            item["score"] = round(score, 3)
            item["overlap"] = overlap
            item["reasons"] = reasons
            prev = items_by_id.get(vid)
            if prev is None or item["score"] > prev["score"]:
                items_by_id[vid] = item

    ranked = sorted(items_by_id.values(), key=lambda x: x["score"], reverse=True)
    ranked = enforce_uploader_diversity(ranked, max_per_uploader)
    ranked = ranked[: args.max_results]
    fallback_only = False
    if not ranked:
        fallback_only = True
        for uploader in preferred_uploaders[: min(8, args.max_results)]:
            search_q = re.sub(r"\s+", "+", f"{uploader} ai business systems")
            ranked.append(
                {
                    "id": f"fallback-{uploader.lower().replace(' ', '-')}",
                    "title": f"{uploader} (seed source search)",
                    "uploader": uploader,
                    "upload_date": "",
                    "view_count": 0,
                    "url": f"https://www.youtube.com/results?search_query={search_q}",
                    "query": "seed_fallback",
                    "score": 0.0,
                    "overlap": [],
                    "reasons": ["fallback_seed_uploader"],
                }
            )

    queued: list[dict] = []
    for item in ranked:
        if len(queued) >= args.queue:
            break
        if str(item.get("id") or "").startswith("fallback-"):
            continue
        if item["id"] in seen_ids:
            continue
        slug = slugify(item["title"], f"video-{item['id']}")
        cmd = [str(queue_script), "add", item["url"], slug, item["title"]]
        proc = subprocess.run(["bash", *cmd], capture_output=True, text=True, check=False)
        if proc.returncode == 0:
            queued.append(item)
            seen_ids.add(item["id"])

    seen_file.write_text("\n".join(sorted(seen_ids)) + ("\n" if seen_ids else ""))

    today = dt.date.today().isoformat()
    report = research_dir / f"{today}-source-recommendations.md"
    lines: list[str] = []
    lines.append(f"# Source Adaptation Recommendations - {today}")
    lines.append("")
    lines.append("## Source Cards Used")
    for f in source_files:
        lines.append(f"- {f.name}")
    lines.append("")
    lines.append("## Extracted Preference Keywords")
    lines.append("- " + ", ".join(keywords[:12]))
    lines.append("")
    lines.append("## Search Queries")
    for q in queries[:10]:
        lines.append(f"- {q}")
    lines.append("")
    lines.append("## Quality Filters")
    lines.append("- Prioritize preferred creators and official-first operator sources.")
    lines.append(f"- Uploader diversity cap: {max_per_uploader} per uploader.")
    lines.append("- Bias toward recent and implementation-focused material.")
    lines.append("")
    lines.append("## Recommended Sources")
    for item in ranked[:10]:
        overlap = ", ".join(item.get("overlap") or [])
        reasons = ", ".join(item.get("reasons") or [])
        lines.append(
            f"- [{item['title']}]({item['url']}) | score={item['score']} | "
            f"uploader={item['uploader'] or 'n/a'} | overlap={overlap or 'n/a'} | "
            f"reason={reasons or 'n/a'} | seed_query={item['query']}"
        )
    lines.append("")
    if fallback_only:
        lines.append("## Fallback Note")
        lines.append("- Live video retrieval returned no results; using seed-source fallback list.")
        lines.append("- Next step: verify outbound access for yt-dlp on host and rerun.")
        lines.append("")
    lines.append("## Primary Docs Priority")
    if official_docs:
        for doc in official_docs:
            name = str(doc.get("name") or "Doc")
            url = str(doc.get("url") or "")
            reason = str(doc.get("reason") or "")
            lines.append(f"- [{name}]({url}) | {reason}".rstrip())
    else:
        lines.append("- none configured")
    lines.append("")
    lines.append("## Queued For Transcription")
    if queued:
        for item in queued:
            lines.append(f"- [{item['title']}]({item['url']})")
    else:
        lines.append("- none (all top items already queued/seen)")
    lines.append("")
    lines.append("## Operator Notes")
    lines.append("- Use the top 3 recommendations to expand the next insight synthesis.")
    lines.append("- If recommendations are weak, refine source cards before the next run.")
    report.write_text("\n".join(lines) + "\n")

    status = "fallback" if fallback_only else "ok"
    print(
        f"recommend_status={status} sources={len(source_files)} keywords={len(keywords)} "
        f"recommendations={len(ranked)} queued={len(queued)} report={report}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
