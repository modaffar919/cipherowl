//! BIP39 mnemonic generation, validation, and seed derivation.
//!
//! Uses the `tiny-bip39` crate for standards-compliant mnemonic handling
//! with the English wordlist (2048 words, BIP39 specification).

use bip39::{Language, Mnemonic, MnemonicType, Seed};

/// Errors from BIP39 operations.
#[derive(Debug)]
pub enum Bip39Error {
    /// Unsupported word count — must be 12 or 24.
    InvalidWordCount(usize),
    /// The mnemonic phrase is invalid (bad words or checksum).
    InvalidMnemonic(String),
}

impl std::fmt::Display for Bip39Error {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Bip39Error::InvalidWordCount(n) => {
                write!(f, "Invalid word count {}: must be 12 or 24", n)
            }
            Bip39Error::InvalidMnemonic(msg) => {
                write!(f, "Invalid mnemonic: {}", msg)
            }
        }
    }
}

/// Generate a new BIP39 mnemonic phrase.
///
/// * `word_count` — 12 (128-bit entropy) or 24 (256-bit entropy).
///
/// Returns a list of English words.
pub fn generate_mnemonic(word_count: usize) -> Result<Vec<String>, Bip39Error> {
    let mtype = match word_count {
        12 => MnemonicType::Words12,
        24 => MnemonicType::Words24,
        _ => return Err(Bip39Error::InvalidWordCount(word_count)),
    };

    let mnemonic = Mnemonic::new(mtype, Language::English);
    let words: Vec<String> = mnemonic
        .phrase()
        .split_whitespace()
        .map(|w| w.to_string())
        .collect();

    Ok(words)
}

/// Validate a BIP39 mnemonic phrase.
///
/// Checks word count, wordlist membership, and checksum.
pub fn validate_mnemonic(words: &[String]) -> Result<bool, Bip39Error> {
    let phrase = words.join(" ");
    match Mnemonic::from_phrase(&phrase, Language::English) {
        Ok(_) => Ok(true),
        Err(e) => Err(Bip39Error::InvalidMnemonic(e.to_string())),
    }
}

/// Derive a 64-byte seed from a valid BIP39 mnemonic and optional passphrase.
///
/// The passphrase adds an extra layer of protection (BIP39 §5).
/// Pass an empty string for no passphrase.
pub fn mnemonic_to_seed(words: &[String], passphrase: &str) -> Result<Vec<u8>, Bip39Error> {
    let phrase = words.join(" ");
    let mnemonic = Mnemonic::from_phrase(&phrase, Language::English)
        .map_err(|e| Bip39Error::InvalidMnemonic(e.to_string()))?;

    let seed = Seed::new(&mnemonic, passphrase);
    Ok(seed.as_bytes().to_vec())
}

// ─── Unit tests ──────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_12_words() {
        let words = generate_mnemonic(12).unwrap();
        assert_eq!(words.len(), 12);
        // Each word should be non-empty
        assert!(words.iter().all(|w| !w.is_empty()));
    }

    #[test]
    fn test_generate_24_words() {
        let words = generate_mnemonic(24).unwrap();
        assert_eq!(words.len(), 24);
    }

    #[test]
    fn test_invalid_word_count() {
        assert!(generate_mnemonic(15).is_err());
        assert!(generate_mnemonic(0).is_err());
    }

    #[test]
    fn test_validate_generated_mnemonic() {
        let words = generate_mnemonic(12).unwrap();
        assert!(validate_mnemonic(&words).unwrap());
    }

    #[test]
    fn test_validate_invalid_mnemonic() {
        let bad = vec!["invalid".to_string(); 12];
        assert!(validate_mnemonic(&bad).is_err());
    }

    #[test]
    fn test_seed_derivation() {
        let words = generate_mnemonic(12).unwrap();
        let seed = mnemonic_to_seed(&words, "").unwrap();
        assert_eq!(seed.len(), 64);
    }

    #[test]
    fn test_seed_with_passphrase_differs() {
        let words = generate_mnemonic(12).unwrap();
        let seed_no_pass = mnemonic_to_seed(&words, "").unwrap();
        let seed_with_pass = mnemonic_to_seed(&words, "my-passphrase").unwrap();
        assert_ne!(seed_no_pass, seed_with_pass);
    }

    #[test]
    fn test_deterministic_seed() {
        let words = generate_mnemonic(12).unwrap();
        let seed1 = mnemonic_to_seed(&words, "test").unwrap();
        let seed2 = mnemonic_to_seed(&words, "test").unwrap();
        assert_eq!(seed1, seed2);
    }
}
