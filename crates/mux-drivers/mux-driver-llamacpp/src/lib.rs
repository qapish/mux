use anyhow::Result;
use futures::stream;
use mux_drivers::{Driver, ChatRequest, ChatChunk};
use mux_router::ModelSpec;
use std::sync::Arc;

pub struct LlamaCppDriver {
    _endpoint: String,
}

impl LlamaCppDriver {
    pub fn new(endpoint: String) -> Arc<Self> {
        Arc::new(Self { _endpoint: endpoint })
    }
}

#[async_trait::async_trait]
impl Driver for LlamaCppDriver {
    async fn chat_stream(
        &self,
        _spec: &ModelSpec,
        _req: ChatRequest,
    ) -> Result<futures::stream::BoxStream<'static, Result<ChatChunk>>> {
        let s = stream::iter(vec![
            Ok(ChatChunk{ text: "hello from llamacpp stub".into(), done: false }),
            Ok(ChatChunk{ text: "".into(), done: true }),
        ]);
        Ok(Box::pin(s))
    }
}
