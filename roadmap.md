
# mux — Roadmap

A practical, phased plan for building **mux**: an ACP-native model router/orchestrator in Rust, with GPU-resident model hot‑swap and multi-file editing UX via ACP.

> Legend: `[ ]` todo · `[~]` in progress · `[x]` done

---

## Phase 0 — Bootstrap & Foundations
- [ ] **Repo & scaffolding**
  - [x] Rust workspace with crates (`mux-cli`, `mux-acp`, `mux-planner`, `mux-router`, `mux-drivers/*`, `mux-fs`, `mux-diff`, `mux-config`, `mux-telemetry`, `xtask`)
  - [x] `agents.md` (contributor expectations)
  - [ ] `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`
- [ ] **Toolchain & hygiene**
  - [ ] `rust-toolchain.toml` pin & CI lint gates (`clippy -D warnings`, `fmt --check`)
  - [ ] Editor configs (`.editorconfig`, VSCode/Zed settings hints)
- [ ] **CI**
  - [ ] GitHub Actions: build matrix (linux x86_64, optional aarch64), cache, lint, test
  - [ ] CI artifact: dev binaries (debug) per PR

---

## Phase 1 — ACP MVP (Editor Loop)
- [ ] **ACP transport (stdio JSON-RPC)**
  - [ ] Define request/response envelopes, ids, error shape
  - [ ] Heartbeats: `ping` / `pong` + health
  - [ ] Progress events & logs (streamed)
- [ ] **Workspace ops (minimal)**
  - [ ] `read_file`, `write_file`, `apply_patch` (single-buffer)
  - [ ] `list_files` (scoped to repo root), basic ignore rules
- [ ] **Planning loop (stubbed)**
  - [ ] Echo/No-op planner returning a synthetic patch (proves review UI in Zed)
  - [ ] Tracing spans for each ACP request
- [ ] **Zed integration (manual)**
  - [ ] `settings.json` example for launching `mux-cli`
  - [ ] Verify Agent Panel → plan/patch review UI end-to-end

---

## Phase 2 — Model Router & Drivers (Bring-up)
- [ ] **Config & registry**
  - [ ] `models.yaml` schema + validation (names, paths, backend, tokenizer, quant, max_ctx)
  - [ ] Env & flags to choose default model, per-session overrides
- [ ] **Router core**
  - [ ] Driver trait + registry
  - [ ] Health checks / readiness gating
  - [ ] Simple residency policy (ensure_loaded/unload hooks)
- [ ] **Drivers (sidecar first)**
  - [ ] `llama.cpp` driver: OpenAI-compatible server, stream support
  - [ ] `vLLM` driver (optional for bring-up): OpenAI-compatible server (process orchestration only)
- [ ] **Planner → model**
  - [ ] Minimal chat/completions API (`ChatRequest`, streamed tokens)
  - [ ] Timeouts, cancellation, backpressure

---

## Phase 3 — Filesystem Staging & GPU Residency
- [ ] **Staging pipeline**
  - [ ] NFS → local NVMe cache (content-addressed; SHA256)
  - [ ] File locks, temp names, atomic moves, resume partials
  - [ ] Integrity verification (hashes/size)
- [ ] **Residency policy (VRAM)**
  - [ ] LRU of active models per GPU
  - [ ] Clean unload (free weights + KV pools), fragmentation avoidance
  - [ ] Pre-warm on idle policy hooks
- [ ] **Topology awareness**
  - [ ] GPU inventory (CUDA/ROCm probe)
  - [ ] Model→GPU pinning policy (cfg + runtime hints)
  - [ ] Process-level isolation per model (preferred) vs in-process

---

## Phase 4 — Planner v1 (Useful Editing)
- [ ] **Repo context**
  - [ ] File graph snapshot (ignore rules, language heuristics)
  - [ ] ripgrep integration for code search
- [ ] **Edit production**
  - [ ] Prompt templates (system/user) for plan → patch
  - [ ] Multi-file unified diff generation
  - [ ] Safe patch application (conflict-aware, backup)
- [ ] **Function-calling (optional)**
  - [ ] Define tool schema: `read_files`, `search`, `propose_patch`, `run_shell` (guarded)
  - [ ] Planner translates LLM tool calls → ACP ops
- [ ] **User UX hooks**
  - [ ] Fine-grained patch hunks; accept/skip per file
  - [ ] Progress messages & rationale summaries

---

## Phase 5 — Telemetry, Limits, and Stability
- [ ] **Observability**
  - [ ] `tracing` spans with request ids, per-module targets
  - [ ] Prometheus exporter: token/s, queue depth, GPU mem, latency p50/p95/p99
  - [ ] Structured logs (json) togglable by env
- [ ] **Quotas & safety**
  - [ ] Max tokens / time per session
  - [ ] Sandboxed shell runner (denylist & cwd jail), opt-out build flag
- [ ] **Error handling**
  - [ ] Retries/backoff for sidecars
  - [ ] Graceful cancellation on editor disconnect
  - [ ] Crash handling & core dumps opt-in

---

## Phase 6 — Performance Track
- [ ] **Serving scheduler**
  - [ ] Continuous/inflight batching (prefill vs decode scheduling)
  - [ ] Prefix caching & prompt dedup
- [ ] **KV cache**
  - [ ] Paged KV abstraction & allocator
  - [ ] Memory accounting per session/model
- [ ] **Attention kernels**
  - [ ] FlashAttention-class kernel via FFI (C++/CUDA) — gated feature
  - [ ] Benchmark harness & golden tests
- [ ] **Speculative decoding (optional)**
  - [ ] Draft model support (configurable)
  - [ ] Acceptance metrics, rollback on regressions

---

## Phase 7 — Candle Driver (Pure Rust Path)
- [ ] **Weights & tokenizer**
  - [ ] safetensors mmap, tokenizer integration (SPM/BPE)
- [ ] **Generation loop**
  - [ ] CUDA/Metal backend selection
  - [ ] Streaming, cancellation, backpressure
- [ ] **KV & batching**
  - [ ] Shared with router abstractions (reuse from Perf Track)
- [ ] **Parity tests**
  - [ ] Output diff across drivers for the same prompt
  - [ ] Throughput & latency comparison

---

## Phase 8 — ACP Feature-Complete
- [ ] **Full ACP surface**
  - [ ] Multi-buffer edits, rename/move ops
  - [ ] File templates, create/delete
  - [ ] Long-running task progress & cancellation
  - [ ] Agent state persistence between turns
- [ ] **Compatibility tests**
  - [ ] Zed ACP logs validation suite
  - [ ] Fuzz JSON-RPC framing & error recovery

---

## Phase 9 — Packaging & Release
- [ ] **Binaries**
  - [ ] Static builds (musl where feasible), GNU builds with jemalloc toggle
  - [ ] Version embeddings (`--version`, git sha)
- [ ] **Configs & examples**
  - [ ] `models.yaml` templates for common backends
  - [ ] Zed `settings.json` examples (Agent Panel)
- [ ] **Docs**
  - [ ] `README` with quickstart, troubleshooting
  - [ ] `docs/` for architecture, drivers, staging, ACP mapping
- [ ] **Release process**
  - [ ] GitHub Releases with checksums & SBOM
  - [ ] Signed artifacts

---

## Phase 10 — Nice-to-haves / Future
- [ ] **LoRA hot-attach/detach** for lightweight swaps
- [ ] **Multi-tenant quotas** (team/shared rigs)
- [ ] **MCP tool bridges** (optional) for non-ACP editors
- [ ] **GPU topology-aware scheduler** across hosts
- [ ] **Live reload** of configs & model registry
- [ ] **Pluggable auth hooks** for sidecar endpoints

---

## Benchmarks & SLAs
- [ ] **Microbenchmarks**
  - [ ] Tokenization speed
  - [ ] Prefill tokens/s, decode tokens/s
  - [ ] Latency per token (stream jitter)
- [ ] **Macrobenchmarks**
  - [ ] Repo-wide refactor completion time
  - [ ] Concurrent sessions (p50/p95 latency, error rate)
- [ ] **Target baselines**
  - [ ] Single 4090/5090: target tokens/s & p95 under load (to be set after bring-up)

---

## Security & Compliance
- [ ] Supply-chain: lockfiles, cargo-deny audit, vendor lists
- [ ] Secret handling: no secrets on disk; env-only & redaction in logs
- [ ] Sandboxed shell & path whitelists for write/apply ops
- [ ] Network egress policy for drivers (allowlist endpoints)

---

## Tracking Table (high level)
- [ ] Phase 0 — Bootstrap & Foundations
- [ ] Phase 1 — ACP MVP
- [ ] Phase 2 — Router & Drivers (bring-up)
- [ ] Phase 3 — Staging & Residency
- [ ] Phase 4 — Planner v1
- [ ] Phase 5 — Telemetry, Limits, Stability
- [ ] Phase 6 — Performance Track
- [ ] Phase 7 — Candle Driver
- [ ] Phase 8 — ACP Complete
- [ ] Phase 9 — Packaging & Release
- [ ] Phase 10 — Future
