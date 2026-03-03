# Add the 10 missing tasks identified from PROJECT_DOCUMENTATION.md

$tasks = @(
    # 1. Travel Mode
    @{
        title = "Implement Travel Mode hide vault categories at borders"
        priority = 3
        desc = "Travel Mode temporarily hides selected vault categories when crossing borders. Does NOT delete data - only hides it. User activates before travel, deactivates after. Useful when devices may be inspected at border crossings."
    },
    # 2. Geo-Fencing
    @{
        title = "Implement Geo-Fencing auto-lock outside safe zones"
        priority = 3
        desc = "Auto-lock vault when user leaves a defined geographic zone. User configures safe zones (home, office). Uses GPS location services. When device location exits safe zone, app auto-locks and requires full re-authentication."
    },
    # 3. Ed25519 Digital Signatures
    @{
        title = "Implement Ed25519 digital signatures for data integrity"
        priority = 2
        desc = "Implement Ed25519 digital signature generation and verification in Rust crate. Used to verify data integrity of encrypted vault items and shared items. Sign on encrypt, verify on decrypt. Prevents tampering with ciphertext."
    },
    # 4. Password Import/Export CSV
    @{
        title = "Implement password import export CSV Chrome Firefox Bitwarden"
        priority = 1
        desc = "Import passwords from CSV files exported by Chrome, Firefox, Bitwarden, LastPass, 1Password. Export vault to encrypted CSV. Use csv and file_picker packages. Map fields from different formats to CipherOwl schema. Encrypt imported data with MEK immediately."
    },
    # 5. LDAP/AD + SSO
    @{
        title = "Implement enterprise SSO SAML OIDC and LDAP AD integration"
        priority = 3
        desc = "Enterprise authentication: SAML 2.0 SSO, OpenID Connect (OIDC), LDAP/Active Directory integration. Allow organizations to use existing identity providers. Map enterprise groups to vault access roles."
    },
    # 6. Repository Layer (Clean Architecture)
    @{
        title = "Create Repository layer for Clean Architecture data abstraction"
        priority = 1
        desc = "Create data/repositories/ layer: VaultRepository, AuthRepository, SettingsRepository, SecurityRepository. Abstract data sources (Drift local DB + Supabase remote). BLoCs depend on repositories, not directly on DAOs or APIs. Implements offline-first with sync."
    },
    # 7. Entity/Domain Layer
    @{
        title = "Create Domain entities and use cases layer"
        priority = 1
        desc = "Create domain/entities/: VaultItem, UserProfile, SecurityScore, ShareLink, Badge, AcademyModule. Create domain/usecases/: EncryptVaultItem, DecryptVaultItem, CalculateSecurityScore, GeneratePassword. Pure Dart classes with no framework dependencies."
    },
    # 8. Replace Emoji with Rive in OnboardingScreen
    @{
        title = "Replace OnboardingScreen emoji placeholders with Rive animations"
        priority = 2
        desc = "OnboardingScreen currently uses large emoji as placeholders for 3 pages. Replace with proper Rive animations: Page 1 (owl guarding), Page 2 (encryption shield), Page 3 (biometric scan). Create or source .riv files."
    },
    # 9. zxcvbn Strength Scorer in Rust
    @{
        title = "Implement zxcvbn password strength analysis in Rust native"
        priority = 1
        desc = "Implement password strength scoring in Rust (native/smartvault_core/src/password/). Port or wrap zxcvbn algorithm for real-time strength analysis. Must support Arabic common passwords. Return score 0-4 with crack time estimate. Used by GeneratorScreen, AddEditItemScreen, SecurityBloc."
    },
    # 10. Face Cosine Similarity in Rust
    @{
        title = "Implement face embedding cosine similarity in Rust native"
        priority = 1
        desc = "Move face embedding comparison (cosine similarity) from Dart to Rust for security. Input: two 128-dim float vectors. Output: similarity score 0.0-1.0. Threshold 0.6 for match (was 0.85 in docs, adjusted). Runs in secure memory with zeroize after comparison."
    }
)

$count = 0
foreach ($t in $tasks) {
    $title = $t.title
    $priority = $t.priority
    $desc = $t.desc -replace "'", "''"
    
    # Create via bd create
    $result = bd create "$title" -p $priority -t task 2>&1 | Out-String
    Write-Host "Created: $title"
    Write-Host $result
    
    # Extract ID and add description
    if ($result -match "(cipherowl-[a-z0-9]+)") {
        $newId = $Matches[1]
        bd sql "UPDATE beads.issues SET description = '$desc' WHERE id = '$newId'" 2>$null
        Write-Host "  -> ID: $newId (description added)"
    }
    
    $count++
}
Write-Host "`nDone! Created $count new tasks."
