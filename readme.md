# mux

An ACP-native model router/orchestrator written in Rust.

Goals:
- Speak ACP over stdio for first-class editor integrations (e.g., Zed).
- Dynamically stage and hot-load models from network storage into GPU VRAM.
- Route requests to pluggable drivers (llama.cpp, Candle, etc.).
- Provide multi-file plans and patches for a review/apply UX.

## Getting Started

```bash
cd mux
cargo build

# Try the stub ACP loop (line-delimited JSON)
cargo run -p mux-cli
# then type a line: {"Ping":{}}
# you should see: {"Pong":{}}
```

See `fixtures/models.yaml` for an example model registry.
