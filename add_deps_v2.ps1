# Dependencies as pipe-separated strings to avoid PowerShell array flattening
$deps = @(
    "cipherowl-8k3|cipherowl-6hi",
    "cipherowl-1kg|cipherowl-6hi",
    "cipherowl-ag6|cipherowl-6hi",
    "cipherowl-4ho|cipherowl-8k3",
    "cipherowl-zis|cipherowl-8k3",
    "cipherowl-8gi|cipherowl-8k3",
    "cipherowl-z58|cipherowl-6hi",
    "cipherowl-9bz|cipherowl-4ho",
    "cipherowl-9bz|cipherowl-1kg",
    "cipherowl-9bz|cipherowl-8k3",
    "cipherowl-9bz|cipherowl-8gi",
    "cipherowl-9bz|cipherowl-zis",
    "cipherowl-d4r|cipherowl-2qj",
    "cipherowl-bcz|cipherowl-d4r",
    "cipherowl-gqr|cipherowl-d4r",
    "cipherowl-dgh|cipherowl-d4r",
    "cipherowl-6bh|cipherowl-d4r",
    "cipherowl-1za|cipherowl-d4r",
    "cipherowl-0i5|cipherowl-bcz",
    "cipherowl-0i5|cipherowl-gqr",
    "cipherowl-0i5|cipherowl-dgh",
    "cipherowl-p6g|cipherowl-bcz",
    "cipherowl-p6g|cipherowl-gqr",
    "cipherowl-p6g|cipherowl-9bz",
    "cipherowl-nlo|cipherowl-9bz",
    "cipherowl-5d9|cipherowl-nlo",
    "cipherowl-5d9|cipherowl-p6g",
    "cipherowl-jv1|cipherowl-nlo",
    "cipherowl-073|cipherowl-jv1",
    "cipherowl-4ed|cipherowl-073",
    "cipherowl-8xg|cipherowl-073",
    "cipherowl-dw8|cipherowl-073",
    "cipherowl-dw8|cipherowl-p6g",
    "cipherowl-gtb|cipherowl-073",
    "cipherowl-lup|cipherowl-p6g",
    "cipherowl-yly|cipherowl-gtb",
    "cipherowl-1zi|cipherowl-073",
    "cipherowl-yot|cipherowl-073",
    "cipherowl-ztk|cipherowl-dw8",
    "cipherowl-ztk|cipherowl-gtb",
    "cipherowl-ztk|cipherowl-lup",
    "cipherowl-ztk|cipherowl-yly",
    "cipherowl-ztk|cipherowl-1zi",
    "cipherowl-6i8|cipherowl-zig",
    "cipherowl-op4|cipherowl-zig",
    "cipherowl-op4|cipherowl-dw8",
    "cipherowl-8tj|cipherowl-6i8",
    "cipherowl-2qq|cipherowl-8tj",
    "cipherowl-2qq|cipherowl-p6g",
    "cipherowl-2qq|cipherowl-gtb",
    "cipherowl-rhy|cipherowl-6i8",
    "cipherowl-qm8|cipherowl-9bz",
    "cipherowl-9ts|cipherowl-qm8",
    "cipherowl-ko8|cipherowl-9ts",
    "cipherowl-rtv|cipherowl-9ts",
    "cipherowl-fhh|cipherowl-rtv",
    "cipherowl-fhh|cipherowl-dw8",
    "cipherowl-9rp|cipherowl-dw8",
    "cipherowl-b7k|cipherowl-9rp",
    "cipherowl-div|cipherowl-dw8",
    "cipherowl-dq0|cipherowl-dw8",
    "cipherowl-dq0|cipherowl-gtb",
    "cipherowl-933|cipherowl-p6g",
    "cipherowl-kgc|cipherowl-9bz",
    "cipherowl-6jv|cipherowl-933",
    "cipherowl-6jv|cipherowl-kgc",
    "cipherowl-6jv|cipherowl-gtb",
    "cipherowl-df4|cipherowl-p6g",
    "cipherowl-e0k|cipherowl-9bz",
    "cipherowl-zaq|cipherowl-ztk",
    "cipherowl-at2|cipherowl-9bz",
    "cipherowl-xw9|cipherowl-lup",
    "cipherowl-bgr|cipherowl-gtb",
    "cipherowl-vyv|cipherowl-p6g",
    "cipherowl-jtm|cipherowl-bgr",
    "cipherowl-2tp|cipherowl-bgr",
    "cipherowl-2tp|cipherowl-vyv",
    "cipherowl-26b|cipherowl-gtb",
    "cipherowl-yqj|cipherowl-gtb",
    "cipherowl-a5f|cipherowl-dgh",
    "cipherowl-a5f|cipherowl-op4",
    "cipherowl-obe|cipherowl-a5f",
    "cipherowl-wnk|cipherowl-9bz",
    "cipherowl-6mm|cipherowl-wnk",
    "cipherowl-2p5|cipherowl-6mm",
    "cipherowl-rmq|cipherowl-kj5",
    "cipherowl-p7t|cipherowl-yot",
    "cipherowl-7dw|cipherowl-yot",
    "cipherowl-dla|cipherowl-ztk",
    "cipherowl-bbt|cipherowl-ztk",
    "cipherowl-8ij|cipherowl-dla",
    "cipherowl-8ij|cipherowl-bbt",
    "cipherowl-d5r|cipherowl-2qq",
    "cipherowl-d5r|cipherowl-fhh",
    "cipherowl-j7j|cipherowl-9bz",
    "cipherowl-fce|cipherowl-9bz",
    "cipherowl-jf1|cipherowl-fce",
    "cipherowl-jsl|cipherowl-dla",
    "cipherowl-179|cipherowl-d5r",
    "cipherowl-4i7|cipherowl-obe",
    "cipherowl-x0y|cipherowl-26b"
)

$count = 0
$errors = 0
foreach ($dep in $deps) {
    $parts = $dep.Split("|")
    $issueId = $parts[0]
    $dependsOn = $parts[1]
    $sql = "INSERT INTO beads.dependencies (issue_id, depends_on_id, type, created_by) VALUES ('$issueId', '$dependsOn', 'blocks', 'CipherOwl Team')"
    try {
        $result = bd sql $sql 2>&1 | Out-String
        if ($result -match "Error") {
            Write-Host "FAIL: $issueId <- $dependsOn"
            $errors++
        } else {
            $count++
        }
    } catch {
        Write-Host "FAIL: $issueId <- $dependsOn"
        $errors++
    }
    if ($count % 20 -eq 0 -and $count -gt 0) { Write-Host "$count deps OK..." }
}
Write-Host "`nDone! $count dependencies added, $errors errors."
