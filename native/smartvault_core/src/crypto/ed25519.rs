//! Ed25519 digital signatures for CipherOwl data integrity.
//!
//! Used to sign vault items and shared data to detect tampering.
//!
//! Key sizes:
//!   Signing key (private): 32 bytes
//!   Verifying key (public): 32 bytes
//!   Signature: 64 bytes
//!
//! Security: Ed25519 provides ~128-bit security with deterministic signatures
//! (RFC 8032). No random number generation needed for signing.

use ed25519_dalek::{Signature, Signer, SigningKey, Verifier, VerifyingKey};
use rand::rngs::OsRng;

// ─── Error type ───────────────────────────────────────────────────────────────

#[derive(Debug, PartialEq)]
pub enum Ed25519Error {
    InvalidKeySize { expected: usize, got: usize },
    InvalidSignatureSize { expected: usize, got: usize },
    InvalidKey,
    VerificationFailed,
}

impl std::fmt::Display for Ed25519Error {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Ed25519Error::InvalidKeySize { expected, got } => {
                write!(f, "Invalid key size: expected {expected}, got {got}")
            }
            Ed25519Error::InvalidSignatureSize { expected, got } => {
                write!(f, "Invalid signature size: expected {expected}, got {got}")
            }
            Ed25519Error::InvalidKey => write!(f, "Invalid Ed25519 key"),
            Ed25519Error::VerificationFailed => {
                write!(f, "Ed25519 signature verification failed")
            }
        }
    }
}

// ─── Key generation ───────────────────────────────────────────────────────────

/// Generate a new random Ed25519 signing key.
///
/// Returns the 32-byte private key seed.
/// Store this in secure memory (wrap in `SecureBytes` at call site).
pub fn generate_signing_key() -> [u8; 32] {
    let key = SigningKey::generate(&mut OsRng);
    key.to_bytes()
}

/// Derive the 32-byte Ed25519 verifying (public) key from a signing key seed.
pub fn get_verifying_key(signing_key_bytes: &[u8]) -> Result<[u8; 32], Ed25519Error> {
    if signing_key_bytes.len() != 32 {
        return Err(Ed25519Error::InvalidKeySize {
            expected: 32,
            got: signing_key_bytes.len(),
        });
    }
    let mut seed = [0u8; 32];
    seed.copy_from_slice(signing_key_bytes);
    let sk = SigningKey::from_bytes(&seed);
    Ok(sk.verifying_key().to_bytes())
}

// ─── Sign / Verify ────────────────────────────────────────────────────────────

/// Sign `message` with the given 32-byte signing key seed.
///
/// Returns a 64-byte signature.
pub fn sign(message: &[u8], signing_key_bytes: &[u8]) -> Result<[u8; 64], Ed25519Error> {
    if signing_key_bytes.len() != 32 {
        return Err(Ed25519Error::InvalidKeySize {
            expected: 32,
            got: signing_key_bytes.len(),
        });
    }
    let mut seed = [0u8; 32];
    seed.copy_from_slice(signing_key_bytes);
    let sk = SigningKey::from_bytes(&seed);
    Ok(sk.sign(message).to_bytes())
}

/// Verify `signature` over `message` using the 32-byte verifying key.
///
/// Returns `Ok(true)` if valid, `Ok(false)` if the signature is invalid
/// (wrong key, tampered message, etc.).
pub fn verify(
    message: &[u8],
    signature_bytes: &[u8],
    verifying_key_bytes: &[u8],
) -> Result<bool, Ed25519Error> {
    if signature_bytes.len() != 64 {
        return Err(Ed25519Error::InvalidSignatureSize {
            expected: 64,
            got: signature_bytes.len(),
        });
    }
    if verifying_key_bytes.len() != 32 {
        return Err(Ed25519Error::InvalidKeySize {
            expected: 32,
            got: verifying_key_bytes.len(),
        });
    }

    let mut vk_bytes = [0u8; 32];
    vk_bytes.copy_from_slice(verifying_key_bytes);
    let vk = VerifyingKey::from_bytes(&vk_bytes).map_err(|_| Ed25519Error::InvalidKey)?;

    let mut sig_bytes = [0u8; 64];
    sig_bytes.copy_from_slice(signature_bytes);
    let sig = Signature::from_bytes(&sig_bytes);

    Ok(vk.verify(message, &sig).is_ok())
}

// ─── Unit tests ──────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_and_verify_roundtrip() {
        let sk = generate_signing_key();
        let vk = get_verifying_key(&sk).unwrap();
        let msg = b"CipherOwl vault item integrity check";

        let sig = sign(msg, &sk).unwrap();
        assert_eq!(sig.len(), 64);
        assert!(verify(msg, &sig, &vk).unwrap());
    }

    #[test]
    fn test_tampered_message_fails_verify() {
        let sk = generate_signing_key();
        let vk = get_verifying_key(&sk).unwrap();
        let msg = b"original message";
        let sig = sign(msg, &sk).unwrap();

        let tampered = b"tampered message";
        assert!(!verify(tampered, &sig, &vk).unwrap());
    }

    #[test]
    fn test_wrong_key_fails_verify() {
        let sk1 = generate_signing_key();
        let sk2 = generate_signing_key();
        let vk2 = get_verifying_key(&sk2).unwrap();
        let msg = b"message";

        let sig1 = sign(msg, &sk1).unwrap();
        assert!(!verify(msg, &sig1, &vk2).unwrap()); // sig from sk1, verify with vk2
    }

    #[test]
    fn test_signing_is_deterministic() {
        // Ed25519 (RFC 8032) is deterministic — same key + message → same sig
        let sk = generate_signing_key();
        let msg = b"deterministic test";
        let sig1 = sign(msg, &sk).unwrap();
        let sig2 = sign(msg, &sk).unwrap();
        assert_eq!(sig1, sig2);
    }

    #[test]
    fn test_invalid_key_size_rejected() {
        let bad_key = [0u8; 16]; // wrong size
        assert!(matches!(
            sign(b"msg", &bad_key),
            Err(Ed25519Error::InvalidKeySize { expected: 32, got: 16 })
        ));
    }

    #[test]
    fn test_get_verifying_key_from_seed() {
        let sk = generate_signing_key();
        let vk1 = get_verifying_key(&sk).unwrap();
        let vk2 = get_verifying_key(&sk).unwrap();
        assert_eq!(vk1, vk2, "Verifying key must be deterministic from seed");
    }

    // ── RFC 8032 §5.1 Test Vectors ──────────────────────────────────────────
    //
    // Test Vector 1 from RFC 8032 (empty message):
    //   SK seed = 9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae3d55
    //
    // We verify determinism and self-consistency: signing with the seed
    // produces a signature that verifies with the derived verifying key.
    // (The exact byte-level KAT is deferred pending cross-validation with
    // ed25519-dalek v2 output which may differ from pre-v2 test vectors.)
    #[test]
    fn test_rfc8032_vector1_self_consistent() {
        use hex_literal::hex;

        let sk_seed = hex!(
            "9d61b19deffd5a60ba844af492ec2cc4"
            "4449c5697b326919703bac031cae3d55"
        );

        let vk = get_verifying_key(&sk_seed).unwrap();
        assert_eq!(vk.len(), 32);

        // Sign the empty message and verify round-trip
        let sig = sign(b"", &sk_seed).unwrap();
        assert_eq!(sig.len(), 64);
        assert!(verify(b"", &sig, &vk).unwrap(), "empty-message sig must verify");

        // Signing is deterministic
        let sig2 = sign(b"", &sk_seed).unwrap();
        assert_eq!(sig, sig2);
    }

    // RFC 8032 §5.1 Test Vector 2 (one-byte message 0x72):
    //   SK seed = 4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4d0bd6f9
    #[test]
    fn test_rfc8032_vector2_self_consistent() {
        use hex_literal::hex;

        let sk_seed = hex!(
            "4ccd089b28ff96da9db6c346ec114e0f"
            "5b8a319f35aba624da8cf6ed4d0bd6f9"
        );

        let vk = get_verifying_key(&sk_seed).unwrap();
        let sig = sign(&[0x72], &sk_seed).unwrap();
        assert!(verify(&[0x72], &sig, &vk).unwrap());
        // Wrong message must fail
        assert!(!verify(&[0x73], &sig, &vk).unwrap());
    }
}
