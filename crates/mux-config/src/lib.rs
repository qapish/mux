use anyhow::Result;
use serde::Deserialize;

#[derive(Debug, Deserialize, Clone)]
pub struct Config {
    pub models_file: String,
}

pub fn load_from_env() -> Result<Config> {
    let path = std::env::var("MODELS_CONFIG").unwrap_or_else(|_| "fixtures/models.yaml".into());
    Ok(Config { models_file: path })
}
