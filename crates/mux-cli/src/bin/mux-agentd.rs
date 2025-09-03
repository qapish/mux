use futures::{SinkExt, StreamExt};
use tokio::net::TcpListener;
use tokio_tungstenite::tungstenite::protocol::Message;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    mux_telemetry::init();
    let listener = TcpListener::bind("0.0.0.0:7777").await?;
    tracing::info!("mux-agentd listening on 0.0.0.0:7777");

    while let Ok((stream, addr)) = listener.accept().await {
        tracing::info!("connection from {addr}");
        tokio::spawn(async move {
            let ws = tokio_tungstenite::accept_async(stream).await?;
            let (mut sink, mut source) = ws.split();

            // Echo loop for now — replace with ACP loop
            while let Some(msg) = source.next().await {
                match msg? {
                    Message::Text(s) => sink.send(Message::Text(s)).await?,
                    Message::Binary(b) => sink.send(Message::Binary(b)).await?,
                    Message::Close(c) => {
                        sink.send(Message::Close(c)).await.ok();
                        break;
                    }
                    Message::Ping(p) => sink.send(Message::Pong(p)).await?,
                    _ => {}
                }
            }
            Ok::<(), anyhow::Error>(())
        });
    }

    Ok(())
}
