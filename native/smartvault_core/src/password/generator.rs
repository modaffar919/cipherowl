//! Password generator stub.
//!
//! Full implementation is tracked in a separate task (zxcvbn integration).
//! This stub exposes the public API surface so that the rest of the crate
//! can compile and be tested independently.

use rand::Rng;

// ─── Character sets ───────────────────────────────────────────────────────────

const LOWERCASE: &[u8] = b"abcdefghijklmnopqrstuvwxyz";
const UPPERCASE: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
const DIGITS:    &[u8] = b"0123456789";
const SYMBOLS:   &[u8] = b"!@#$%^&*()-_=+[]{}|;:,.<>?";

/// Configuration for password generation.
#[derive(Debug, Clone)]
pub struct GeneratorConfig {
    pub length: usize,
    pub use_lowercase: bool,
    pub use_uppercase: bool,
    pub use_digits: bool,
    pub use_symbols: bool,
}

impl Default for GeneratorConfig {
    fn default() -> Self {
        GeneratorConfig {
            length: 20,
            use_lowercase: true,
            use_uppercase: true,
            use_digits: true,
            use_symbols: true,
        }
    }
}

/// Errors returned by the generator.
#[derive(Debug, PartialEq)]
pub enum GeneratorError {
    /// All character classes are disabled.
    NoCharactersEnabled,
    /// Requested length is too short to fit one of each required class.
    LengthTooShort { minimum: usize },
}

/// Generate a cryptographically random password according to the given config.
pub fn generate(config: &GeneratorConfig) -> Result<String, GeneratorError> {
    // Build an alphabet from enabled character classes
    let mut alphabet: Vec<u8> = Vec::new();
    let mut mandatory: Vec<u8> = Vec::new(); // at least one char from each class

    if config.use_lowercase {
        alphabet.extend_from_slice(LOWERCASE);
        mandatory.push(*random_from(LOWERCASE));
    }
    if config.use_uppercase {
        alphabet.extend_from_slice(UPPERCASE);
        mandatory.push(*random_from(UPPERCASE));
    }
    if config.use_digits {
        alphabet.extend_from_slice(DIGITS);
        mandatory.push(*random_from(DIGITS));
    }
    if config.use_symbols {
        alphabet.extend_from_slice(SYMBOLS);
        mandatory.push(*random_from(SYMBOLS));
    }

    if alphabet.is_empty() {
        return Err(GeneratorError::NoCharactersEnabled);
    }
    if config.length < mandatory.len() {
        return Err(GeneratorError::LengthTooShort {
            minimum: mandatory.len(),
        });
    }

    let mut rng = rand::thread_rng();

    // Fill remainder of the buffer with random chars from full alphabet
    let extra = config.length - mandatory.len();
    let mut password: Vec<u8> = mandatory;
    for _ in 0..extra {
        let idx = rng.gen_range(0..alphabet.len());
        password.push(alphabet[idx]);
    }

    // Fisher-Yates shuffle to remove positional bias from the mandatory chars
    for i in (1..password.len()).rev() {
        let j = rng.gen_range(0..=i);
        password.swap(i, j);
    }

    Ok(String::from_utf8(password).expect("Password is always valid UTF-8 ASCII"))
}

/// Pick a random byte from a non-empty slice.
fn random_from(set: &[u8]) -> &u8 {
    let mut rng = rand::thread_rng();
    let idx = rng.gen_range(0..set.len());
    &set[idx]
}

// ─── Unit tests ──────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_length() {
        let cfg = GeneratorConfig::default();
        let pwd = generate(&cfg).unwrap();
        assert_eq!(pwd.len(), 20);
    }

    #[test]
    fn test_only_digits() {
        let cfg = GeneratorConfig {
            length: 8,
            use_lowercase: false,
            use_uppercase: false,
            use_digits: true,
            use_symbols: false,
        };
        let pwd = generate(&cfg).unwrap();
        assert!(pwd.chars().all(|c| c.is_ascii_digit()), "Expected only digits");
    }

    #[test]
    fn test_no_chars_enabled() {
        let cfg = GeneratorConfig {
            length: 8,
            use_lowercase: false,
            use_uppercase: false,
            use_digits: false,
            use_symbols: false,
        };
        assert_eq!(generate(&cfg), Err(GeneratorError::NoCharactersEnabled));
    }

    #[test]
    fn test_length_too_short() {
        // All 4 classes enabled requires length >= 4
        let cfg = GeneratorConfig {
            length: 2,
            ..Default::default()
        };
        assert!(matches!(
            generate(&cfg),
            Err(GeneratorError::LengthTooShort { .. })
        ));
    }

    #[test]
    fn test_passwords_are_different() {
        let cfg = GeneratorConfig::default();
        let p1 = generate(&cfg).unwrap();
        let p2 = generate(&cfg).unwrap();
        // Extremely unlikely to collide
        assert_ne!(p1, p2);
    }

    #[test]
    fn test_contains_required_classes() {
        let cfg = GeneratorConfig {
            length: 16,
            ..Default::default()
        };
        let pwd = generate(&cfg).unwrap();
        assert!(pwd.chars().any(|c| c.is_lowercase()), "Missing lowercase");
        assert!(pwd.chars().any(|c| c.is_uppercase()), "Missing uppercase");
        assert!(pwd.chars().any(|c| c.is_ascii_digit()), "Missing digit");
        assert!(
            pwd.chars().any(|c| !c.is_alphanumeric()),
            "Missing symbol"
        );
    }
}
