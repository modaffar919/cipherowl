//! CipherOwl SmartVault Core - Rust Cryptography Engine
//!
//! Military-grade cryptography for the CipherOwl password manager.
//! All sensitive data is encrypted with AES-256-GCM.
//! Keys are derived via Argon2id (OWASP MASVS compliant).
//! Sensitive memory is zeroed on drop via zeroize.

mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge */
pub mod crypto;
pub mod face;
pub mod memory;
pub mod password;
pub mod totp;
pub mod api;

// Re-export core API surface
pub use crypto::aes_gcm::{decrypt, encrypt, encrypt_with_nonce, decrypt_with_nonce, generate_key, generate_nonce, CryptoError};
pub use crypto::argon2::{derive_key, hash_password, verify_password, ArgonError};
pub use crypto::ed25519::{generate_signing_key, get_verifying_key, sign, verify, Ed25519Error};
pub use crypto::pbkdf2::{derive_key as derive_key_pbkdf2, PBKDF2_ITERATIONS};
pub use crypto::sharing::{encrypt_for_recipient, decrypt_from_sender, EncryptedShare, SharingError};
pub use memory::secure_memory::SecureBytes;
pub use face::embedding::{cosine_similarity, is_same_person, find_best_match, EMBEDDING_DIM, DEFAULT_THRESHOLD};
pub use totp::generator::{generate as totp_generate, generate_custom as totp_generate_custom, time_remaining as totp_time_remaining, TotpError};
pub use crypto::bip39::{generate_mnemonic, validate_mnemonic, mnemonic_to_seed, Bip39Error};
pub use password::strength::{estimate_strength, StrengthResult};
// api module re-exported for frb codegen
