#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-qapish/mux}"

# ---------- helpers ----------
upsert_label () {
  local name="$1" color="$2" desc="${3:-}"
  if gh label create "$name" -R "$REPO" --color "$color" --description "$desc" >/dev/null 2>&1; then
    echo "Created label: $name"
  else
    gh label edit "$name" -R "$REPO" --color "$color" ${desc:+--description "$desc"} >/dev/null
    echo "Updated label: $name"
  fi
}

# Create milestone by title if missing. Returns nothing; we pass title to gh later.
ensure_milestone () {
  local title="$1" desc="${2:-}" state="${3:-open}"
  local found
  found="$(gh api -X GET -F state=all "repos/${REPO}/milestones" --jq ".[] | select(.title==\"${title}\") | .title" || true)"
  if [[ -z "$found" ]]; then
    gh api -X POST "repos/${REPO}/milestones" \
      -f title="$title" -f state="$state" -f description="$desc" --silent >/dev/null
    echo "Created milestone: $title"
  else
    echo "Milestone exists: $title"
  fi
}

# Create an issue under a milestone (by TITLE) with labels.
issue () {
  local title="$1"; shift
  local labels_csv="$1"; shift
  local milestone_title="$1"; shift

  # ensure milestone exists
  ensure_milestone "$milestone_title"

  local label_args=()
  IFS=',' read -ra LBL <<<"$labels_csv"
  for l in "${LBL[@]}"; do [[ -n "$l" ]] && label_args+=(-l "$l"); done

  gh issue create -R "$REPO" -t "$title" \
    --milestone "$milestone_title" \
    "${label_args[@]}" \
    -b "$(cat)"
}

echo "==> Target repo: $REPO"
echo "==> Ensuring labels…"

# Areas
upsert_label "area/acp"       "ededed" "ACP protocol + JSON-RPC/stdio"
upsert_label "area/router"    "ededed" "Model registry, routing, residency"
upsert_label "area/drivers"   "ededed" "Sidecar & embedded drivers"
upsert_label "area/fs"        "ededed" "Staging, cache, integrity"
upsert_label "area/planner"   "ededed" "Planning loop, tools, prompts"
upsert_label "area/diff"      "ededed" "Diff/patch generation & apply"
upsert_label "area/telemetry" "ededed" "Tracing, metrics, logs"
upsert_label "area/ci"        "ededed" "CI/CD, release, packaging"
upsert_label "area/security"  "ededed" "Policy, sandboxing, supply chain"

# Types & Priority
upsert_label "type/enhancement" "84b6eb" "Feature work"
upsert_label "type/bug"         "ee0701" "Defects"
upsert_label "priority/P1"      "e11d21" "High urgency"
upsert_label "priority/P2"      "eb6420" "Medium"
upsert_label "priority/P3"      "fbca04" "Low"

echo "==> Ensuring milestones…"
M_FOUNDATIONS="Foundations"
M_ACP_MVP="ACP MVP"
M_ROUTER_DRIVERS="Router & Drivers"
M_STAGING="Staging & Residency"
M_PLANNER="Planner v1"
M_TELEMETRY="Telemetry & Stability"
M_PERF="Performance Track"
M_CANDLE="Candle Driver"
M_ACP_COMPLETE="ACP Complete"
M_RELEASE="Release"
M_FUTURE="Future Work"

ensure_milestone "$M_FOUNDATIONS"        "Bootstrap, hygiene, CI"
ensure_milestone "$M_ACP_MVP"            "ACP transport + editor loop MVP"
ensure_milestone "$M_ROUTER_DRIVERS"     "Router, registry, sidecar drivers"
ensure_milestone "$M_STAGING"            "NFS→NVMe staging & GPU residency"
ensure_milestone "$M_PLANNER"            "Planner v1: context, diffs"
ensure_milestone "$M_TELEMETRY"          "Observability, limits, stability"
ensure_milestone "$M_PERF"               "Scheduler, KV, kernels, throughput"
ensure_milestone "$M_CANDLE"             "Pure-Rust inference driver"
ensure_milestone "$M_ACP_COMPLETE"       "Full ACP surface coverage"
ensure_milestone "$M_RELEASE"            "Packaging, docs, releases"
ensure_milestone "$M_FUTURE"             "Nice-to-haves & future work"

echo "==> Creating issues (grouped by milestone)…"

# ---------- Foundations
issue "Repo hygiene: CODE_OF_CONDUCT, CONTRIBUTING, SECURITY" \
      "area/ci,type/enhancement,priority/P3" "$M_FOUNDATIONS" <<'EOF'
Add baseline project docs:
- [ ] CODE_OF_CONDUCT.md
- [ ] CONTRIBUTING.md (workflow, style, PR checklist)
- [ ] SECURITY.md (reporting, supported versions)
EOF

issue "CI: Build, test, clippy -D warnings, fmt --check" \
      "area/ci,type/enhancement,priority/P2" "$M_FOUNDATIONS" <<'EOF'
Set up GitHub Actions:
- [ ] Linux x86_64 build matrix (stable)
- [ ] Cache cargo/target
- [ ] Run tests
- [ ] Run clippy with `-D warnings`
- [ ] Run `cargo fmt --check`
Artifacts (optional): debug binaries per PR.
EOF

# ---------- ACP MVP
issue "ACP transport MVP: JSON-RPC over stdio" \
      "area/acp,type/enhancement,priority/P1" "$M_ACP_MVP" <<'EOF'
Deliver ACP MVP:
- [ ] Request/response envelopes with ids and errors
- [ ] Heartbeat (`ping`/`pong`)
- [ ] Streamed progress/log events
- [ ] Backpressure-safe framing
EOF

issue "Workspace ops (minimal): read/write/apply_patch/list_files" \
      "area/acp,area/diff,type/enhancement,priority/P1" "$M_ACP_MVP" <<'EOF'
Implement editor-facing ops:
- [ ] `read_file`, `write_file`, `apply_patch`
- [ ] `list_files` (repo-scoped, obey ignore rules)
- [ ] Unit tests and golden patch tests
EOF

issue "Planner stub: synthetic plan/patch for Zed review UI" \
      "area/planner,type/enhancement,priority/P2" "$M_ACP_MVP" <<'EOF'
- [ ] Minimal planner returning a single-file synthetic patch
- [ ] Tracing spans for each ACP request
- [ ] Verify Zed Agent Panel review/apply flow
EOF

issue "Zed integration example & docs" \
      "area/acp,area/ci,type/enhancement,priority/P2" "$M_ACP_MVP" <<'EOF'
- [ ] Provide `settings.json` snippet for Zed Agent Panel
- [ ] Capture ACP logs for a demo session
- [ ] Troubleshooting section in README
EOF

# ---------- Router & Drivers
issue "Config: models.yaml schema + validator" \
      "area/router,type/enhancement,priority/P1" "$M_ROUTER_DRIVERS" <<'EOF'
Define and validate model entries:
- [ ] name, path, backend, tokenizer, quant, max_ctx
- [ ] clear error messages
- [ ] example fixtures
EOF

issue "Router core: driver trait, registry, health checks" \
      "area/router,type/enhancement,priority/P1" "$M_ROUTER_DRIVERS" <<'EOF'
- [ ] `Driver` trait with streaming API
- [ ] registry for backends
- [ ] readiness/health check contracts
- [ ] simple residency hook: `ensure_loaded` / `unload`
EOF

issue "Driver: llama.cpp (OpenAI server) with streaming" \
      "area/drivers,type/enhancement,priority/P1" "$M_ROUTER_DRIVERS" <<'EOF'
- [ ] Connect to `llama-server` in OpenAI mode
- [ ] SSE / chunked streaming to editor
- [ ] Timeout & cancellation handling
EOF

issue "Driver: vLLM sidecar (optional) with process orchestration" \
      "area/drivers,type/enhancement,priority/P3" "$M_ROUTER_DRIVERS" <<'EOF'
- [ ] Spawn/monitor vLLM server for a model
- [ ] Health/readiness probe
- [ ] Graceful shutdown
EOF

issue "Planner→model integration: streaming chat/completions" \
      "area/planner,area/drivers,type/enhancement,priority/P2" "$M_ROUTER_DRIVERS" <<'EOF'
- [ ] `ChatRequest` with system/user messages
- [ ] Token streaming to ACP events
- [ ] Backpressure and cancellation
EOF

# ---------- Staging & Residency
issue "Staging pipeline: NFS → NVMe (CAS), integrity, resume" \
      "area/fs,type/enhancement,priority/P1" "$M_STAGING" <<'EOF'
- [ ] Content-addressed store (SHA256)
- [ ] File locks, temp names, atomic move
- [ ] Resume partial downloads
- [ ] Hash/size integrity verification
EOF

issue "VRAM residency: LRU, clean unload, prewarm hooks" \
      "area/router,type/enhancement,priority/P1" "$M_STAGING" <<'EOF'
- [ ] Per-GPU LRU of active models
- [ ] Clean unload of weights & KV pools
- [ ] Pre-warm idle models policy hooks
EOF

issue "Topology awareness: GPU inventory & pinning policy" \
      "area/router,type/enhancement,priority/P2" "$M_STAGING" <<'EOF'
- [ ] CUDA/ROCm inventory probe
- [ ] Model→GPU pinning config
- [ ] Per-process isolation defaults
EOF

# ---------- Planner v1
issue "Repo context: file graph + ripgrep search" \
      "area/planner,type/enhancement,priority/P2" "$M_PLANNER" <<'EOF'
- [ ] Snapshot file graph with ignore rules
- [ ] ripgrep integration for code search
- [ ] Heuristics for language relevance
EOF

issue "Edit production: plan→multi-file unified diff + safe apply" \
      "area/diff,area/planner,type/enhancement,priority/P1" "$M_PLANNER" <<'EOF'
- [ ] Prompt templates for plan/diff production
- [ ] Multi-file unified diff generation
- [ ] Conflict-aware apply with backup/rollback
EOF

issue "Function-calling (optional): tools → ACP ops" \
      "area/planner,type/enhancement,priority/P3" "$M_PLANNER" <<'EOF'
- [ ] Tool schema: read_files, search, propose_patch, run_shell(guarded)
- [ ] Translate tool calls to ACP workspace ops
EOF

# ---------- Telemetry & Stability
issue "Observability: tracing + Prometheus metrics" \
      "area/telemetry,type/enhancement,priority/P2" "$M_TELEMETRY" <<'EOF'
- [ ] Request ids & spans per module
- [ ] Metrics: token/s, queue depth, GPU mem, p50/p95/p99
- [ ] JSON logs toggle via env
EOF

issue "Quotas, limits, and stability" \
      "area/telemetry,type/enhancement,priority/P2" "$M_TELEMETRY" <<'EOF'
- [ ] Max tokens/time per session
- [ ] Sandboxed shell runner (denylist & cwd jail)
- [ ] Retries/backoff for sidecars
- [ ] Graceful cancellation on editor disconnect
EOF

# ---------- Performance Track
issue "Scheduler (continuous/inflight batching)" \
      "area/router,type/enhancement,priority/P1" "$M_PERF" <<'EOF'
- [ ] Prefill vs decode scheduling
- [ ] Prompt dedup & prefix caching
- [ ] Bench harness for throughput/latency
EOF

issue "KV cache (paged allocator & accounting)" \
      "area/router,type/enhancement,priority/P1" "$M_PERF" <<'EOF'
- [ ] Paged KV abstraction
- [ ] Memory accounting per session/model
- [ ] Integration with residency policy
EOF

issue "Attention kernels via FFI (FlashAttention-class)" \
      "area/drivers,type/enhancement,priority/P2" "$M_PERF" <<'EOF'
- [ ] FFI to C++/CUDA kernels
- [ ] Benchmarks & golden tests
- [ ] Feature gate
EOF

# ---------- Candle Driver
issue "Candle driver: pure-Rust inference path" \
      "area/drivers,type/enhancement,priority/P2" "$M_CANDLE" <<'EOF'
- [ ] safetensors mmap + tokenizer
- [ ] Streaming + cancellation
- [ ] Reuse scheduler/KV abstractions
- [ ] Parity tests vs sidecars
EOF

# ---------- ACP Complete
issue "ACP: full surface (multi-buffer, rename/move, templates)" \
      "area/acp,type/enhancement,priority/P2" "$M_ACP_COMPLETE" <<'EOF'
- [ ] Multi-buffer edits
- [ ] Rename/move/create/delete
- [ ] Long-running task progress & cancellation
- [ ] Agent state persistence between turns
EOF

# ---------- Release
issue "Packaging & release (static builds, docs, examples)" \
      "area/ci,type/enhancement,priority/P2" "$M_RELEASE" <<'EOF'
- [ ] Static builds (musl where feasible), jemalloc toggle
- [ ] Version embedding (git sha)
- [ ] Example models.yaml and Zed settings
- [ ] Release notes + checksums + SBOM
EOF

# ---------- Future Work
issue "Benchmark suite: micro + macro SLAs" \
      "area/telemetry,type/enhancement,priority/P2" "$M_FUTURE" <<'EOF'
- [ ] Tokenization speed, prefill/decode tokens/s
- [ ] Latency per token (stream jitter)
- [ ] Repo-wide refactor timing under load
- [ ] Concurrency p50/p95/p99 targets
EOF

issue "Security & supply chain: cargo-deny, secret redaction, sandbox" \
      "area/security,type/enhancement,priority/P2" "$M_FUTURE" <<'EOF'
- [ ] cargo-deny audit
- [ ] Redact secrets in logs
- [ ] Sandboxed shell & path allowlists
- [ ] Network egress allowlist for sidecars
EOF

echo "==> Done. 🎯"
