#![no_main]
use libfuzzer_sys::fuzz_target;
use smartvault_core::crypto::argon2;

/// Fuzz `derive_key` with arbitrary passwords and salts.
///
/// Must NEVER panic — only return `Err` on invalid parameters.
fuzz_target!(|data: &[u8]| {
    if data.len() < 2 {
        return;
    }
    // Split data into password and salt portions.
    let split = data.len() / 2;
    let (password, salt) = data.split_at(split);

    let _ = argon2::derive_key(password, salt);
});
