#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-qapish/mux}"
M_NET="Networking & Remote Agents"

echo "==> Target repo: $REPO"

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
    gh api -X POST "repos/${REPO}/milestones" \
      -f title="$title" -f state="$state" -f description="$desc" --silent >/dev/null
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

echo "==> Ensuring labels..."
upsert_label "area/acp"       "ededed" "ACP protocol + stdio transport"
upsert_label "area/network"   "ededed" "Relay, sockets, WS/TCP"
upsert_label "area/telemetry" "ededed" "Tracing, metrics, logs"
upsert_label "area/security"  "ededed" "Auth, TLS, sandboxing"
upsert_label "area/docs"      "ededed" "Docs & examples"
upsert_label "type/enhancement" "84b6eb" "Feature work"
upsert_label "priority/P1"      "e11d21" "High urgency"
upsert_label "priority/P2"      "eb6420" "Medium"

echo "==> Ensuring milestone..."
ensure_milestone "$M_NET" "Remote agent support: relay (stdio⇄WebSocket/TCP), agent daemon, reliability & security"

echo "==> Creating issues..."

issue "Relay client in mux-cli: stdio ⇄ WebSocket/TCP" \
      "area/network,area/acp,type/enhancement,priority/P1" "$M_NET" <<'EOF'
Implement a relay mode in `mux-cli`:
- [ ] `--relay <ws://|wss://|tcp://>` flag
- [ ] Line-delimited JSON framing both directions
- [ ] Clean close propagation (stdio <-> socket)
- [ ] Basic error handling; exit codes mapped to failure modes
EOF

issue "Agent daemon mux-agentd: accept WebSocket and stdio" \
      "area/network,area/acp,type/enhancement,priority/P1" "$M_NET" <<'EOF'
Deliver a remote agent daemon:
- [ ] `--listen 0.0.0.0:7777` WebSocket server
- [ ] Optional stdio mode for local runs
- [ ] Session lifecycle (one WS == one ACP session)
- [ ] Graceful shutdown & draining
EOF

issue "TLS & authentication for WebSocket relay" \
      "area/network,area/security,type/enhancement,priority/P1" "$M_NET" <<'EOF'
Secure the relay:
- [ ] `wss://` via rustls
- [ ] Token auth (header or Sec-WebSocket-Protocol)
- [ ] Optional mTLS support
- [ ] Rotate secrets without restart (SIGHUP/reload)
EOF

issue "Heartbeats & reconnect/backoff in relay" \
      "area/network,area/acp,type/enhancement,priority/P2" "$M_NET" <<'EOF'
Improve reliability:
- [ ] WS ping/pong every 20s; drop on timeout
- [ ] Exponential backoff reconnect in `mux-cli --relay`
- [ ] Bound buffers to prevent unbounded memory growth
- [ ] Health endpoint in daemon
EOF

issue "Backpressure & flow control between stdio and socket" \
      "area/network,area/acp,type/enhancement,priority/P2" "$M_NET" <<'EOF'
Flow control:
- [ ] Bounded channels between stdio and WS tasks
- [ ] Pause reads if peer is slow
- [ ] Drop/merge low-priority logs when congested (configurable)
- [ ] Tests for head-of-line blocking scenarios
EOF

issue "Config & flags: networking options" \
      "area/network,type/enhancement,priority/P2" "$M_NET" <<'EOF'
Add configuration:
- [ ] `--relay`, `--listen`, timeouts, max-frame size
- [ ] Env overrides
- [ ] Config validation + helpful errors
EOF

issue "Docs: networking.md and Zed examples" \
      "area/docs,area/network,type/enhancement,priority/P2" "$M_NET" <<'EOF'
Author documentation:
- [ ] `docs/networking.md` (topology, flags, security)
- [ ] Zed `settings.json` examples (local vs relay)
- [ ] Troubleshooting guide (firewalls, certs)
EOF

issue "Tests: integration for relay & daemon" \
      "area/network,area/telemetry,type/enhancement,priority/P2" "$M_NET" <<'EOF'
Integration tests:
- [ ] Loopback relay (client <-> server) happy path
- [ ] Drop/close mid-stream, ensure recovery
- [ ] Latency/jitter tracking & assertions
EOF

issue "Telemetry for sessions: metrics and tracing" \
      "area/telemetry,area/network,type/enhancement,priority/P2" "$M_NET" <<'EOF'
Observability:
- [ ] Tracing spans with session IDs
- [ ] Metrics: active sessions, bytes in/out, reconnects
- [ ] JSON logs with redaction for headers/tokens
EOF

issue "Security hardening: directory allowlists & sandbox" \
      "area/security,area/network,type/enhancement,priority/P2" "$M_NET" <<'EOF'
Hardening:
- [ ] Workspace root allowlist on server
- [ ] Path normalization & traversal protections
- [ ] (Optional) chroot/namespace sandbox (feature-gated)
EOF

echo "==> Done. 🎯"
