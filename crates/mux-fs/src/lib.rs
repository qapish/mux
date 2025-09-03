use anyhow::Result;

pub fn ensure_local(path: &str) -> Result<String> {
    // TODO: stage from NFS to NVMe
    Ok(path.to_string())
}
