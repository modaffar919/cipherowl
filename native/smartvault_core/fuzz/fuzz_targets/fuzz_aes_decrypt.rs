#![no_main]
use libfuzzer_sys::fuzz_target;
use smartvault_core::crypto::aes_gcm;

/// Fuzz `decrypt` with arbitrary ciphertext blobs.
///
/// Must NEVER panic — only return `Err` on invalid input.
fuzz_target!(|data: &[u8]| {
    // Generate a valid key for decryption attempts.
    let key = aes_gcm::generate_key();
    // Attempt to decrypt random data — should gracefully return Err.
    let _ = aes_gcm::decrypt(data, &key);

    // Also try with arbitrary key sizes.
    if data.len() >= 32 {
        let (key_slice, ct_slice) = data.split_at(32);
        let _ = aes_gcm::decrypt(ct_slice, key_slice);
    }

    // Try empty inputs.
    let _ = aes_gcm::decrypt(&[], &key);
    let _ = aes_gcm::decrypt(data, &[]);
});
