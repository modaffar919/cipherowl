#![no_main]
use libfuzzer_sys::fuzz_target;
use smartvault_core::crypto::bip39;

/// Fuzz BIP-39 mnemonic validation with arbitrary word lists.
///
/// Must NEVER panic — only return `Err` on invalid mnemonics.
fuzz_target!(|data: &[u8]| {
    // Convert fuzzed bytes into space-separated "words".
    let text = String::from_utf8_lossy(data);
    let words: Vec<String> = text.split_whitespace().map(String::from).collect();

    if words.is_empty() {
        return;
    }

    // Validate arbitrary word lists — must not panic.
    let _ = bip39::validate_mnemonic(&words);

    // Try seed derivation with fuzzed passphrase.
    let passphrase = if data.len() > 4 {
        String::from_utf8_lossy(&data[..4]).to_string()
    } else {
        String::new()
    };
    let _ = bip39::mnemonic_to_seed(&words, &passphrase);

    // Generate with fuzzed word count.
    if !data.is_empty() {
        let count = (data[0] as usize) % 50;
        let _ = bip39::generate_mnemonic(count);
    }
});
