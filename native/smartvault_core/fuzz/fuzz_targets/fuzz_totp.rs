#![no_main]
use libfuzzer_sys::fuzz_target;
use smartvault_core::totp::generator as totp;

/// Fuzz TOTP generation with arbitrary parameters.
///
/// Must NEVER panic — only return `Err` on invalid secrets.
fuzz_target!(|data: &[u8]| {
    if data.is_empty() {
        return;
    }

    // Use the fuzzed data as a base32 "secret" string.
    let secret = String::from_utf8_lossy(data);

    let _ = totp::generate(&secret, 1_700_000_000);

    // Custom parameters with fuzzed digits/period.
    let digits = if data.len() > 1 { (data[0] % 10) as u32 } else { 6 };
    let period = if data.len() > 2 { data[1] as u64 + 1 } else { 30 };

    let _ = totp::generate_custom(&secret, 1_700_000_000, digits, period);

    // Raw TOTP with arbitrary key bytes.
    let _ = totp::totp_raw(data, 1_700_000_000, 6, 30);
});
