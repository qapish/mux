use anyhow::Result;
use mux_acp::{Request, Response};
use tracing::info;

pub async fn handle(msg: Request) -> Result<Response> {
    match msg {
        Request::Ping => {
            info!("planner: received Ping");
            Ok(Response::Pong)
        }
    }
}
