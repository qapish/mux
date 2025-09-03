use anyhow::Result;
use futures::{stream, StreamExt};
use mux_drivers::{Driver, ChatRequest, ChatChunk};
use mux_router::ModelSpec;
use std::sync::Arc;

pub struct VllmDriver {
    _endpoint: String,
}

impl VllmDriver {
    pub fn new(endpoint: String) -> Arc<Self> {
        Arc::new(Self { _endpoint: endpoint })
    }
}

#[async_trait::async_trait]
impl Driver for VllmDriver {
    async fn chat_stream(
        &self,
        _spec: &ModelSpec,
        _req: ChatRequest,
    ) -> Result<futures::stream::BoxStream<'static, Result<ChatChunk>>> {
        // Stub: return a tiny stream
        let s = stream::iter(vec![
            Ok(ChatChunk{ text: "hello from vllm stub".into(), done: false }),
            Ok(ChatChunk{ text: "".into(), done: true }),
        ]);
        Ok(Box::pin(s))
    }
}
