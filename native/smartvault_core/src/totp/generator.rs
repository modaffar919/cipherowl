//! TOTP / HOTP code generation — RFC 6238 + RFC 4226.
//!
//! ## Algorithm (RFC 4226 HOTP)
//! ```text
//! HS     = HMAC-SHA1(K, C)          where C is an 8-byte big-endian counter
//! offset = HS[19] & 0x0f
//! P      = (HS[offset]    & 0x7f) << 24
//!        | (HS[offset+1]       ) << 16
//!        | (HS[offset+2]       ) << 8
//!        | (HS[offset+3]       )
//! code   = P mod 10^digits
//! ```
//!
//! ## Algorithm (RFC 6238 TOTP)
//! ```text
//! T = floor(unix_timestamp / period)    (period = 30 s, T0 = 0)
//! code = HOTP(K, T)
//! ```
//!
//! ## Validated against RFC 6238 Appendix B test vectors
//! Seed = b"12345678901234567890", 8 digits, SHA-1.

use data_encoding::BASE32_NOPAD;
use hmac::{Hmac, Mac};
use sha1::Sha1;

type HmacSha1 = Hmac<Sha1>;

// ─── Constants ────────────────────────────────────────────────────────────────

/// Default TOTP time step in seconds (RFC 6238 §4.1).
pub const DEFAULT_PERIOD: u64 = 30;

/// Default number of OTP digits (RFC 4226 §5.3).
pub const DEFAULT_DIGITS: u32 = 6;

// ─── Error type ───────────────────────────────────────────────────────────────

/// Errors that can occur during TOTP generation.
#[derive(Debug, PartialEq, Eq)]
pub enum TotpError {
    /// The secret is not valid Base32.
    InvalidBase32,
    /// The secret is empty.
    EmptySecret,
    /// Digits must be between 6 and 8.
    InvalidDigits,
}

impl std::fmt::Display for TotpError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            TotpError::InvalidBase32 => write!(f, "TOTP secret is not valid Base32"),
            TotpError::EmptySecret   => write!(f, "TOTP secret must not be empty"),
            TotpError::InvalidDigits => write!(f, "TOTP digits must be 6, 7, or 8"),
        }
    }
}

// ─── Core HOTP/TOTP ──────────────────────────────────────────────────────────

/// Low-level HOTP(K, counter) per RFC 4226.
///
/// * `key`     — raw secret bytes (already decoded).
/// * `counter` — 8-byte big-endian counter value.
/// * `digits`  — number of decimal digits to return (6–8).
///
/// Returns the numeric code (not zero-padded string).
pub fn hotp(key: &[u8], counter: u64, digits: u32) -> u32 {
    debug_assert!(digits >= 6 && digits <= 8, "digits must be 6–8");

    // Step 1: HMAC-SHA1
    let mut mac = HmacSha1::new_from_slice(key)
        .expect("HMAC-SHA1 accepts any key length");
    mac.update(&counter.to_be_bytes());
    let hs = mac.finalize().into_bytes(); // 20 bytes

    // Step 2: Dynamic truncation
    let offset = (hs[19] & 0x0f) as usize;
    let p: u32 = ((hs[offset]     as u32 & 0x7f) << 24)
               | ((hs[offset + 1] as u32)         << 16)
               | ((hs[offset + 2] as u32)         << 8)
               |  (hs[offset + 3] as u32);

    // Step 3: Modulo
    let modulus = 10u32.pow(digits);
    p % modulus
}

/// Low-level TOTP(K, timestamp_secs) per RFC 6238.
///
/// * `key`             — raw secret bytes.
/// * `timestamp_secs`  — current Unix time in seconds.
/// * `digits`          — 6, 7, or 8.
/// * `period`          — time step in seconds (typ. 30).
pub fn totp_raw(key: &[u8], timestamp_secs: u64, digits: u32, period: u64) -> u32 {
    let counter = timestamp_secs / period;
    hotp(key, counter, digits)
}

/// How many seconds remain in the current time step.
pub fn time_remaining(timestamp_secs: u64) -> u64 {
    DEFAULT_PERIOD - (timestamp_secs % DEFAULT_PERIOD)
}

/// The counter index for a given timestamp.
pub fn time_step(timestamp_secs: u64) -> u64 {
    timestamp_secs / DEFAULT_PERIOD
}

// ─── High-level API ──────────────────────────────────────────────────────────

/// Generate a 6-digit TOTP code from a **Base32-encoded** secret.
///
/// Uses the standard 30-second period and SHA-1 (Google Authenticator
/// compatible).
///
/// * `secret_base32`  — the Base32 secret from the QR code / otpauth URI.
/// * `timestamp_secs` — current Unix timestamp in **whole seconds**.
///
/// Returns a zero-padded 6-digit string, e.g. `"094287"`.
pub fn generate(secret_base32: &str, timestamp_secs: u64) -> Result<String, TotpError> {
    generate_custom(secret_base32, timestamp_secs, DEFAULT_DIGITS, DEFAULT_PERIOD)
}

/// Like [`generate`] but allows custom digit count and period.
pub fn generate_custom(
    secret_base32: &str,
    timestamp_secs: u64,
    digits: u32,
    period: u64,
) -> Result<String, TotpError> {
    if secret_base32.is_empty() {
        return Err(TotpError::EmptySecret);
    }
    if digits < 6 || digits > 8 {
        return Err(TotpError::InvalidDigits);
    }

    // Normalise: uppercase + strip spaces/dashes (common in otpauth URIs)
    let normalised: String = secret_base32
        .chars()
        .filter(|c| *c != ' ' && *c != '-')
        .map(|c| c.to_ascii_uppercase())
        .collect();

    let key = BASE32_NOPAD
        .decode(normalised.as_bytes())
        .map_err(|_| TotpError::InvalidBase32)?;

    let code = totp_raw(&key, timestamp_secs, digits, period);

    // Zero-pad to `digits` characters
    Ok(format!("{:0>width$}", code, width = digits as usize))
}

// ─── Tests ───────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    // RFC 6238 Appendix B test vectors (SHA-1, seed = "12345678901234567890", 8 digits)
    // https://www.rfc-editor.org/rfc/rfc6238#appendix-B
    const SEED: &[u8] = b"12345678901234567890";

    #[test]
    fn test_rfc6238_vector_t59() {
        // T = floor(59 / 30) = 1
        assert_eq!(hotp(SEED, 1, 8), 94287082);
    }

    #[test]
    fn test_rfc6238_vector_t1111111109() {
        // T = floor(1111111109 / 30) = 37037036
        assert_eq!(hotp(SEED, 37037036, 8), 7081804);
    }

    #[test]
    fn test_rfc6238_vector_t1111111111() {
        // T = floor(1111111111 / 30) = 37037037
        assert_eq!(hotp(SEED, 37037037, 8), 14050471);
    }

    #[test]
    fn test_rfc6238_vector_t1234567890() {
        // T = floor(1234567890 / 30) = 41152263
        assert_eq!(hotp(SEED, 41152263, 8), 89005924);
    }

    #[test]
    fn test_rfc6238_vector_t2000000000() {
        // T = floor(2000000000 / 30) = 66666666
        assert_eq!(hotp(SEED, 66666666, 8), 69279037);
    }

    #[test]
    fn test_rfc6238_vector_t20000000000() {
        // T = floor(20000000000 / 30) = 666666666
        assert_eq!(hotp(SEED, 666666666, 8), 65353130);
    }

    #[test]
    fn test_totp_raw_uses_correct_counter() {
        // timestamp=59 → counter=1 → same as above
        assert_eq!(totp_raw(SEED, 59, 8, 30), 94287082);
        assert_eq!(totp_raw(SEED, 1111111109, 8, 30), 7081804);
        assert_eq!(totp_raw(SEED, 1234567890, 8, 30), 89005924);
    }

    #[test]
    fn test_generate_6digits_zero_padding() {
        // Base32 of "12345678901234567890" = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"
        let secret_b32 = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ";
        // T=59 → counter=1 → 8-digit=94287082 → 6-digit=287082
        let code = generate(secret_b32, 59).unwrap();
        assert_eq!(code.len(), 6);
        assert_eq!(code, "287082");
    }

    #[test]
    fn test_generate_zero_padded_small_code() {
        // Use a secret that gives a small code at some timestamp to test zero padding
        // JBSWY3DPEHPK3PXP = base32 of "Hello!" (popular test vector for apps)
        let secret_b32 = "JBSWY3DPEHPK3PXP";
        let code = generate(secret_b32, 0).unwrap();
        assert_eq!(code.len(), 6); // must always be 6 chars
    }

    #[test]
    fn test_generate_normalises_lowercase_and_spaces() {
        let secret_lower = "gezdgnbvgy3tqojqgezdgnbvgy3tqojq";
        let secret_spaces = "GEZD GNBV GY3T QOJQ GEZD GNBV GY3T QOJQ";
        let code_lower  = generate(secret_lower,  59).unwrap();
        let code_spaces = generate(secret_spaces, 59).unwrap();
        assert_eq!(code_lower,  "287082");
        assert_eq!(code_spaces, "287082");
    }

    #[test]
    fn test_generate_error_invalid_base32() {
        let err = generate("!!!!NOT_BASE32!!!!", 0).unwrap_err();
        assert_eq!(err, TotpError::InvalidBase32);
    }

    #[test]
    fn test_generate_error_empty_secret() {
        let err = generate("", 0).unwrap_err();
        assert_eq!(err, TotpError::EmptySecret);
    }

    #[test]
    fn test_generate_error_invalid_digits() {
        let err = generate_custom("GEZDGNBVGY3TQOJQ", 0, 5, 30).unwrap_err();
        assert_eq!(err, TotpError::InvalidDigits);
        let err9 = generate_custom("GEZDGNBVGY3TQOJQ", 0, 9, 30).unwrap_err();
        assert_eq!(err9, TotpError::InvalidDigits);
    }

    #[test]
    fn test_time_remaining() {
        //  0s into step → 30s remaining
        assert_eq!(time_remaining(0),  30);
        assert_eq!(time_remaining(30), 30);
        //  1s into step → 29s remaining
        assert_eq!(time_remaining(1),  29);
        assert_eq!(time_remaining(29), 1);
    }

    #[test]
    fn test_time_step_counter() {
        assert_eq!(time_step(0),  0);
        assert_eq!(time_step(29), 0);
        assert_eq!(time_step(30), 1);
        assert_eq!(time_step(59), 1);
        assert_eq!(time_step(60), 2);
    }

    #[test]
    fn test_generate_8digit_mode() {
        let secret_b32 = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ";
        let code = generate_custom(secret_b32, 59, 8, 30).unwrap();
        assert_eq!(code.len(), 8);
        assert_eq!(code, "94287082");
    }

    #[test]
    fn test_same_timestamp_same_period_gives_same_code() {
        let secret = "JBSWY3DPEHPK3PXP";
        let t = 1234567890u64;
        let c1 = generate(secret, t).unwrap();
        let c2 = generate(secret, t).unwrap();
        assert_eq!(c1, c2);
    }

    #[test]
    fn test_adjacent_timestamps_same_period_same_code() {
        let secret = "JBSWY3DPEHPK3PXP";
        let t0 = 1234567890u64;
        let t1 = t0 + 1;   // Still in the same 30-second window
        let t_next = t0 + 30; // Next window
        let c0 = generate(secret, t0).unwrap();
        let c1 = generate(secret, t1).unwrap();
        let c_next = generate(secret, t_next).unwrap();
        assert_eq!(c0, c1);     // Same window
        assert_ne!(c0, c_next); // Adjacent windows should differ (almost certainly)
    }
}
