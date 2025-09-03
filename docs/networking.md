# Networking & Remote Agents

`mux` speaks ACP (JSON-per-line over stdio) to editors like Zed.
This doc covers running the heavy agent remotely while Zed still talks stdio locally.

## Topology

```
Zed ──(stdio JSON lines)── mux-cli / mux-cli-relay
                     │
                     └── WebSocket/TCP ──► mux-agentd (remote)
```

- **Local mode**: `mux-cli` runs the ACP loop locally (no network).
- **Relay mode**: `mux-cli-relay` pipes stdio ⇄ WebSocket/TCP.
- **Daemon**: `mux-agentd` accepts WebSocket (and optionally stdio) and runs the same ACP loop.

## Binaries

- `mux-cli` — local ACP (what Zed launches by default).
- `mux-cli-relay` — stdio ⇄ WebSocket/TCP bridge.
- `mux-agentd` — remote WebSocket daemon.

## Quick Start

### Local (no network)
```bash
# Zed launches this:
mux-cli
```

### Relay → Daemon (same host for demo)
```bash
# terminal A (server)
cargo run -p mux-cli --bin mux-agentd -- --listen 0.0.0.0:7777

# terminal B (client relay)
cargo run -p mux-cli --bin mux-cli-relay -- --relay ws://127.0.0.1:7777
```

Point Zed to `mux-cli-relay` (see examples below).

## Transport

- **Framing**: one JSON message per line (UTF-8), end with `\n`.
- **WS Ping/Pong**: client sends ping ~every 20s; drop connection on missed pong.
- **Max frame size**: configurable; chunk large diffs into multiple messages.

## Reliability

- **Reconnect**: exponential backoff in the relay (250ms → 10s cap).
- **Bounded channels**: between stdio and WS tasks to avoid unbounded memory.
- **Backpressure**: pause reads when peer is slow; optionally drop/merge low-prio logs.

## Security

- Prefer **wss://** (TLS via rustls).
- **Auth**: bearer token via header or `Sec-WebSocket-Protocol`.
- **mTLS** (optional): client certs; pin CA on server side.
- **Workspace allowlists**: daemon enforces permitted roots for file ops.
- **Redaction**: never log secrets; scrub headers/tokens in logs.

## Configuration (proposed)

Relay client:
```bash
mux-cli-relay \
  --relay wss://agent.example:7777/agent \
  --relay-timeout 10s \
  --relay-max-frame 1MiB \
  --relay-token-file /etc/mux/token
```

Daemon:
```bash
mux-agentd \
  --listen 0.0.0.0:7777 \
  --tls-cert /etc/mux/tls/cert.pem \
  --tls-key /etc/mux/tls/key.pem \
  --token-file /etc/mux/token \
  --workspace-allow /srv/repos \
  --idle-timeout 5m
```

Environment overrides (examples):
```
MUX_RELAY_URL=…
MUX_RELAY_TOKEN=…
MUX_TLS_CERT=…
MUX_TLS_KEY=…
MUX_WORKSPACE_ALLOW=/srv/repos:/opt/code
```

## Systemd (example)

`/etc/systemd/system/mux-agentd.service`:
```ini
[Unit]
Description=mux agent daemon
After=network-online.target

[Service]
User=mux
Group=mux
ExecStart=/usr/local/bin/mux-agentd --listen 0.0.0.0:7777 --tls-cert /etc/mux/tls/cert.pem --tls-key /etc/mux/tls/key.pem --token-file /etc/mux/token --workspace-allow /srv/repos
Restart=on-failure
Environment=RUST_LOG=info

[Install]
WantedBy=multi-user.target
```

## Zed Integration

See `examples/zed/settings-local.jsonc` and `examples/zed/settings-relay.jsonc`.

## Troubleshooting

- **Handshake fails**: verify TLS cert/key and that the client trusts the CA.
- **Drops under load**: increase bounded channel sizes, enable per-message deflate.
- **High p95**: ensure model weights are staged to local NVMe on the daemon host.
