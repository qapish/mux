use clap::Parser;
use futures::{SinkExt, StreamExt};
use tokio::io::{stdin, stdout};
use tokio_tungstenite::tungstenite::protocol::Message;
use tokio_util::codec::{FramedRead, FramedWrite, LinesCodec};

#[derive(Parser, Debug)]
struct Args {
    /// Relay to remote agent (ws://, wss://, or tcp://)
    #[arg(long)]
    relay: String,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    mux_telemetry::init();
    let args = Args::parse();
    relay_stdio_over_ws(&args.relay).await
}

async fn relay_stdio_over_ws(url: &str) -> anyhow::Result<()> {
    let (ws_stream, _) = tokio_tungstenite::connect_async(url).await?;
    let (mut ws_sink, mut ws_stream) = ws_stream.split();

    let mut stdin_lines = FramedRead::new(stdin(), LinesCodec::new());
    let mut stdout_lines = FramedWrite::new(stdout(), LinesCodec::new());

    // forward stdin -> WebSocket
    let fwd = async {
        while let Some(line) = stdin_lines.next().await {
            let line = line?;
            ws_sink.send(Message::Text(line)).await?;
        }
        let _ = ws_sink.send(Message::Close(None)).await;
        Ok::<_, anyhow::Error>(())
    };

    // backward WebSocket -> stdout
    let bwd = async {
        while let Some(msg) = ws_stream.next().await {
            match msg? {
                Message::Text(s) => stdout_lines.send(s).await?,
                Message::Binary(bin) => {
                    stdout_lines
                        .send(String::from_utf8_lossy(&bin).into_owned())
                        .await?
                }
                Message::Close(_) => break,
                _ => {}
            }
        }
        Ok::<_, anyhow::Error>(())
    };

    tokio::try_join!(fwd, bwd)?;
    Ok(())
}
