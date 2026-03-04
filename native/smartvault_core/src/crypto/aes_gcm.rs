//! AES-256-GCM authenticated encryption/decryption.
//!
//! Cipher: AES-256-GCM
//! Key size: 256 bits (32 bytes)
//! Nonce size: 96 bits (12 bytes) — randomly generated per encryption
//! Tag size: 128 bits (16 bytes) — appended to ciphertext by aes-gcm crate
//!
//! Ciphertext layout: [nonce (12 bytes)] [ciphertext + tag (N + 16 bytes)]

use aes_gcm::{
    aead::{Aead, AeadCore, KeyInit, OsRng},
    Aes256Gcm, Key, Nonce,
};

/// Size constants
pub const KEY_SIZE: usize = 32;   // AES-256
pub const NONCE_SIZE: usize = 12; // GCM nonce
pub const TAG_SIZE: usize = 16;   // GCM authentication tag

/// Errors for cryptographic operations
#[derive(Debug, PartialEq)]
pub enum CryptoError {
    InvalidKeySize { expected: usize, got: usize },
    InvalidNonceSize { expected: usize, got: usize },
    EncryptionFailed,
    DecryptionFailed,
    InvalidCiphertext,
}

impl std::fmt::Display for CryptoError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            CryptoError::InvalidKeySize { expected, got } => {
                write!(f, "Invalid key size: expected {expected}, got {got}")
            }
            CryptoError::InvalidNonceSize { expected, got } => {
                write!(f, "Invalid nonce size: expected {expected}, got {got}")
            }
            CryptoError::EncryptionFailed => write!(f, "Encryption failed"),
            CryptoError::DecryptionFailed => write!(f, "Decryption failed (bad key/nonce or tampered data)"),
            CryptoError::InvalidCiphertext => write!(f, "Ciphertext too short"),
        }
    }
}

/// Generate a cryptographically random 256-bit AES key.
pub fn generate_key() -> Vec<u8> {
    let key = Aes256Gcm::generate_key(OsRng);
    key.to_vec()
}

/// Generate a cryptographically random 96-bit GCM nonce.
pub fn generate_nonce() -> Vec<u8> {
    let nonce = Aes256Gcm::generate_nonce(OsRng);
    nonce.to_vec()
}

/// Encrypt `plaintext` with AES-256-GCM.
///
/// Returns `[nonce (12 bytes)] ++ [ciphertext + tag]`
/// so the nonce travels with the ciphertext.
pub fn encrypt(plaintext: &[u8], key: &[u8]) -> Result<Vec<u8>, CryptoError> {
    if key.len() != KEY_SIZE {
        return Err(CryptoError::InvalidKeySize {
            expected: KEY_SIZE,
            got: key.len(),
        });
    }

    let key = Key::<Aes256Gcm>::from_slice(key);
    let cipher = Aes256Gcm::new(key);
    let nonce_bytes = Aes256Gcm::generate_nonce(OsRng);

    let ciphertext = cipher
        .encrypt(&nonce_bytes, plaintext)
        .map_err(|_| CryptoError::EncryptionFailed)?;

    // Prepend nonce to ciphertext
    let mut result = Vec::with_capacity(NONCE_SIZE + ciphertext.len());
    result.extend_from_slice(nonce_bytes.as_slice());
    result.extend_from_slice(&ciphertext);
    Ok(result)
}

/// Encrypt with an explicit nonce (for deterministic tests).
pub fn encrypt_with_nonce(
    plaintext: &[u8],
    key: &[u8],
    nonce: &[u8],
) -> Result<Vec<u8>, CryptoError> {
    if key.len() != KEY_SIZE {
        return Err(CryptoError::InvalidKeySize {
            expected: KEY_SIZE,
            got: key.len(),
        });
    }
    if nonce.len() != NONCE_SIZE {
        return Err(CryptoError::InvalidNonceSize {
            expected: NONCE_SIZE,
            got: nonce.len(),
        });
    }

    let key = Key::<Aes256Gcm>::from_slice(key);
    let cipher = Aes256Gcm::new(key);
    let nonce = Nonce::from_slice(nonce);

    cipher
        .encrypt(nonce, plaintext)
        .map_err(|_| CryptoError::EncryptionFailed)
}

/// Decrypt ciphertext produced by `encrypt`.
///
/// Expects `[nonce (12 bytes)] ++ [ciphertext + tag]` format.
pub fn decrypt(ciphertext_with_nonce: &[u8], key: &[u8]) -> Result<Vec<u8>, CryptoError> {
    if key.len() != KEY_SIZE {
        return Err(CryptoError::InvalidKeySize {
            expected: KEY_SIZE,
            got: key.len(),
        });
    }
    if ciphertext_with_nonce.len() < NONCE_SIZE + TAG_SIZE {
        return Err(CryptoError::InvalidCiphertext);
    }

    let (nonce_bytes, ciphertext) = ciphertext_with_nonce.split_at(NONCE_SIZE);

    let key = Key::<Aes256Gcm>::from_slice(key);
    let cipher = Aes256Gcm::new(key);
    let nonce = Nonce::from_slice(nonce_bytes);

    let plaintext = cipher
        .decrypt(nonce, ciphertext)
        .map_err(|_| CryptoError::DecryptionFailed)?;

    Ok(plaintext)
}

/// Decrypt with explicit nonce (ciphertext does NOT contain the nonce).
pub fn decrypt_with_nonce(
    ciphertext: &[u8],
    key: &[u8],
    nonce: &[u8],
) -> Result<Vec<u8>, CryptoError> {
    if key.len() != KEY_SIZE {
        return Err(CryptoError::InvalidKeySize {
            expected: KEY_SIZE,
            got: key.len(),
        });
    }
    if nonce.len() != NONCE_SIZE {
        return Err(CryptoError::InvalidNonceSize {
            expected: NONCE_SIZE,
            got: nonce.len(),
        });
    }

    let key = Key::<Aes256Gcm>::from_slice(key);
    let cipher = Aes256Gcm::new(key);
    let nonce = Nonce::from_slice(nonce);

    cipher
        .decrypt(nonce, ciphertext)
        .map_err(|_| CryptoError::DecryptionFailed)
}

// ─── Unit tests ──────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    /// NIST AES-256-GCM KAT — Vector 1
    /// Source: NIST CAVP, gcmEncryptExtIV256.rsp (Keylen=256, IVlen=96, PTlen=0, AADlen=0, Taglen=128)
    /// Key  = 0x00*32, IV = 0x00*12, PT = empty, AAD = empty
    /// Expected ciphertext+tag = just the 16-byte authentication tag
    #[test]
    fn test_nist_cavp_v1_empty_plaintext() {
        use hex_literal::hex;
        let key   = [0u8; 32];
        let nonce = [0u8; 12];
        let expected_tag = hex!("530f8afbc74536b9a963b4f1c4cb738b");

        let ct_tag = encrypt_with_nonce(b"", &key, &nonce).unwrap();
        assert_eq!(ct_tag, expected_tag, "NIST CAVP Vector 1: tag mismatch");

        // Verify decrypt also works
        let pt = decrypt_with_nonce(&ct_tag, &key, &nonce).unwrap();
        assert!(pt.is_empty());
    }

    /// NIST AES-256-GCM KAT — Vector 2
    /// Source: NIST CAVP, gcmEncryptExtIV256.rsp (Keylen=256, IVlen=96, PTlen=128, AADlen=0, Taglen=128)
    /// Key  = 0x00*32, IV = 0x00*12, PT = 0x00*16, AAD = empty
    /// Expected CT = 0xcea7403d4d606b6e074ec5d3baf39d18
    /// Expected Tag= 0xd0d1c8a799996bf0265b98b5d48ab919
    #[test]
    fn test_nist_cavp_v2_16byte_plaintext() {
        use hex_literal::hex;
        let key      = [0u8; 32];
        let nonce    = [0u8; 12];
        let pt       = [0u8; 16];
        let expected = hex!(
            "cea7403d4d606b6e074ec5d3baf39d18"  // ciphertext
            "d0d1c8a799996bf0265b98b5d48ab919"  // tag
        );

        let ct_tag = encrypt_with_nonce(&pt, &key, &nonce).unwrap();
        assert_eq!(ct_tag, expected, "NIST CAVP Vector 2: ciphertext+tag mismatch");

        // Verify decryption recovers plaintext
        let decrypted = decrypt_with_nonce(&ct_tag, &key, &nonce).unwrap();
        assert_eq!(decrypted, pt);
    }

    #[test]
    fn test_encrypt_decrypt_roundtrip() {
        let key = generate_key();
        let plaintext = b"CipherOwl military-grade secret!";
        let ciphertext = encrypt(plaintext, &key).unwrap();
        assert_ne!(&ciphertext[NONCE_SIZE..], plaintext.as_slice());
        let decrypted = decrypt(&ciphertext, &key).unwrap();
        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_nonce_is_prepended() {
        let key = generate_key();
        let ct = encrypt(b"hello", &key).unwrap();
        assert!(ct.len() >= NONCE_SIZE + "hello".len() + TAG_SIZE);
    }

    #[test]
    fn test_wrong_key_fails_decryption() {
        let key1 = generate_key();
        let key2 = generate_key();
        let ct = encrypt(b"secret", &key1).unwrap();
        let result = decrypt(&ct, &key2);
        assert_eq!(result, Err(CryptoError::DecryptionFailed));
    }

    #[test]
    fn test_tampered_ciphertext_fails() {
        let key = generate_key();
        let mut ct = encrypt(b"important data", &key).unwrap();
        // Flip a bit in the ciphertext portion
        let flip_pos = ct.len() - 1;
        ct[flip_pos] ^= 0xFF;
        let result = decrypt(&ct, &key);
        assert_eq!(result, Err(CryptoError::DecryptionFailed));
    }

    #[test]
    fn test_invalid_key_size() {
        let short_key = [0u8; 16];
        let result = encrypt(b"data", &short_key);
        assert!(matches!(result, Err(CryptoError::InvalidKeySize { .. })));
    }

    #[test]
    fn test_ciphertext_is_different_each_call() {
        let key = generate_key();
        let pt = b"same plaintext";
        let ct1 = encrypt(pt, &key).unwrap();
        let ct2 = encrypt(pt, &key).unwrap();
        // Random nonces mean ciphertext should differ
        assert_ne!(ct1, ct2);
    }

    #[test]
    fn test_generate_key_length() {
        let key = generate_key();
        assert_eq!(key.len(), KEY_SIZE);
    }

    #[test]
    fn test_generate_nonce_length() {
        let nonce = generate_nonce();
        assert_eq!(nonce.len(), NONCE_SIZE);
    }
}
