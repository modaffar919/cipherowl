//! CipherOwl SmartVault Core - Rust Cryptography Engine
//!
//! Military-grade cryptography for the CipherOwl password manager.
//! All sensitive data is encrypted with AES-256-GCM.
//! Keys are derived via Argon2id (OWASP MASVS compliant).
//! Sensitive memory is zeroed on drop via zeroize.

mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge */
pub mod crypto;
pub mod memory;
pub mod password;
pub mod api;

// Re-export core API surface
pub use crypto::aes_gcm::{decrypt, encrypt, generate_key, generate_nonce, CryptoError};
pub use crypto::argon2::{derive_key, hash_password, verify_password, ArgonError};
pub use memory::secure_memory::SecureBytes;
// api module re-exported for frb codegen
