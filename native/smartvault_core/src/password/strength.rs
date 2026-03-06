//! Password strength estimation using zxcvbn.
//!
//! Provides realistic password strength scoring (0-4) based on pattern matching,
//! dictionary attacks, and estimated crack times.

use zxcvbn::zxcvbn;

/// Result of password strength estimation.
#[derive(Debug, Clone)]
pub struct StrengthResult {
    /// Score from 0 (extremely weak) to 4 (very strong).
    pub score: u8,
    /// Estimated crack time as a human-readable string (e.g. "3 hours").
    pub crack_time_display: String,
    /// Estimated number of guesses needed (log10).
    pub guesses_log10: f64,
    /// Feedback warning message, if any.
    pub warning: String,
    /// Specific suggestions to improve the password.
    pub suggestions: Vec<String>,
}

/// Estimate password strength using the zxcvbn algorithm.
///
/// * `password` — the password to evaluate.
///
/// Returns a `StrengthResult` with score (0-4), crack time, and feedback.
pub fn estimate_strength(password: &str) -> StrengthResult {
    if password.is_empty() {
        return StrengthResult {
            score: 0,
            crack_time_display: "instant".to_string(),
            guesses_log10: 0.0,
            warning: "Password is empty".to_string(),
            suggestions: vec!["Enter a password".to_string()],
        };
    }

    let estimate = zxcvbn(password, &[]);

    let score = estimate.score().into();

    let crack_time_display = estimate
        .crack_times()
        .offline_slow_hashing_1e4_per_second()
        .to_string();

    let guesses_log10 = estimate.guesses_log10();

    let (warning, suggestions) = match estimate.feedback() {
        Some(feedback) => {
            let w = feedback
                .warning()
                .map(|w| w.to_string())
                .unwrap_or_default();
            let s: Vec<String> = feedback
                .suggestions()
                .iter()
                .map(|s| s.to_string())
                .collect();
            (w, s)
        }
        None => (String::new(), Vec::new()),
    };

    StrengthResult {
        score,
        crack_time_display,
        guesses_log10,
        warning,
        suggestions,
    }
}

// ─── Unit tests ──────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_empty_password() {
        let result = estimate_strength("");
        assert_eq!(result.score, 0);
    }

    #[test]
    fn test_weak_password() {
        let result = estimate_strength("password");
        assert!(result.score <= 1, "Common password should score low");
    }

    #[test]
    fn test_common_password() {
        let result = estimate_strength("123456");
        assert_eq!(result.score, 0);
    }

    #[test]
    fn test_strong_password() {
        let result = estimate_strength("c0rr3ct-h0rs3-b@tt3ry-st@pl3!");
        assert!(result.score >= 3, "Complex passphrase should score high");
    }

    #[test]
    fn test_very_strong_password() {
        let result = estimate_strength("Xk9#mP2$vL7@nQ4&jR8!wB5^yF3*");
        assert!(result.score >= 3, "Random-like password should score high");
    }

    #[test]
    fn test_crack_time_populated() {
        let result = estimate_strength("MyP@ssw0rd!");
        assert!(!result.crack_time_display.is_empty());
    }

    #[test]
    fn test_guesses_log10_positive_for_nonempty() {
        let result = estimate_strength("hello");
        assert!(result.guesses_log10 > 0.0);
    }
}
