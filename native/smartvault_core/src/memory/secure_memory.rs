//! Secure memory — a byte buffer that zeroes itself on drop.
//!
//! `SecureBytes` wraps `Vec<u8>` with:
//!  - Automatic zeroing on drop via `ZeroizeOnDrop`
//!  - Optional OS-level memory locking to prevent swapping to disk
//!    (mlock on POSIX, VirtualLock on Windows)
//!
//! Usage:
//! ```rust
//! let key = SecureBytes::from_vec(vec![0x42; 32]);
//! // key is auto-zeroed when it goes out of scope
//! ```

use zeroize::{Zeroize, ZeroizeOnDrop};

// ─────────────────────────────────────────────────────────────────────────────

/// A heap-allocated byte buffer that is zeroed in memory on drop.
///
/// Sensitive data (master keys, derived keys, plaintext passwords) should
/// always be held in a `SecureBytes` rather than a plain `Vec<u8>`.
#[derive(Clone, Zeroize, ZeroizeOnDrop)]
pub struct SecureBytes {
    inner: Vec<u8>,
}

impl SecureBytes {
    /// Create a new `SecureBytes` with `len` zero bytes.
    pub fn new(len: usize) -> Self {
        SecureBytes {
            inner: vec![0u8; len],
        }
    }

    /// Wrap an existing `Vec<u8>`, taking ownership.
    /// The vec will be zeroed when this `SecureBytes` is dropped.
    pub fn from_vec(data: Vec<u8>) -> Self {
        SecureBytes { inner: data }
    }

    /// Wrap a slice by copying it.
    pub fn from_slice(data: &[u8]) -> Self {
        SecureBytes {
            inner: data.to_vec(),
        }
    }

    /// Return an immutable view of the bytes.
    pub fn as_slice(&self) -> &[u8] {
        &self.inner
    }

    /// Return the length in bytes.
    pub fn len(&self) -> usize {
        self.inner.len()
    }

    /// Returns `true` if the buffer is empty (length == 0).
    pub fn is_empty(&self) -> bool {
        self.inner.is_empty()
    }

    /// Explicitly zero and discard the contents (idempotent).
    pub fn clear(&mut self) {
        self.inner.zeroize();
    }
}

impl std::fmt::Debug for SecureBytes {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "SecureBytes([REDACTED; {}])", self.inner.len())
    }
}

// Prevent accidental Display (would leak secret bytes)
impl std::fmt::Display for SecureBytes {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "[REDACTED]")
    }
}

// ─── OS memory locking ───────────────────────────────────────────────────────

/// Attempt to lock memory pages into RAM, preventing them from being swapped.
///
/// Currently a no-op stub; full implementation (libc mlock / WinAPI VirtualLock)
/// will be added when the FFI layer is wired up and platform deps are declared.
///
/// Returns `true` if the lock succeeded, `false` if not supported.
#[allow(unused_variables)]
pub fn lock_memory(_data: &[u8]) -> bool {
    // TODO(cipherowl-6bh): implement platform mlock / VirtualLock
    false
}

/// Unlock memory pages previously locked with `lock_memory`.
#[allow(unused_variables)]
pub fn unlock_memory(_data: &[u8]) {
    // TODO(cipherowl-6bh): implement platform munlock / VirtualUnlock
}

// ─── Unit tests ──────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_from_vec_len() {
        let sb = SecureBytes::from_vec(vec![1, 2, 3, 4]);
        assert_eq!(sb.len(), 4);
        assert!(!sb.is_empty());
    }

    #[test]
    fn test_new_is_all_zeros() {
        let sb = SecureBytes::new(8);
        assert_eq!(sb.as_slice(), &[0u8; 8]);
    }

    #[test]
    fn test_from_slice() {
        let data = [0xDE, 0xAD, 0xBE, 0xEF];
        let sb = SecureBytes::from_slice(&data);
        assert_eq!(sb.as_slice(), &data);
    }

    #[test]
    fn test_clear() {
        let mut sb = SecureBytes::from_vec(vec![0xFF; 16]);
        sb.clear();
        // After clear, contents must be zero
        assert!(sb.as_slice().iter().all(|&b| b == 0));
    }

    #[test]
    fn test_debug_does_not_leak() {
        let sb = SecureBytes::from_vec(vec![0x42; 4]);
        let debug = format!("{:?}", sb);
        assert!(!debug.contains("66"), "Debug must not print raw byte values");
        assert!(debug.contains("REDACTED"));
    }

    #[test]
    fn test_display_does_not_leak() {
        let sb = SecureBytes::from_vec(vec![0x42; 4]);
        let s = format!("{}", sb);
        assert_eq!(s, "[REDACTED]");
    }

    #[test]
    fn test_zeroize_on_drop() {
        // We can't directly inspect dropped memory, but we can verify
        // that ZeroizeOnDrop doesn't panic and the struct compiles correctly.
        {
            let _sb = SecureBytes::from_vec(vec![0xFF; 32]);
        } // dropped here — zeroized
        // If we got here without a crash, the trait impl works
    }

    #[test]
    fn test_is_empty() {
        let empty = SecureBytes::new(0);
        assert!(empty.is_empty());
        let non_empty = SecureBytes::new(1);
        assert!(!non_empty.is_empty());
    }
}
