# fix_tasks_encoding.ps1
param([string]$JsonFile = "tasks_all.json", [string]$OutputFile = "TASKS.md")

# Emoji via codepoints (no literal emoji in this script)
$E_CHECK = [char]::ConvertFromUtf32(0x2705)    # ✅
$E_RED   = [char]::ConvertFromUtf32(0x1F534)   # 🔴
$E_ORNG  = [char]::ConvertFromUtf32(0x1F7E0)   # 🟠
$E_BLUE  = [char]::ConvertFromUtf32(0x1F535)   # 🔵
$E_WHITE = [char]::ConvertFromUtf32(0x2B1C)    # ⬜
$E_TARGET= [char]::ConvertFromUtf32(0x1F3AF)   # 🎯
$E_CHART = [char]::ConvertFromUtf32(0x1F4CA)   # 📊 
$E_FIRE  = [char]::ConvertFromUtf32(0x1F525)   # 🔥
$E_FILES = [char]::ConvertFromUtf32(0x1F5C2)   # 🗂️
$E_PIN   = [char]::ConvertFromUtf32(0x1F4CE)   # 📎

$epicEmoji = @{
    "1"="🏗️"; "2"="🔐"; "3"="🗄️"; "4"="⚡"; "5"="☁️"; "6"="👁️";
    "7"="🛡️"; "8"="🔑"; "9"="✨"; "10"="🔍"; "11"="⌨️"; "12"="🤝";
    "13"="🔔"; "14"="🎓"; "15"="🧪"; "16"="🚀"
}
# Override with codepoint-built strings to avoid encoding issues in this block:
$epicEmoji["1"]  = "$([char]::ConvertFromUtf32(0x1F3D7))$([char]0xFE0F)"
$epicEmoji["2"]  = "$([char]::ConvertFromUtf32(0x1F510))"
$epicEmoji["3"]  = "$([char]::ConvertFromUtf32(0x1F5C4))$([char]0xFE0F)"
$epicEmoji["4"]  = "$([char]::ConvertFromUtf32(0x26A1))"
$epicEmoji["5"]  = "$([char]::ConvertFromUtf32(0x2601))$([char]0xFE0F)"
$epicEmoji["6"]  = "$([char]::ConvertFromUtf32(0x1F441))$([char]0xFE0F)"
$epicEmoji["7"]  = "$([char]::ConvertFromUtf32(0x1F6E1))$([char]0xFE0F)"
$epicEmoji["8"]  = "$([char]::ConvertFromUtf32(0x1F511))"
$epicEmoji["9"]  = "$([char]::ConvertFromUtf32(0x2728))"
$epicEmoji["10"] = "$([char]::ConvertFromUtf32(0x1F50D))"
$epicEmoji["11"] = "$([char]::ConvertFromUtf32(0x2328))$([char]0xFE0F)"
$epicEmoji["12"] = "$([char]::ConvertFromUtf32(0x1F91D))"
$epicEmoji["13"] = "$([char]::ConvertFromUtf32(0x1F514))"
$epicEmoji["14"] = "$([char]::ConvertFromUtf32(0x1F393))"
$epicEmoji["15"] = "$([char]::ConvertFromUtf32(0x1F9EA))"
$epicEmoji["16"] = "$([char]::ConvertFromUtf32(0x1F680))"

$data = Get-Content $JsonFile -Raw | ConvertFrom-Json
$taskMap = @{}
foreach ($t in $data) { $taskMap[$t.id] = $t }

function Get-StatusEmoji($id, $title) {
    if ($title -match '~~') { return $script:E_CHECK }
    if ($taskMap.ContainsKey($id)) {
        $t = $taskMap[$id]
        if ($t.status -eq "closed") { return $script:E_CHECK }
        switch ($t.priority) {
            0 { return $script:E_RED }
            1 { return $script:E_ORNG }
            2 { return $script:E_BLUE }
            default { return $script:E_WHITE }
        }
    }
    return $script:E_WHITE
}

$raw = [System.IO.File]::ReadAllText($OutputFile, [System.Text.Encoding]::GetEncoding(1256))
$lines = $raw -split "\r?\n"

$closed = @($data | Where-Object { $_.status -eq "closed" }).Count
$open   = @($data | Where-Object { $_.status -ne "closed" }).Count

$fixedLines = foreach ($line in $lines) {

    if ($line -match '^#\s+\S+\s+.*(CipherOwl|مهام)') {
        $line = $line -replace '^#\s+\S+\s+', "# $E_TARGET "
    }
    elseif ($line -match '^##\s+\S+\s+.*الإحصائيات') {
        $line = $line -replace '^##\s+\S+\s+', "## $E_CHART "
    }
    elseif ($line -match '^##\s+\S+\s+.*المسار') {
        $line = $line -replace '^##\s+\S+\s+', "## $E_FIRE "
    }
    elseif ($line -match '^##\s+\S+\s+.*المهام') {
        $line = $line -replace '^##\s+\S+\s+', "## $E_FILES "
    }
    elseif ($line -match '^##\s+\S+\s+.*مهام خارج') {
        $line = $line -replace '^##\s+\S+\s+', "## $E_PIN "
    }
    elseif ($line -match '^###\s+\S+\s+EPIC-(\d+)') {
        $n = $Matches[1]
        $em = if ($epicEmoji.ContainsKey($n)) { $epicEmoji[$n] } else { $E_PIN }
        $line = $line -replace '^###\s+\S+\s+', "### $em "
    }
    elseif ($line -match '^\|\s*\S+\s*P0\s*·') {
        $line = $line -replace '^\|\s*\S+\s*P0\s*·', "| $E_RED P0 ·"
    }
    elseif ($line -match '^\|\s*\S+\s*P1\s*·') {
        $line = $line -replace '^\|\s*\S+\s*P1\s*·', "| $E_ORNG P1 ·"
    }
    elseif ($line -match '^\|\s*\S+\s*P2\s*·') {
        $line = $line -replace '^\|\s*\S+\s*P2\s*·', "| $E_BLUE P2 ·"
    }
    elseif ($line -match '^\|\s*\S+\s*P3\s*·') {
        $line = $line -replace '^\|\s*\S+\s*P3\s*·', "| $E_WHITE P3 ·"
    }
    elseif ($line -match '\*\*التقدم\*\*.*\|\s*\S+\s*(\d+)/(\d+)') {
        $done  = [int]$Matches[1]; $total = [int]$Matches[2]
        $filled = [int][Math]::Round(20 * $done / [Math]::Max($total, 1))
        $bar    = ([char]0x2588).ToString() * $filled + ([char]0x2591).ToString() * (20 - $filled)
        $line   = $line -replace '\S+\s*\d+/\d+', "$bar $done/$total"
    }
    elseif ($line -match '^\|\s*\S+\s*\|.+`(cipherowl-[a-z0-9]+)`') {
        $id    = $Matches[1]
        $title = if ($line -match '\|\s*\S+\s*\|\s*(.+?)\s*\|') { $Matches[1] } else { "" }
        $emoji = Get-StatusEmoji $id $title
        $line  = $line -replace '^\|\s*\S+\s*\|', "| $emoji |"
    }
    elseif ($line -match '\S+\s+منجزة.*\S+\s+مفتوحة') {
        $line = $line -replace '\S+\s+منجزة:\s*\d+', "$E_CHECK منجزة: $closed"
        $line = $line -replace '\S+\s+مفتوحة:\s*\d+', "$E_RED مفتوحة: $open"
    }

    $line
}

$utf8Bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText(
    [System.IO.Path]::GetFullPath($OutputFile),
    ($fixedLines -join "`n"),
    $utf8Bom
)
Write-Host "Done. $closed closed, $open open tasks."