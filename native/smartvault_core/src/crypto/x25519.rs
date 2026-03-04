//! X25519 ECDH key exchange implementation for CipherOwl
//!
//! Provides public/private key generation and shared secret derivation.

use x25519_dalek::{StaticSecret, PublicKey};
use rand::rngs::OsRng;

/// Generate a new X25519 private key (StaticSecret)
pub fn generate_private_key() -> [u8; 32] {
    let secret = StaticSecret::random_from_rng(OsRng);
    secret.to_bytes()
}

/// Get the public key for a given private key
pub fn get_public_key(private_key: &[u8; 32]) -> [u8; 32] {
    let secret = StaticSecret::from(*private_key);
    let public = PublicKey::from(&secret);
    public.to_bytes()
}

/// Derive a shared secret from your private key and peer's public key
pub fn derive_shared_secret(private_key: &[u8; 32], peer_public_key: &[u8; 32]) -> [u8; 32] {
    let secret = StaticSecret::from(*private_key);
    let peer_public = PublicKey::from(*peer_public_key);
    let shared = secret.diffie_hellman(&peer_public);
    shared.to_bytes()
}

// ─── Unit tests ──────────────────────────────────────────────────────────────
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_key_generation_produces_32_bytes() {
        let priv_key = generate_private_key();
        assert_eq!(priv_key.len(), 32);
        // Should not be all zeros
        assert!(priv_key.iter().any(|&b| b != 0));
    }

    #[test]
    fn test_public_key_from_private() {
        let priv_key = generate_private_key();
        let pub_key = get_public_key(&priv_key);
        assert_eq!(pub_key.len(), 32);
        // Public key should differ from private key
        assert_ne!(priv_key, pub_key);
    }

    #[test]
    fn test_shared_secret_agreement() {
        // Alice generates keypair
        let alice_priv = generate_private_key();
        let alice_pub = get_public_key(&alice_priv);

        // Bob generates keypair
        let bob_priv = generate_private_key();
        let bob_pub = get_public_key(&bob_priv);

        // Both derive the same shared secret
        let alice_shared = derive_shared_secret(&alice_priv, &bob_pub);
        let bob_shared = derive_shared_secret(&bob_priv, &alice_pub);

        assert_eq!(alice_shared, bob_shared);
        assert_eq!(alice_shared.len(), 32);
    }

    #[test]
    fn test_different_keys_different_secrets() {
        let alice_priv = generate_private_key();
        let alice_pub = get_public_key(&alice_priv);

        let bob_priv = generate_private_key();
        let bob_pub = get_public_key(&bob_priv);

        let eve_priv = generate_private_key();

        // Eve trying with Alice's public key gets a different secret
        let legit_shared = derive_shared_secret(&bob_priv, &alice_pub);
        let eve_shared = derive_shared_secret(&eve_priv, &alice_pub);

        assert_ne!(legit_shared, eve_shared);
    }

    #[test]
    fn test_deterministic_from_same_private() {
        let priv_key = generate_private_key();
        let pub1 = get_public_key(&priv_key);
        let pub2 = get_public_key(&priv_key);
        assert_eq!(pub1, pub2);
    }
}
