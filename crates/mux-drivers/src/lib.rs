use anyhow::Result;
use async_trait::async_trait;
use futures::stream::BoxStream;
use mux_router::ModelSpec;

#[derive(Debug, Clone)]
pub struct ChatRequest {
    pub prompt: String,
}

#[derive(Debug, Clone)]
pub struct ChatChunk {
    pub text: String,
    pub done: bool,
}

#[async_trait]
pub trait Driver: Send + Sync {
    async fn ensure_loaded(&self, _spec: &ModelSpec) -> Result<()> { Ok(()) }
    async fn unload(&self, _name: &str) -> Result<()> { Ok(()) }
    async fn health(&self) -> Result<()> { Ok(()) }

    async fn chat_stream(&self, _spec: &ModelSpec, _req: ChatRequest)
        -> Result<BoxStream<'static, Result<ChatChunk>>>;
}
