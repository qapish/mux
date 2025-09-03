use anyhow::Result;
use futures::stream;
use mux_drivers::{ChatChunk, ChatRequest, Driver};
use mux_router::ModelSpec;
use std::sync::Arc;

pub struct CandleDriver;

impl CandleDriver {
    pub fn new() -> Arc<Self> {
        Arc::new(Self)
    }
}

#[async_trait::async_trait]
impl Driver for CandleDriver {
    async fn chat_stream(
        &self,
        _spec: &ModelSpec,
        _req: ChatRequest,
    ) -> Result<futures::stream::BoxStream<'static, Result<ChatChunk>>> {
        let s = stream::iter(vec![
            Ok(ChatChunk {
                text: "hello from candle stub".into(),
                done: false,
            }),
            Ok(ChatChunk {
                text: "".into(),
                done: true,
            }),
        ]);
        Ok(Box::pin(s))
    }
}
