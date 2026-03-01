#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
QUERY_FILE="${WORKSPACE}/config/video_queries.txt"
QUEUE_SCRIPT="${WORKSPACE}/scripts/transcription_queue.sh"
SIGNAL_GATE_SCRIPT="${WORKSPACE}/scripts/research_signal_gate.py"
POLICY_FILE="${WORKSPACE}/config/research_signal_policy.json"
TODAY="$(date +%F)"
REPORT_DIR="${WORKSPACE}/memory/research"
STATE_DIR="${WORKSPACE}/memory/research/.state"
REPORT_FILE="${REPORT_DIR}/${TODAY}-resource-harvest.md"
REJECTED_REPORT="${REPORT_DIR}/${TODAY}-rejected-sources.md"
VIDEO_JSONL="${STATE_DIR}/videos-${TODAY}.jsonl"
VIDEO_RANKED_JSON="${STATE_DIR}/videos-${TODAY}-ranked.json"
HN_JSON="${STATE_DIR}/hn-${TODAY}.json"
SIGNAL_GATE_JSON="${STATE_DIR}/signals-${TODAY}.json"
SIGNAL_HISTORY="${STATE_DIR}/accepted_source_fingerprints.txt"
SEEN_FILE="${STATE_DIR}/seen_videos.txt"
YT_ERROR_LOG="${STATE_DIR}/videos-${TODAY}-errors.log"
QUEUE_TOP="${1:-3}"

mkdir -p "$REPORT_DIR" "$STATE_DIR"
touch "$SEEN_FILE"
touch "$SIGNAL_HISTORY"
rm -f "$VIDEO_JSONL" "$VIDEO_RANKED_JSON" "$YT_ERROR_LOG" "$HN_JSON" "$SIGNAL_GATE_JSON"

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing dependency: $1" >&2
    exit 1
  fi
}

require jq
require curl
require yt-dlp
require python3

if [[ ! -f "$QUERY_FILE" ]]; then
  cat >"$QUERY_FILE" <<'EOF'
agent engineering production workflows
openai agents production workflows
ai entrepreneurship case study
ai founder systems execution
personal brand ai business strategy
automation agency systems
operator workflow design ai
EOF
fi

date_cutoff() {
  if date -v-14d +%Y%m%d >/dev/null 2>&1; then
    date -v-14d +%Y%m%d
  else
    date -d "14 days ago" +%Y%m%d
  fi
}

RECENT_CUTOFF="$(date_cutoff)"

collect_videos() {
  local q
  local tmp
  tmp="$(mktemp)"
  while IFS= read -r q; do
    [[ -z "${q// }" ]] && continue
    [[ "${q:0:1}" == "#" ]] && continue
    if ! yt-dlp --dump-json --flat-playlist --quiet "ytsearch8:${q}" >"$tmp" 2>>"$YT_ERROR_LOG"; then
      continue
    fi
    cat "$tmp" \
      | jq -c --arg query "$q" '
          {
            id: (.id // ""),
            title: (.title // ""),
            uploader: (.uploader // ""),
            channel: (.channel // ""),
            upload_date: (.upload_date // ""),
            duration: (.duration // 0),
            view_count: (.view_count // 0),
            url: ("https://www.youtube.com/watch?v=" + (.id // "")),
            query: $query
          }
          | select(.id != "" and .title != "")
        ' >>"$VIDEO_JSONL" || true
  done <"$QUERY_FILE"
  rm -f "$tmp"
}

yt_failure_reason() {
  if [[ -s "$YT_ERROR_LOG" ]]; then
    if rg -qi 'Failed to resolve|Could not resolve host|Name or service not known|nodename nor servname provided' "$YT_ERROR_LOG"; then
      echo "dns_unavailable"
      return
    fi
    if rg -qi 'HTTP Error 429|Too Many Requests|captcha|Sign in to confirm|Please sign in|rate limit' "$YT_ERROR_LOG"; then
      echo "rate_limited_or_challenged"
      return
    fi
    echo "yt_dlp_runtime_error"
    return
  fi
  echo ""
}

rank_videos() {
  jq -s --arg cutoff "$RECENT_CUTOFF" '
    map(
      .title_lc = (.title | ascii_downcase)
      | .score =
        (if .title_lc | test("agent|agentic|automation|workflow|business|revenue|ops|operator|entrepreneur|founder|brand|execution|system") then 4 else 0 end)
        + (if (.upload_date != "" and .upload_date >= $cutoff) then 3 else 0 end)
        + (if (.view_count // 0) >= 100000 then 2 else 0 end)
        + (if (.view_count // 0) >= 500000 then 2 else 0 end)
      | del(.title_lc)
    )
    | sort_by(-.score, -(.view_count // 0))
    | unique_by(.id)
    | .[:20]
  ' "$VIDEO_JSONL" >"$VIDEO_RANKED_JSON"
}

queue_top_videos() {
  local queued=0
  local line id title url slug
  while IFS= read -r line; do
    id="$(jq -r '.id' <<<"$line")"
    title="$(jq -r '.title' <<<"$line")"
    url="$(jq -r '.url' <<<"$line")"
    [[ -z "${id// }" || "${id}" == "null" ]] && continue
    if rg -qx "$id" "$SEEN_FILE" >/dev/null 2>&1; then
      continue
    fi
    slug="$(printf '%s' "$title" \
      | tr '[:upper:]' '[:lower:]' \
      | tr -cs 'a-z0-9' '-' \
      | sed 's/^-*//; s/-*$//' \
      | cut -c1-48)"
    if [[ -z "$slug" ]]; then
      slug="video-${id}"
    fi
    if bash "$QUEUE_SCRIPT" add "$url" "$slug" "$title" >/dev/null 2>&1; then
      echo "$id" >>"$SEEN_FILE"
      queued=$((queued + 1))
    fi
    [[ "$queued" -ge "$QUEUE_TOP" ]] && break
  done < <(jq -c '.accepted[] | select(.sourceType == "video")' "$SIGNAL_GATE_JSON")
  echo "$queued"
}

collect_hn() {
  local q enc
  q="$1"
  enc="${q// /%20}"
  curl -fsSL "https://hn.algolia.com/api/v1/search_by_date?query=${enc}&tags=story&hitsPerPage=30" \
    | jq -c --arg query "$q" '
      .hits
      | map(
          .title = (.title // "")
          | .title_lc = (.title | ascii_downcase)
          | .url = (.url // "")
          | .hn_url = ("https://news.ycombinator.com/item?id=" + (.objectID // ""))
          | .points = (.points // 0)
          | .comments = (.num_comments // 0)
          | .created_at = (.created_at // "")
          | .query = $query
          | .score = (.points + .comments)
        )
      | map(
          select(
            .title != ""
            and (
              .title_lc
              | test("ai|agent|automation|business|workflow|startup|entrepreneur|ops|mcp|founder|brand|distribution")
            )
            and (.score >= 4 or .comments >= 3)
          )
        )
      | map(del(.title_lc))
      | sort_by(-.score)
      | .[:6]
    '
}

collect_videos

if [[ ! -s "$VIDEO_JSONL" ]]; then
  REASON="$(yt_failure_reason)"
  {
    echo "# Resource Harvest - ${TODAY}"
    echo
    echo "## Summary"
    echo "- Harvested videos: 0"
    echo "- Queued for transcription: 0"
    echo "- HN stories captured: 0"
    echo
    if [[ -n "$REASON" ]]; then
      echo "## Failure Signal"
      echo "- reason: ${REASON}"
      echo
    fi
    echo "## Operator Notes"
    echo "- No videos discovered from yt-dlp queries in this environment."
    echo "- Fastest unblock: verify outbound DNS/network + yt-dlp access from the gateway host runtime."
    echo "- If reason=dns_unavailable, this is a network/runtime issue (not prompt quality)."
    echo "- If reason=rate_limited_or_challenged, rotate IP/session or add cooldown/retry."
  } >"$REPORT_FILE"
  echo "No videos discovered from yt-dlp queries." >&2
  printf 'harvest_status=empty report=%s\n' "$REPORT_FILE"
  exit 0
fi

rank_videos
VIDEO_COUNT="$(jq 'length' "$VIDEO_RANKED_JSON")"

HN_A="$(collect_hn "AI agents business execution" || echo '[]')"
HN_B="$(collect_hn "AI founder workflows automation" || echo '[]')"
HN_ALL="$(jq -s 'add | sort_by(-.score) | unique_by(.hn_url) | .[:10]' <(printf '%s' "$HN_A") <(printf '%s' "$HN_B"))"
printf '%s\n' "$HN_ALL" >"$HN_JSON"

if [[ ! -f "$POLICY_FILE" ]]; then
  echo "missing policy file: $POLICY_FILE" >&2
  exit 1
fi
if [[ ! -f "$SIGNAL_GATE_SCRIPT" ]]; then
  echo "missing script: $SIGNAL_GATE_SCRIPT" >&2
  exit 1
fi

python3 "$SIGNAL_GATE_SCRIPT" \
  --policy "$POLICY_FILE" \
  --videos "$VIDEO_RANKED_JSON" \
  --hn "$HN_JSON" \
  --history "$SIGNAL_HISTORY" \
  --output "$SIGNAL_GATE_JSON"

QUEUED_COUNT="$(queue_top_videos)"
ACCEPTED_COUNT="$(jq -r '.acceptedCount' "$SIGNAL_GATE_JSON")"
REJECTED_COUNT="$(jq -r '.rejectedCount' "$SIGNAL_GATE_JSON")"
BLOCKED_FLAG="$(jq -r '.blocked' "$SIGNAL_GATE_JSON")"
BLOCKED_REASON="$(jq -r '.blockedReason // ""' "$SIGNAL_GATE_JSON")"
MIN_ACCEPTED="$(jq -r '.thresholds.minAcceptedSources // 3' "$SIGNAL_GATE_JSON")"

{
  echo "# Resource Harvest - ${TODAY}"
  echo
  echo "## Summary"
  echo "- Harvested videos: ${VIDEO_COUNT}"
  echo "- Queued for transcription: ${QUEUED_COUNT}"
  echo "- HN stories captured: $(jq 'length' <<<"$HN_ALL")"
  echo "- Accepted high-signal sources: ${ACCEPTED_COUNT}"
  echo "- Rejected sources: ${REJECTED_COUNT}"
  echo
  echo "## Accepted High-Signal Sources"
  jq -r '
    .accepted[:5]
    | to_entries[]
    | "- [\((.value.title | gsub("\\|"; "/")))](\(.value.url)) | type=\(.value.sourceType) | relevance=\(.value.scores.relevanceTotal)/25 | entrepreneur=\(.value.scores.entrepreneurImportance)/25 | focus=\((.value.focusAreasMatched | join(",")))"
  ' "$SIGNAL_GATE_JSON"
  echo
  echo "## Rejected Source Highlights"
  jq -r '
    .rejected[:8]
    | to_entries[]
    | "- [\((.value.title | gsub("\\|"; "/")))](\(.value.url)) | reasons=\((.value.rejectionReasons | join(",")))"
  ' "$SIGNAL_GATE_JSON"
  echo
  echo "## Operator Notes"
  if [[ "$BLOCKED_FLAG" == "true" ]]; then
    echo "- BLOCKED: accepted high-signal sources below threshold (${ACCEPTED_COUNT}/${MIN_ACCEPTED})."
    echo "- BLOCKED reason: ${BLOCKED_REASON}"
    echo "- Fastest path: broaden query set with implementation keywords and rerun; add 2-3 primary sources (official docs/changelogs) manually."
  else
    echo "- Use accepted sources only for synthesis."
    echo "- For each accepted source, map evidence -> implication -> 48h action."
  fi
} >"$REPORT_FILE"

{
  echo "# Rejected Sources - ${TODAY}"
  echo
  echo "Purpose: explain why candidates failed strict relevance/importance gates."
  echo
  jq -r '
    .rejected
    | to_entries[]
    | "## \(.key + 1). \(.value.title)\n- URL: \(.value.url)\n- Source type: \(.value.sourceType)\n- Rejection reasons: \((.value.rejectionReasons | join(", ")))\n- Relevance: \(.value.scores.relevanceTotal)/25\n- Entrepreneur importance: \(.value.scores.entrepreneurImportance)/25\n"
  ' "$SIGNAL_GATE_JSON"
} >"$REJECTED_REPORT"

printf 'harvest_status=ok videos=%s queued=%s hn=%s report=%s\n' \
  "$VIDEO_COUNT" "$QUEUED_COUNT" "$(jq 'length' <<<"$HN_ALL")" "$REPORT_FILE"
