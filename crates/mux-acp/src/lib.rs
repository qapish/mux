use anyhow::Result;
use serde::{Deserialize, Serialize};
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub enum Request {
    Ping,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub enum Response {
    Pong,
    Error { message: String },
}

pub struct Server<R, W> {
    reader: BufReader<R>,
    writer: W,
}

impl<R, W> Server<R, W>
where
    R: tokio::io::AsyncRead + Unpin + Send + 'static,
    W: tokio::io::AsyncWrite + Unpin + Send + 'static,
{
    pub fn new(reader: R, writer: W) -> Self {
        Self {
            reader: BufReader::new(reader),
            writer,
        }
    }

    /// Very small stub line-delimited JSON protocol to prove wiring.
    pub async fn next_request(&mut self) -> Result<Option<Request>> {
        let mut line = String::new();
        let n = self.reader.read_line(&mut line).await?;
        if n == 0 {
            return Ok(None);
        }
        let req: Request = serde_json::from_str(line.trim()).unwrap_or(Request::Ping);
        Ok(Some(req))
    }

    pub async fn respond(&mut self, resp: Response) -> Result<()> {
        let s = serde_json::to_string(&resp)?;
        self.writer.write_all(s.as_bytes()).await?;
        self.writer.write_all(b"\n").await?;
        self.writer.flush().await?;
        Ok(())
    }

    pub async fn respond_err(&mut self, e: anyhow::Error) -> Result<()> {
        self.respond(Response::Error {
            message: e.to_string(),
        })
        .await
    }
}
