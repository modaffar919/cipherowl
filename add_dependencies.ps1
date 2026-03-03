# Add dependencies: issue_id depends_on depends_on_id
# Format: issue_id DEPENDS ON depends_on_id (i.e. depends_on_id BLOCKS issue_id)

$deps = @(
    # === EPIC-1 internal chain ===
    # 8k3 (pub get) depends on 6hi (Flutter SDK)
    @("cipherowl-8k3", "cipherowl-6hi")
    # 1kg (Android build.gradle) depends on 6hi
    @("cipherowl-1kg", "cipherowl-6hi")
    # ag6 (iOS Xcode) depends on 6hi
    @("cipherowl-ag6", "cipherowl-6hi")
    # 4ho (app_localizations) depends on 8k3
    @("cipherowl-4ho", "cipherowl-8k3")
    # zis (l10n ARB files) depends on 8k3
    @("cipherowl-zis", "cipherowl-8k3")
    # 8gi (fonts) depends on 8k3
    @("cipherowl-8gi", "cipherowl-8k3")
    # z58 (gitignore) depends on 6hi
    @("cipherowl-z58", "cipherowl-6hi")
    # 9bz (verify compiles) depends on 4ho, 1kg, 8k3, 8gi, zis
    @("cipherowl-9bz", "cipherowl-4ho")
    @("cipherowl-9bz", "cipherowl-1kg")
    @("cipherowl-9bz", "cipherowl-8k3")
    @("cipherowl-9bz", "cipherowl-8gi")
    @("cipherowl-9bz", "cipherowl-zis")

    # === EPIC-2 depends on EPIC-1 foundation ===
    # d4r (Scaffold Rust) depends on 2qj (Rust toolchain)
    @("cipherowl-d4r", "cipherowl-2qj")
    # bcz (AES-256-GCM) depends on d4r
    @("cipherowl-bcz", "cipherowl-d4r")
    # gqr (Argon2id) depends on d4r
    @("cipherowl-gqr", "cipherowl-d4r")
    # dgh (X25519) depends on d4r
    @("cipherowl-dgh", "cipherowl-d4r")
    # 6bh (secure memory) depends on d4r
    @("cipherowl-6bh", "cipherowl-d4r")
    # 1za (PBKDF2) depends on d4r
    @("cipherowl-1za", "cipherowl-d4r")
    # 0i5 (Rust tests) depends on bcz, gqr, dgh
    @("cipherowl-0i5", "cipherowl-bcz")
    @("cipherowl-0i5", "cipherowl-gqr")
    @("cipherowl-0i5", "cipherowl-dgh")
    # p6g (FFI bridge) depends on bcz, gqr, 9bz (project compiles)
    @("cipherowl-p6g", "cipherowl-bcz")
    @("cipherowl-p6g", "cipherowl-gqr")
    @("cipherowl-p6g", "cipherowl-9bz")

    # === EPIC-3 depends on EPIC-2 (crypto) + EPIC-1 ===
    # nlo (Drift schema) depends on 9bz (project compiles)
    @("cipherowl-nlo", "cipherowl-9bz")
    # 5d9 (SQLCipher) depends on nlo, p6g (FFI for key derivation)
    @("cipherowl-5d9", "cipherowl-nlo")
    @("cipherowl-5d9", "cipherowl-p6g")
    # jv1 (code generation) depends on nlo
    @("cipherowl-jv1", "cipherowl-nlo")
    # 073 (DAOs) depends on jv1
    @("cipherowl-073", "cipherowl-jv1")
    # 4ed (migration) depends on 073
    @("cipherowl-4ed", "cipherowl-073")
    # 8xg (backup/restore) depends on 073
    @("cipherowl-8xg", "cipherowl-073")

    # === EPIC-4 depends on EPIC-3 (database) ===
    # dw8 (AuthBloc) depends on 073 (DAOs), p6g (FFI)
    @("cipherowl-dw8", "cipherowl-073")
    @("cipherowl-dw8", "cipherowl-p6g")
    # gtb (VaultBloc) depends on 073
    @("cipherowl-gtb", "cipherowl-073")
    # lup (GeneratorBloc) depends on p6g (FFI for crypto)
    @("cipherowl-lup", "cipherowl-p6g")
    # yly (SecurityBloc) depends on gtb
    @("cipherowl-yly", "cipherowl-gtb")
    # 1zi (SettingsBloc) depends on 073
    @("cipherowl-1zi", "cipherowl-073")
    # yot (GamificationBloc) depends on 073
    @("cipherowl-yot", "cipherowl-073")
    # ztk (Wire BLoCs to screens) depends on dw8, gtb, lup, yly, 1zi
    @("cipherowl-ztk", "cipherowl-dw8")
    @("cipherowl-ztk", "cipherowl-gtb")
    @("cipherowl-ztk", "cipherowl-lup")
    @("cipherowl-ztk", "cipherowl-yly")
    @("cipherowl-ztk", "cipherowl-1zi")

    # === EPIC-5 depends on EPIC-2 (crypto) + EPIC-4 (BLoCs) ===
    # zig (Supabase project) - no code dependency, can start anytime
    # 6i8 (SQL schema) depends on zig
    @("cipherowl-6i8", "cipherowl-zig")
    # op4 (Supabase Auth) depends on zig, dw8 (AuthBloc)
    @("cipherowl-op4", "cipherowl-zig")
    @("cipherowl-op4", "cipherowl-dw8")
    # 8tj (RLS) depends on 6i8
    @("cipherowl-8tj", "cipherowl-6i8")
    # 2qq (zero-knowledge sync) depends on 8tj, p6g, gtb
    @("cipherowl-2qq", "cipherowl-8tj")
    @("cipherowl-2qq", "cipherowl-p6g")
    @("cipherowl-2qq", "cipherowl-gtb")
    # rhy (Edge Functions) depends on 6i8
    @("cipherowl-rhy", "cipherowl-6i8")

    # === EPIC-6 depends on EPIC-4 (AuthBloc) ===
    # qm8 (ML Kit) depends on 9bz
    @("cipherowl-qm8", "cipherowl-9bz")
    # 9ts (MobileFaceNet) depends on qm8
    @("cipherowl-9ts", "cipherowl-qm8")
    # ko8 (enrollment) depends on 9ts
    @("cipherowl-ko8", "cipherowl-9ts")
    # rtv (verification) depends on 9ts
    @("cipherowl-rtv", "cipherowl-9ts")
    # fhh (background service) depends on rtv, dw8
    @("cipherowl-fhh", "cipherowl-rtv")
    @("cipherowl-fhh", "cipherowl-dw8")

    # === EPIC-7 depends on EPIC-4 (AuthBloc) ===
    # 9rp (FIDO2 registration) depends on dw8
    @("cipherowl-9rp", "cipherowl-dw8")
    # b7k (FIDO2 auth) depends on 9rp
    @("cipherowl-b7k", "cipherowl-9rp")
    # div (intruder snapshot) depends on dw8
    @("cipherowl-div", "cipherowl-dw8")
    # dq0 (duress password) depends on dw8, gtb
    @("cipherowl-dq0", "cipherowl-dw8")
    @("cipherowl-dq0", "cipherowl-gtb")

    # === EPIC-8 depends on EPIC-2 (crypto) ===
    # 933 (TOTP generation) depends on p6g (crypto for HMAC)
    @("cipherowl-933", "cipherowl-p6g")
    # kgc (QR scanner) depends on 9bz
    @("cipherowl-kgc", "cipherowl-9bz")
    # 6jv (wire to UI) depends on 933, kgc, gtb
    @("cipherowl-6jv", "cipherowl-933")
    @("cipherowl-6jv", "cipherowl-kgc")
    @("cipherowl-6jv", "cipherowl-gtb")
    # df4 (BIP39 recovery) depends on p6g
    @("cipherowl-df4", "cipherowl-p6g")

    # === EPIC-9 depends on EPIC-4 (screens wired) ===
    # e0k (Rive owl) depends on 9bz
    @("cipherowl-e0k", "cipherowl-9bz")
    # zaq (Hero transitions) depends on ztk
    @("cipherowl-zaq", "cipherowl-ztk")
    # at2 (Lottie) depends on 9bz
    @("cipherowl-at2", "cipherowl-9bz")
    # xw9 (password strength meter) depends on lup
    @("cipherowl-xw9", "cipherowl-lup")

    # === EPIC-10 depends on EPIC-4 + EPIC-5 ===
    # bgr (score engine) depends on gtb
    @("cipherowl-bgr", "cipherowl-gtb")
    # vyv (HaveIBeenPwned) depends on p6g
    @("cipherowl-vyv", "cipherowl-p6g")
    # jtm (recommendations) depends on bgr
    @("cipherowl-jtm", "cipherowl-bgr")
    # 2tp (wire to screen) depends on bgr, vyv
    @("cipherowl-2tp", "cipherowl-bgr")
    @("cipherowl-2tp", "cipherowl-vyv")

    # === EPIC-11 depends on EPIC-4 (VaultBloc) ===
    # 26b (Android Autofill) depends on gtb
    @("cipherowl-26b", "cipherowl-gtb")
    # yqj (iOS AutoFill) depends on gtb
    @("cipherowl-yqj", "cipherowl-gtb")

    # === EPIC-12 depends on EPIC-2 + EPIC-5 ===
    # a5f (encrypted sharing) depends on dgh (X25519), op4 (Supabase Auth)
    @("cipherowl-a5f", "cipherowl-dgh")
    @("cipherowl-a5f", "cipherowl-op4")
    # obe (team vault) depends on a5f
    @("cipherowl-obe", "cipherowl-a5f")

    # === EPIC-13 depends on EPIC-4 ===
    # wnk (Firebase config) depends on 9bz
    @("cipherowl-wnk", "cipherowl-9bz")
    # 6mm (push notifications) depends on wnk
    @("cipherowl-6mm", "cipherowl-wnk")
    # 2p5 (notification center) depends on 6mm
    @("cipherowl-2p5", "cipherowl-6mm")

    # === EPIC-14 depends on EPIC-4 ===
    # kj5 (academy content) - no code dep
    # rmq (quiz system) depends on kj5
    @("cipherowl-rmq", "cipherowl-kj5")
    # p7t (badges) depends on yot (GamificationBloc)
    @("cipherowl-p7t", "cipherowl-yot")
    # 7dw (daily challenges) depends on yot
    @("cipherowl-7dw", "cipherowl-yot")

    # === EPIC-15 depends on ALL feature EPICs ===
    # dla (unit tests) depends on ztk (all BLoCs wired)
    @("cipherowl-dla", "cipherowl-ztk")
    # bbt (widget tests) depends on ztk
    @("cipherowl-bbt", "cipherowl-ztk")
    # 8ij (integration tests) depends on dla, bbt
    @("cipherowl-8ij", "cipherowl-dla")
    @("cipherowl-8ij", "cipherowl-bbt")
    # d5r (security audit) depends on 2qq (sync), fhh (biometric)
    @("cipherowl-d5r", "cipherowl-2qq")
    @("cipherowl-d5r", "cipherowl-fhh")

    # === EPIC-16 depends on EPIC-15 ===
    # j7j (release signing) depends on 9bz
    @("cipherowl-j7j", "cipherowl-9bz")
    # fce (app icons) depends on 9bz
    @("cipherowl-fce", "cipherowl-9bz")
    # jf1 (App Store listing) depends on fce
    @("cipherowl-jf1", "cipherowl-fce")
    # jsl (CI/CD) depends on dla (tests pass)
    @("cipherowl-jsl", "cipherowl-dla")
    # 179 (graduation report) depends on d5r (security audit)
    @("cipherowl-179", "cipherowl-d5r")

    # === EPIC-level dependencies ===
    # EPIC-4 admin dashboard depends on obe (team vault)
    @("cipherowl-4i7", "cipherowl-obe")
    # Browser extension depends on 26b (Android autofill first)
    @("cipherowl-x0y", "cipherowl-26b")
)

$count = 0
$errors = 0
foreach ($dep in $deps) {
    $issueId = $dep[0]
    $dependsOn = $dep[1]
    $sql = "INSERT INTO beads.dependencies (issue_id, depends_on_id, type, created_by) VALUES ('$issueId', '$dependsOn', 'blocks', 'CipherOwl Team')"
    $result = bd sql $sql 2>&1 | Out-String
    if ($result -match "error" -or $result -match "Error") {
        Write-Host "ERROR: $issueId -> $dependsOn : $result"
        $errors++
    } else {
        $count++
    }
    if ($count % 20 -eq 0 -and $count -gt 0) { Write-Host "$count dependencies added..." }
}
Write-Host "Done! Added $count dependencies ($errors errors)."
