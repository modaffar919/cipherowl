//! Argon2id key derivation function.
//!
//! Parameters (OWASP MASVS L2 / password manager grade):
//!   - Algorithm : Argon2id (hybrid, resists both side-channel and GPU attacks)
//!   - t_cost    : 3 iterations
//!   - m_cost    : 65536 KiB = 64 MiB memory
//!   - p_cost    : 4 parallel threads
//!   - output    : 32 bytes (256 bits)
//!
//! Two modes are exposed:
//!  1. `derive_key`      — deterministic KDF from (password, salt) → 32-byte key
//!  2. `hash_password`   — PHC string hash for storage (random salt)
//!  3. `verify_password` — constant-time verify against stored PHC hash

use argon2::{
    password_hash::{
        rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString,
    },
    Argon2, Algorithm, Params, Version,
};

// ── OWASP-MASVS compliant parameters ─────────────────────────────────────────
pub const ARGON2_T_COST: u32 = 3;       // iterations
pub const ARGON2_M_COST: u32 = 65536;   // 64 MiB
pub const ARGON2_P_COST: u32 = 4;       // parallelism
pub const DERIVED_KEY_LEN: usize = 32;  // 256-bit output

/// Errors for Argon2 operations
#[derive(Debug, PartialEq)]
pub enum ArgonError {
    InvalidParameters,
    HashingFailed,
    VerificationFailed,
    PasswordMismatch,
    InvalidSaltSize { expected: usize, got: usize },
}

impl std::fmt::Display for ArgonError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ArgonError::InvalidParameters => write!(f, "Invalid Argon2 parameters"),
            ArgonError::HashingFailed => write!(f, "Argon2 hashing failed"),
            ArgonError::VerificationFailed => write!(f, "Argon2 verification failed"),
            ArgonError::PasswordMismatch => write!(f, "Password does not match hash"),
            ArgonError::InvalidSaltSize { expected, got } => {
                write!(f, "Invalid salt size: expected >= {expected}, got {got}")
            }
        }
    }
}

/// Build the Argon2id instance with OWASP-MASVS parameters.
fn build_argon2() -> Result<Argon2<'static>, ArgonError> {
    let params = Params::new(ARGON2_M_COST, ARGON2_T_COST, ARGON2_P_COST, Some(DERIVED_KEY_LEN))
        .map_err(|_| ArgonError::InvalidParameters)?;
    Ok(Argon2::new(Algorithm::Argon2id, Version::V0x13, params))
}

/// Derive a 32-byte key from a password and a fixed salt.
///
/// Use this to derive the vault encryption key from the master password.
/// The salt must be stored alongside the encrypted vault.
/// Minimum salt size: 16 bytes (128 bits).
pub fn derive_key(password: &[u8], salt: &[u8]) -> Result<Vec<u8>, ArgonError> {
    if salt.len() < 16 {
        return Err(ArgonError::InvalidSaltSize {
            expected: 16,
            got: salt.len(),
        });
    }

    let argon2 = build_argon2()?;
    let mut output = vec![0u8; DERIVED_KEY_LEN];

    argon2
        .hash_password_into(password, salt, &mut output)
        .map_err(|_| ArgonError::HashingFailed)?;

    Ok(output)
}

/// Hash a password with a random salt, returning a PHC-format string.
///
/// Store this string in the database for authentication.
/// Example output: `$argon2id$v=19$m=65536,t=3,p=4$<salt>$<hash>`
pub fn hash_password(password: &str) -> Result<String, ArgonError> {
    let argon2 = build_argon2()?;
    let salt = SaltString::generate(&mut OsRng);

    let hash = argon2
        .hash_password(password.as_bytes(), &salt)
        .map_err(|_| ArgonError::HashingFailed)?
        .to_string();

    Ok(hash)
}

/// Verify a password against a previously hashed PHC string.
///
/// Returns `Ok(true)` on match, `Ok(false)` on mismatch.
/// Comparison is constant-time.
pub fn verify_password(password: &str, hash_str: &str) -> Result<bool, ArgonError> {
    let parsed = PasswordHash::new(hash_str).map_err(|_| ArgonError::VerificationFailed)?;

    let argon2 = Argon2::default();
    let result = argon2.verify_password(password.as_bytes(), &parsed);

    match result {
        Ok(_) => Ok(true),
        Err(argon2::password_hash::Error::Password) => Ok(false),
        Err(_) => Err(ArgonError::VerificationFailed),
    }
}

// ─── Unit tests ──────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_derive_key_deterministic() {
        let password = b"correct horse battery staple";
        let salt = b"cipherowl_salt16"; // exactly 16 bytes

        let key1 = derive_key(password, salt).unwrap();
        let key2 = derive_key(password, salt).unwrap();

        assert_eq!(key1, key2, "Same password+salt must produce same key");
        assert_eq!(key1.len(), DERIVED_KEY_LEN);
    }

    #[test]
    fn test_derive_key_different_passwords() {
        let salt = b"cipherowl_salt16";
        let k1 = derive_key(b"password1", salt).unwrap();
        let k2 = derive_key(b"password2", salt).unwrap();
        assert_ne!(k1, k2);
    }

    #[test]
    fn test_derive_key_different_salts() {
        let password = b"same password";
        let k1 = derive_key(password, b"salt_one________").unwrap();
        let k2 = derive_key(password, b"salt_two________").unwrap();
        assert_ne!(k1, k2);
    }

    #[test]
    fn test_derive_key_short_salt_rejected() {
        let result = derive_key(b"password", b"tooshort");
        assert!(matches!(result, Err(ArgonError::InvalidSaltSize { .. })));
    }

    #[test]
    fn test_hash_and_verify_correct_password() {
        let password = "صاحب الخزنة الآمنة";
        let hash = hash_password(password).unwrap();
        assert!(hash.starts_with("$argon2id$"));
        let ok = verify_password(password, &hash).unwrap();
        assert!(ok);
    }

    #[test]
    fn test_verify_wrong_password() {
        let hash = hash_password("correct").unwrap();
        let ok = verify_password("wrong", &hash).unwrap();
        assert!(!ok);
    }

    #[test]
    fn test_hash_is_unique_each_call() {
        // Random salt → different hashes even for same password
        let h1 = hash_password("same").unwrap();
        let h2 = hash_password("same").unwrap();
        assert_ne!(h1, h2);
    }

    // IETF test vector: Argon2id RFC 9106, Example 1
    // (Uses default params, just verifies the derive_key path doesn't panic)
    #[test]
    fn test_ietf_style_known_input() {
        let password = b"password";
        let salt     = b"somesalt12345678"; // 16 bytes
        let key = derive_key(password, salt).unwrap();
        assert_eq!(key.len(), 32);
        // Key must be non-zero
        assert!(key.iter().any(|&b| b != 0));
    }

    /// IETF RFC 9106 Section 5 — Argon2id official test vector (exact KAT).
    ///
    /// Parameters from the RFC:
    ///   Password : 0x01 × 32
    ///   Salt     : 0x02 × 16
    ///   Secret   : 0x03 × 8
    ///   Data (AD): 0x04 × 12
    ///   m = 32 KiB, t = 3, p = 4, taglen = 32
    ///
    /// Expected tag (hex):
    ///   0d640df5 8d78766c 08c037a3 4a8b53c9 d01ef045 2d75b65e b52520e9 6b01e659
    #[test]
    fn test_rfc9106_argon2id_official_vector() {
        use argon2::{Algorithm, Argon2, AssociatedData, ParamsBuilder, Version};
        use hex_literal::hex;

        let password = [0x01u8; 32];
        let salt     = [0x02u8; 16];
        let secret   = [0x03u8; 8];
        let ad_bytes = [0x04u8; 12];

        let ad = AssociatedData::new(&ad_bytes).expect("valid AD");

        let mut builder = ParamsBuilder::new();
        builder.m_cost(32);         // 32 KiB — RFC 9106 §5
        builder.t_cost(3);
        builder.p_cost(4);
        builder.output_len(32);
        builder.data(ad);
        let params = builder.build().expect("valid Argon2 params");

        let argon2 = Argon2::new_with_secret(
            &secret,
            Algorithm::Argon2id,
            Version::V0x13,
            params,
        ).expect("valid Argon2id with secret");

        let mut tag = [0u8; 32];
        argon2.hash_password_into(&password, &salt, &mut tag)
            .expect("Argon2id hash_password_into");

        let expected = hex!(
            "0d640df58d78766c08c037a34a8b53c9"
            "d01ef0452d75b65eb52520e96b01e659"
        );
        assert_eq!(tag, expected, "RFC 9106 §5 Argon2id KAT mismatch");
    }
}
