//! Public Flutter-Rust Bridge API surface.
//!
//! Every function and type in this module that is annotated with
//! `#[flutter_rust_bridge::frb]` will be included in the auto-generated
//! Dart bindings.
//!
//! Run code generation with:
//!   ```sh
//!   flutter_rust_bridge_codegen generate
//!   ```
//! This produces `lib/src/rust/frb_generated.dart` and
//! `native/smartvault_core/src/frb_generated.rs`.

use flutter_rust_bridge::frb;

use crate::crypto::{aes_gcm, argon2};
use crate::password::generator::{GeneratorConfig, GeneratorError};

use crate::crypto::x25519;

// ─── AES-256-GCM ─────────────────────────────────────────────────────────────

/// Generate a random 32-byte AES-256 key.
#[frb(sync)]
pub fn api_generate_key() -> Vec<u8> {
    aes_gcm::generate_key()
}

/// Generate a random 12-byte AES-GCM nonce.
#[frb(sync)]
pub fn api_generate_nonce() -> Vec<u8> {
    aes_gcm::generate_nonce()
}

/// Encrypt `plaintext` with `key`. Returns `[nonce(12) || ciphertext+tag]`.
///
/// Throws a Dart exception if `key` is not 32 bytes.
#[frb(sync)]
pub fn api_encrypt(plaintext: Vec<u8>, key: Vec<u8>) -> anyhow::Result<Vec<u8>> {
    aes_gcm::encrypt(&plaintext, &key).map_err(|e| anyhow::anyhow!("{}", e))
}

/// Decrypt a blob produced by `api_encrypt`.
#[frb(sync)]
pub fn api_decrypt(ciphertext_with_nonce: Vec<u8>, key: Vec<u8>) -> anyhow::Result<Vec<u8>> {
    aes_gcm::decrypt(&ciphertext_with_nonce, &key).map_err(|e| anyhow::anyhow!("{}", e))
}

// ─── Argon2id ────────────────────────────────────────────────────────────────

/// Derive a 32-byte vault encryption key from `password` and `salt`.
///
/// Parameters: t=3, m=64 MiB, p=4 (OWASP MASVS L2).
/// The `salt` must be at least 16 bytes; store it alongside the vault.
/// Async — runs on Rust worker thread to avoid blocking Flutter UI.
#[frb]
pub fn api_derive_key(password: Vec<u8>, salt: Vec<u8>) -> anyhow::Result<Vec<u8>> {
    argon2::derive_key(&password, &salt).map_err(|e| anyhow::anyhow!("{}", e))
}

/// Hash `password` using Argon2id with a random salt.
/// Returns a PHC-format string suitable for server-side auth.
/// Async — runs on Rust worker thread to avoid blocking Flutter UI.
#[frb]
pub fn api_hash_password(password: String) -> anyhow::Result<String> {
    argon2::hash_password(&password).map_err(|e| anyhow::anyhow!("{}", e))
}

/// Verify `password` against a PHC hash string.
/// Returns `true` on match, `false` on mismatch.
/// Async — runs on Rust worker thread to avoid blocking Flutter UI.
#[frb]
pub fn api_verify_password(password: String, hash: String) -> anyhow::Result<bool> {
    argon2::verify_password(&password, &hash).map_err(|e| anyhow::anyhow!("{}", e))
}

// ─── X25519 ECDH Key Exchange ────────────────────────────────────────────────

/// Generate a new X25519 private key (32 bytes).
#[frb(sync)]
pub fn api_generate_x25519_private_key() -> Vec<u8> {
    x25519::generate_private_key().to_vec()
}

/// Get the X25519 public key for a given 32-byte private key.
#[frb(sync)]
pub fn api_get_x25519_public_key(private_key: Vec<u8>) -> anyhow::Result<Vec<u8>> {
    if private_key.len() != 32 {
        return Err(anyhow::anyhow!("Private key must be 32 bytes"));
    }
    let mut arr = [0u8; 32];
    arr.copy_from_slice(&private_key);
    Ok(x25519::get_public_key(&arr).to_vec())
}

/// Derive an X25519 shared secret from your private key and peer's public key.
#[frb(sync)]
pub fn api_derive_x25519_shared_secret(private_key: Vec<u8>, peer_public_key: Vec<u8>) -> anyhow::Result<Vec<u8>> {
    if private_key.len() != 32 || peer_public_key.len() != 32 {
        return Err(anyhow::anyhow!("Keys must be 32 bytes"));
    }
    let mut priv_arr = [0u8; 32];
    priv_arr.copy_from_slice(&private_key);
    let mut pub_arr = [0u8; 32];
    pub_arr.copy_from_slice(&peer_public_key);
    Ok(x25519::derive_shared_secret(&priv_arr, &pub_arr).to_vec())
}
// ─── Password Generator ───────────────────────────────────────────────────────

/// Config for `api_generate_password`.
#[frb]
pub struct ApiGeneratorConfig {
    pub length: usize,
    pub use_lowercase: bool,
    pub use_uppercase: bool,
    pub use_digits: bool,
    pub use_symbols: bool,
}

impl From<ApiGeneratorConfig> for GeneratorConfig {
    fn from(c: ApiGeneratorConfig) -> Self {
        GeneratorConfig {
            length: c.length,
            use_lowercase: c.use_lowercase,
            use_uppercase: c.use_uppercase,
            use_digits: c.use_digits,
            use_symbols: c.use_symbols,
        }
    }
}

/// Generate a cryptographically random password.
#[frb(sync)]
pub fn api_generate_password(config: ApiGeneratorConfig) -> anyhow::Result<String> {
    crate::password::generator::generate(&config.into())
        .map_err(|e| match e {
            GeneratorError::NoCharactersEnabled => {
                anyhow::anyhow!("No character classes enabled")
            }
            GeneratorError::LengthTooShort { minimum } => {
                anyhow::anyhow!("Password length too short (minimum {})", minimum)
            }
        })
}

// ─── Utility init ─────────────────────────────────────────────────────────────

/// Called once at Flutter app startup to initialise the Rust runtime.
/// flutter_rust_bridge codegen populates this at build time.
#[frb(init)]
pub fn init_app() {}
