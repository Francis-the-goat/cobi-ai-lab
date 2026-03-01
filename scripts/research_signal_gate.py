#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import re
from pathlib import Path
from typing import Any


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def save_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, ensure_ascii=True)
        f.write("\n")


def normalize(text: str) -> str:
    return re.sub(r"\s+", " ", text.lower()).strip()


def phrase_hits(text: str, phrases: list[str]) -> list[str]:
    hay = normalize(text)
    hits: list[str] = []
    for phrase in phrases:
        p = normalize(phrase)
        if not p:
            continue
        if " " in p:
            if p in hay:
                hits.append(phrase)
            continue
        if re.search(rf"\b{re.escape(p)}[a-z0-9\-]*\b", hay):
            hits.append(phrase)
    return sorted(set(hits))


def clamp_0_5(value: float) -> int:
    if value < 0:
        return 0
    if value > 5:
        return 5
    return int(round(value))


def score_component(hit_count: int, bias: int = 0) -> int:
    if hit_count <= 0:
        return 0
    return min(5, hit_count + bias)


def build_candidates(videos: list[dict[str, Any]], hn_items: list[dict[str, Any]]) -> list[dict[str, Any]]:
    candidates: list[dict[str, Any]] = []

    for item in videos:
        candidates.append(
            {
                "sourceType": "video",
                "id": item.get("id", ""),
                "title": item.get("title", ""),
                "url": item.get("url", ""),
                "query": item.get("query", ""),
                "uploader": item.get("uploader", ""),
                "rawScore": item.get("score", 0),
                "meta": {
                    "view_count": item.get("view_count", 0),
                    "upload_date": item.get("upload_date", ""),
                },
            }
        )

    for item in hn_items:
        candidates.append(
            {
                "sourceType": "news",
                "id": item.get("hn_url", item.get("url", "")),
                "title": item.get("title", ""),
                "url": item.get("url", "") or item.get("hn_url", ""),
                "query": item.get("query", ""),
                "uploader": "hn",
                "rawScore": item.get("score", 0),
                "meta": {
                    "points": item.get("points", 0),
                    "comments": item.get("comments", 0),
                    "created_at": item.get("created_at", ""),
                },
            }
        )

    dedup: dict[str, dict[str, Any]] = {}
    for c in candidates:
        key = normalize(f"{c.get('title', '')}|{c.get('url', '')}")
        if not key:
            continue
        if key not in dedup:
            dedup[key] = c
            continue
        if float(c.get("rawScore", 0)) > float(dedup[key].get("rawScore", 0)):
            dedup[key] = c
    return list(dedup.values())


def novelty_score(fingerprint: str, seen_fingerprints: set[str]) -> int:
    if fingerprint in seen_fingerprints:
        return 1
    return 5


def parse_history(path: Path) -> set[str]:
    if not path.exists():
        return set()
    lines = [line.strip() for line in path.read_text(encoding="utf-8").splitlines()]
    return {line for line in lines if line}


def write_history(path: Path, fingerprints: set[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = "\n".join(sorted(fingerprints))
    if payload:
        payload += "\n"
    path.write_text(payload, encoding="utf-8")


def fingerprint_for(candidate: dict[str, Any]) -> str:
    base = normalize(f"{candidate.get('title', '')}|{candidate.get('url', '')}")
    return hashlib.sha1(base.encode("utf-8")).hexdigest()


def area_hits(text: str, area_keywords: dict[str, list[str]]) -> dict[str, list[str]]:
    return {area: phrase_hits(text, words) for area, words in area_keywords.items()}


def evaluate_candidate(
    candidate: dict[str, Any],
    policy: dict[str, Any],
    seen_fingerprints: set[str],
) -> dict[str, Any]:
    title = candidate.get("title", "")
    query = candidate.get("query", "")
    source_type = candidate.get("sourceType", "")
    text = normalize(f"{title} {query}")

    kw = policy.get("keywords", {})
    focus_kw = kw.get("focus", {})
    impl_kw = kw.get("implementationEvidence", [])
    action_kw = kw.get("actionability48h", [])
    entrepreneur_kw = kw.get("entrepreneurImportance", {})

    focus = area_hits(text, focus_kw)
    focus_match_areas = sorted([name for name, hits in focus.items() if hits])
    focus_hit_count = sum(len(v) for v in focus.values())

    impl_hits = phrase_hits(text, impl_kw)
    action_hits = phrase_hits(text, action_kw)

    revenue_hits = phrase_hits(text, entrepreneur_kw.get("revenue", []))
    delivery_hits = phrase_hits(text, entrepreneur_kw.get("delivery", []))
    moat_hits = phrase_hits(text, entrepreneur_kw.get("moat", []))
    risk_hits = phrase_hits(text, entrepreneur_kw.get("risk", []))

    fp = fingerprint_for(candidate)
    novelty = novelty_score(fp, seen_fingerprints)

    relevance = clamp_0_5((2 if len(focus_match_areas) >= 1 else 0) + min(3, focus_hit_count))
    implementation_depth = score_component(len(impl_hits), 1 if source_type == "video" else 0)
    business_leverage = clamp_0_5(
        score_component(len(revenue_hits), 0)
        + (1 if delivery_hits else 0)
        + (1 if moat_hits else 0)
    )
    actionability = clamp_0_5(score_component(len(action_hits), 0) + (1 if implementation_depth >= 3 else 0))
    relevance_total = relevance + implementation_depth + business_leverage + novelty + actionability

    revenue_impact = clamp_0_5(
        score_component(len(revenue_hits), 0) + (1 if business_leverage >= 3 else 0)
    )
    time_saved = clamp_0_5(
        score_component(len(delivery_hits), 0) + (1 if actionability >= 4 else 0)
    )
    moat_strength = clamp_0_5(
        score_component(len(moat_hits), 0)
        + (1 if len(focus_match_areas) >= 2 and implementation_depth >= 3 else 0)
    )
    risk_reduction = clamp_0_5(
        score_component(len(risk_hits), 0)
        + (
            1
            if any(term in text for term in ("guardrail", "reliability", "security", "ci", "test"))
            else 0
        )
    )
    near_term = clamp_0_5(actionability + (1 if implementation_depth >= 3 else 0))
    entrepreneur_importance = revenue_impact + time_saved + moat_strength + risk_reduction + near_term

    gates_cfg = policy.get("gates", {})
    gates = {
        "focusMatch": bool(focus_match_areas),
        "implementationEvidence": bool(impl_hits),
        "actionability48h": bool(action_hits),
        "entrepreneurImportance": bool(
            revenue_hits or delivery_hits or moat_hits or risk_hits
        ),
    }

    gate_failures: list[str] = []
    if gates_cfg.get("requireFocusMatch", True) and not gates["focusMatch"]:
        gate_failures.append("no_focus_area_match")
    if gates_cfg.get("requireImplementationEvidence", True) and not gates["implementationEvidence"]:
        gate_failures.append("no_implementation_evidence")
    if gates_cfg.get("requireActionability48h", True) and not gates["actionability48h"]:
        gate_failures.append("no_48h_actionability")
    if gates_cfg.get("requireEntrepreneurImportance", True) and not gates["entrepreneurImportance"]:
        gate_failures.append("no_entrepreneur_importance")

    thresholds = policy.get("thresholds", {})
    min_relevance = int(thresholds.get("minRelevanceScore", 23))
    min_importance = int(thresholds.get("minImportanceScore", 18))

    pass_relevance = relevance_total >= min_relevance
    pass_importance = entrepreneur_importance >= min_importance

    rejection_reasons = list(gate_failures)
    if not pass_relevance:
        rejection_reasons.append(f"relevance_below_threshold:{relevance_total}<{min_relevance}")
    if not pass_importance:
        rejection_reasons.append(f"importance_below_threshold:{entrepreneur_importance}<{min_importance}")

    passed = not rejection_reasons
    return {
        **candidate,
        "fingerprint": fp,
        "focusAreasMatched": focus_match_areas,
        "keywordHits": {
            "focus": focus,
            "implementationEvidence": impl_hits,
            "actionability48h": action_hits,
            "entrepreneur": {
                "revenue": revenue_hits,
                "delivery": delivery_hits,
                "moat": moat_hits,
                "risk": risk_hits,
            },
        },
        "scores": {
            "relevance": relevance,
            "implementationDepth": implementation_depth,
            "businessLeverage": business_leverage,
            "novelty": novelty,
            "actionability48h": actionability,
            "relevanceTotal": relevance_total,
            "entrepreneurImportance": entrepreneur_importance,
            "entrepreneurBreakdown": {
                "revenueImpact": revenue_impact,
                "timeSavedLeverage": time_saved,
                "moatStrength": moat_strength,
                "riskReduction": risk_reduction,
                "nearTermExecutability": near_term,
            },
        },
        "gates": gates,
        "passed": passed,
        "rejectionReasons": rejection_reasons,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Strict research signal gate with entrepreneur weighting.")
    parser.add_argument("--policy", required=True)
    parser.add_argument("--videos", required=True)
    parser.add_argument("--hn", required=True)
    parser.add_argument("--history", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    policy_path = Path(args.policy).expanduser()
    videos_path = Path(args.videos).expanduser()
    hn_path = Path(args.hn).expanduser()
    history_path = Path(args.history).expanduser()
    out_path = Path(args.output).expanduser()

    policy = load_json(policy_path)
    videos = load_json(videos_path)
    hn_items = load_json(hn_path)
    seen_fingerprints = parse_history(history_path)

    candidates = build_candidates(videos=videos, hn_items=hn_items)
    evaluated = [evaluate_candidate(c, policy, seen_fingerprints) for c in candidates]
    evaluated_sorted = sorted(
        evaluated,
        key=lambda x: (
            x["scores"]["relevanceTotal"] + x["scores"]["entrepreneurImportance"],
            x.get("rawScore", 0),
        ),
        reverse=True,
    )

    thresholds = policy.get("thresholds", {})
    max_accepted = int(thresholds.get("maxAcceptedSources", 5))
    min_accepted = int(thresholds.get("minAcceptedSources", 3))

    accepted = [row for row in evaluated_sorted if row.get("passed")][:max_accepted]
    rejected = [row for row in evaluated_sorted if not row.get("passed")]

    updated_history = set(seen_fingerprints)
    for row in accepted:
        updated_history.add(row["fingerprint"])
    write_history(history_path, updated_history)

    blocked = len(accepted) < min_accepted
    blocked_reason = ""
    if blocked:
        blocked_reason = (
            f"accepted_sources_below_min:{len(accepted)}<{min_accepted}"
        )

    payload = {
        "generatedAt": dt.datetime.now(dt.timezone.utc).isoformat(),
        "policyVersion": policy.get("version", 1),
        "thresholds": thresholds,
        "candidateCount": len(candidates),
        "acceptedCount": len(accepted),
        "rejectedCount": len(rejected),
        "blocked": blocked,
        "blockedReason": blocked_reason,
        "accepted": accepted,
        "rejected": rejected[:25],
    }
    save_json(out_path, payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
