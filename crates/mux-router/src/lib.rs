use anyhow::Result;
use serde::Deserialize;
use tracing::info;

#[derive(Debug, Deserialize, Clone)]
pub struct ModelSpec {
    pub name: String,
    pub path: String,
    pub backend: String,
    pub tokenizer: String,
    pub quant: Option<String>,
    pub max_ctx: usize,
}

#[derive(Debug, Deserialize, Clone)]
pub struct ModelRegistry {
    pub models: Vec<ModelSpec>,
}

impl ModelRegistry {
    pub fn from_yaml(yaml: &str) -> Result<Self> {
        Ok(serde_yaml::from_str(yaml)?)
    }

    pub fn get(&self, name: &str) -> Option<ModelSpec> {
        self.models.iter().find(|m| m.name == name).cloned()
    }
}

pub fn init_from_file(path: &str) -> Result<ModelRegistry> {
    let yaml = std::fs::read_to_string(path)?;
    let reg = ModelRegistry::from_yaml(&yaml)?;
    info!("loaded {} model specs", reg.models.len());
    Ok(reg)
}
