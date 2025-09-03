# Agents Expectations (mux)

This document defines the expectations for contributors working on `mux`, the ACP-native router/orchestrator.

## Goals
- Provide an ACP-compliant server that editors (Zed, and others) can integrate with natively.
- Allow dynamic model routing and GPU residency control, with hot-load/unload from network storage.
- Deliver a reliable, performant Rust-based system that avoids Python bottlenecks.

## Implementation Guidelines
- **Compilable state**: Every PR must build cleanly (`cargo build --workspace`) and run `cargo clippy --all-targets -- -D warnings` without emitting new warnings.
- **Tests**: New functionality should include tests where feasible. Use `cargo test` and integration tests under `mux-cli/tests` or crate-level `tests/` dirs.
- **Telemetry**: All components should emit useful tracing spans/metrics via `mux-telemetry`.
- **ACP compliance**: Message schemas, patch streaming, and progress events must follow the ACP spec. Ensure Zed’s ACP debug logs show valid traffic.
- **Drivers**: Implement new model drivers behind the `Driver` trait. Each driver crate should compile independently and be feature-gated in `mux-drivers`.
- **Filesystem staging**: All large model files must be staged from NFS to local NVMe before loading. Never attempt to stream directly from network storage into GPU memory.
- **Planner**: The planner crate should mediate LLM interactions and translate outputs into ACP operations (plans, patches, progress events). Do not hard-code editor-specific logic.
- **Configuration**: Model specs should be stored in YAML and validated by `mux-config`. Avoid environment-specific hacks—support clean config-driven behavior.

## Expectations for Agents
- **Acknowledgment**: Contributors must explicitly confirm in their PR description that they have read and understood this `agents.md` file.
- **Clarifications**: If guidance is missing or ambiguous, contributors are encouraged to ask for clarification rather than guessing.
- **Consistency**: Keep coding style consistent with Rust 2021 idioms. Run `cargo fmt` before committing.

## Out of Scope
- No experimental kernels or performance hacks should land in `main` without guard rails and benchmarks.
- No direct dependencies on Python runtimes should be introduced.

---

This file acts as the reference agreement for all contributors. Any substantial changes must be discussed in issues before merging.
