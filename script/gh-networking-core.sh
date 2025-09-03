#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-qapish/mux}"
M_NET="Networking & Remote Agents"

echo "==> Target repo: $REPO"

# -- helpers ---------------------------------------------------------------

upsert_label () {
  local name="$1" color="$2" desc="${3:-}"
  if gh label create "$name" -R "$REPO" --color "$color" --description "$desc" >/dev/null 2>&1; then
    echo "Created label: $name"
  else
    gh label edit "$name" -R "$REPO" --color "$color" ${desc:+--description "$desc"} >/dev/null
    echo "Updated label: $name"
  fi
}

ensure_milestone () {
  local title="$1" desc="${2:-}" state="${3:-open}"
  local found
  found="$(gh api -X GET -F state=all "repos/${REPO}/milestones" --jq ".[] | select(.title==\"${title}\") | .title" || true)"
  if [[ -z "$found" ]]; then
    gh api -X POST "repos/${REPO}/milestones" -f title="$title" -f state="$state" -f description="$desc" --silent >/dev/null
    echo "Created milestone: $title"
  else
    echo "Milestone exists: $title"
  fi
}

issue () {
  local title="$1"; shift
  local labels_csv="$1"; shift
  local milestone_title="$1"; shift

  ensure_milestone "$milestone_title"

  local label_args=()
  IFS=',' read -ra LBL <<<"$labels_csv"
  for l in "${LBL[@]}"; do [[ -n "$l" ]] && label_args+=(-l "$l"); done

  gh issue create -R "$REPO" -t "$title" \
    --milestone "$milestone_title" \
    "${label_args[@]}" \
    -b "$(cat)"
}

# -- labels & milestone ----------------------------------------------------

echo "==> Ensuring labels…"
upsert_label "area/network"   "ededed" "Relay, sockets, WS/TCP"
upsert_label "area/acp"       "ededed" "ACP protocol & stdio framing"
upsert_label "area/security"  "ededed" "Auth, TLS, sandboxing"
upsert_label "area/docs"      "ededed" "Docs & examples"
upsert_label "area/telemetry" "ededed" "Tracing, metrics, logs"
upsert_label "type/enhancement" "84b6eb" "Feature work"
upsert_label "priority/P1"      "e11d21" "High urgency"
upsert_label "priority/P2"      "eb6420" "Medium"

echo "==> Ensuring milestone…"
ensure_milestone "$M_NET" "Remote agent support: relay (stdio⇄WebSocket/TCP) and agent daemon"

# -- issues ---------------------------------------------------------------

issue "Implement mux-cli-relay: stdio ⇄ WebSocket/TCP" \
      "area/network,area/acp,type/enhancement,priority/P1" "$M_NET" <<'EOF'
Build a relay client as a separate binary:
- [ ] New bin: `mux-cli-relay` under `crates/mux-cli/src/bin/`
- [ ] Flag: `--relay <ws://|wss://|tcp://>`
- [ ] Line-delimited JSON framing both directions
- [ ] Clean close propagation (stdio <-> socket)
- [ ] Exit codes mapped to failure modes
- [ ] Example Zed `settings.json` block
EOF

issue "Implement mux-agentd: WebSocket daemon (plus stdio mode)" \
      "area/network,area/acp,type/enhancement,priority/P1" "$M_NET" <<'EOF'
Deliver a remote agent daemon:
- [ ] New bin: `mux-agentd` under `crates/mux-cli/src/bin/`
- [ ] `--listen 0.0.0.0:7777` WebSocket server
- [ ] One WS connection = one ACP session
- [ ] Optional stdio mode for local runs
- [ ] Graceful shutdown & draining
EOF

issue "TLS and authentication for the relay path" \
      "area/network,area/security,type/enhancement,priority/P1" "$M_NET" <<'EOF'
Secure the network link:
- [ ] TLS via rustls (wss://)
- [ ] Token auth (header or Sec-WebSocket-Protocol)
- [ ] Optional mTLS (client certs)
- [ ] Secret reload without restart (SIGHUP or config hot-reload)
EOF

issue "Heartbeats, reconnect, and bounded buffers" \
      "area/network,area/acp,type/enhancement,priority/P2" "$M_NET" <<'EOF'
Reliability primitives:
- [ ] WS ping/pong every 20s with timeout
- [ ] Exponential backoff reconnect in `mux-cli-relay`
- [ ] Bounded channels between stdio and WS tasks
- [ ] Pause reads if peer is slow; drop/merge low-priority logs under pressure
EOF

issue "Config & flags for networking (relay/daemon, limits)" \
      "area/network,type/enhancement,priority/P2" "$M_NET" <<'EOF'
User-facing configuration:
- [ ] Flags: `--relay`, `--listen`, timeouts, max-frame size
- [ ] Env var overrides and config validation
- [ ] Helpful error messages
EOF

issue "Docs: docs/networking.md + Zed examples" \
      "area/docs,area/network,type/enhancement,priority/P2" "$M_NET" <<'EOF'
Documentation:
- [ ] Topology diagrams (local vs relay)
- [ ] Zed `settings.json` examples
- [ ] Security notes (TLS, tokens, mTLS)
- [ ] Troubleshooting (firewalls, certs, reconnects)
EOF

issue "Integration tests for relay and daemon" \
      "area/network,area/telemetry,type/enhancement,priority/P2" "$M_NET" <<'EOF'
Test coverage:
- [ ] Loopback relay <-> daemon happy path
- [ ] Close mid-stream (client and server) with clean teardown
- [ ] Latency/jitter recording; assert no unbounded growth
- [ ] CI job to spin up ephemeral WS server and run tests
EOF

issue "Telemetry for sessions: tracing & metrics" \
      "area/telemetry,area/network,type/enhancement,priority/P2" "$M_NET" <<'EOF'
Observability:
- [ ] Tracing spans with session IDs
- [ ] Metrics: active sessions, bytes in/out, reconnects, heartbeat failures
- [ ] JSON logs with token/header redaction
EOF

issue "Security hardening: workspace allowlists & path guards" \
      "area/security,area/network,type/enhancement,priority/P2" "$M_NET" <<'EOF'
Hardening:
- [ ] Workspace root allowlist on server
- [ ] Path normalization & traversal protections
- [ ] (Optional) chroot/namespace sandbox feature gate
EOF

echo "==> Done. 🎯"
