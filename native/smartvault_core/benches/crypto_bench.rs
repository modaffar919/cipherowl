use criterion::{black_box, criterion_group, criterion_main, Criterion};
use smartvault_core::crypto::{aes_gcm, argon2, ed25519, x25519};
use smartvault_core::password::strength;
use smartvault_core::totp::generator as totp;

fn bench_aes_gcm(c: &mut Criterion) {
    let key = aes_gcm::generate_key();
    let plaintext = vec![0x42u8; 1024]; // 1 KB payload

    let ciphertext = aes_gcm::encrypt(&plaintext, &key).unwrap();

    c.bench_function("aes_gcm_encrypt_1kb", |b| {
        b.iter(|| aes_gcm::encrypt(black_box(&plaintext), black_box(&key)).unwrap())
    });

    c.bench_function("aes_gcm_decrypt_1kb", |b| {
        b.iter(|| aes_gcm::decrypt(black_box(&ciphertext), black_box(&key)).unwrap())
    });

    let large = vec![0x42u8; 1024 * 1024]; // 1 MB
    c.bench_function("aes_gcm_encrypt_1mb", |b| {
        b.iter(|| aes_gcm::encrypt(black_box(&large), black_box(&key)).unwrap())
    });
}

fn bench_argon2(c: &mut Criterion) {
    let password = b"correct-horse-battery-staple";
    let salt = b"random_salt_16b!";

    c.bench_function("argon2_derive_key", |b| {
        b.iter(|| argon2::derive_key(black_box(password), black_box(salt)).unwrap())
    });

    c.bench_function("argon2_hash_password", |b| {
        b.iter(|| argon2::hash_password(black_box("TestPassword123!")).unwrap())
    });
}

fn bench_ed25519(c: &mut Criterion) {
    let signing_key = ed25519::generate_signing_key();
    let message = b"Hello, CipherOwl!";
    let signature = ed25519::sign(message, &signing_key).unwrap();
    let verifying_key = ed25519::get_verifying_key(&signing_key).unwrap();

    c.bench_function("ed25519_sign", |b| {
        b.iter(|| ed25519::sign(black_box(message), black_box(&signing_key)).unwrap())
    });

    c.bench_function("ed25519_verify", |b| {
        b.iter(|| {
            ed25519::verify(
                black_box(message),
                black_box(&signature),
                black_box(&verifying_key),
            )
            .unwrap()
        })
    });
}

fn bench_x25519(c: &mut Criterion) {
    let private_a = x25519::generate_private_key();
    let public_b = x25519::get_public_key(&x25519::generate_private_key());

    c.bench_function("x25519_key_exchange", |b| {
        b.iter(|| x25519::derive_shared_secret(black_box(&private_a), black_box(&public_b)))
    });
}

fn bench_totp(c: &mut Criterion) {
    let secret = "JBSWY3DPEHPK3PXP"; // base32 test secret
    let ts: u64 = 1_700_000_000;

    c.bench_function("totp_generate", |b| {
        b.iter(|| totp::generate(black_box(secret), black_box(ts)).unwrap())
    });
}

fn bench_password_strength(c: &mut Criterion) {
    c.bench_function("password_strength_simple", |b| {
        b.iter(|| strength::estimate_strength(black_box("password123")))
    });

    c.bench_function("password_strength_complex", |b| {
        b.iter(|| strength::estimate_strength(black_box("C0rr€ct-H0rs3-B@tt3ry-St@ple!2024")))
    });
}

criterion_group!(
    benches,
    bench_aes_gcm,
    bench_argon2,
    bench_ed25519,
    bench_x25519,
    bench_totp,
    bench_password_strength
);
criterion_main!(benches);
