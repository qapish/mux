use anyhow::Result;
use mux_acp::{Server};
use mux_acp::Request;
use mux_telemetry as telemetry;
use tokio::io::{stdin, stdout};
use tracing::info;

#[tokio::main]
async fn main() -> Result<()> {
    telemetry::init();
    info!("mux-cli starting (stub)");

    let mut server = Server::new(stdin(), stdout());

    while let Some(msg) = server.next_request().await? {
        let resp = mux_planner::handle(msg).await?;
        server.respond(resp).await?;
    }

    Ok(())
}
