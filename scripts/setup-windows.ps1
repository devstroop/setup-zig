# setup-windows.ps1 — install the Zig compiler on Windows.
#
# Expects env: DOWNLOAD_URL, EXPECTED_SHA256, RUNNER_TOOL_CACHE, GITHUB_PATH.
# Downloads the tarball/zip, verifies SHA-256, extracts it under
# $RUNNER_TOOL_CACHE\setup-zig and prepends the bin directory to $GITHUB_PATH.

$ErrorActionPreference = "Stop"

$url = $env:DOWNLOAD_URL
$expected = $env:EXPECTED_SHA256
$toolCache = $env:RUNNER_TOOL_CACHE
if (-not $toolCache) { throw "RUNNER_TOOL_CACHE is required" }
$gitHubPath = $env:GITHUB_PATH
if (-not $gitHubPath) { throw "GITHUB_PATH is required" }

$tmp = Join-Path $env:RUNNER_TEMP "setup-zig-$([System.Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
try {
    $archive = Join-Path $tmp "zig-archive"

    Write-Host "setup-zig: downloading $url"
    $attempts = 3
    for ($i = 1; $i -le $attempts; $i++) {
        try {
            Invoke-WebRequest -Uri $url -OutFile $archive -UseBasicParsing
            break
        } catch {
            if ($i -eq $attempts) { throw }
            Write-Host "setup-zig: download attempt $i failed, retrying..."
            Start-Sleep -Seconds 2
        }
    }

    $actual = (Get-FileHash -Path $archive -Algorithm SHA256).Hash.ToLower()
    $expectedNorm = $expected.ToLower()
    if ($actual -ne $expectedNorm) {
        throw "SHA-256 mismatch for $archive`n  expected: $expectedNorm`n  actual:   $actual"
    }

    # Windows tar.exe (bsdtar) handles both .tar.xz and .zip.
    Push-Location $tmp
    try {
        tar -xf $archive
        if ($LASTEXITCODE -ne 0) { throw "tar extraction failed with exit code $LASTEXITCODE" }
    } finally {
        Pop-Location
    }

    $zigDir = Get-ChildItem -Path $tmp -Directory -Filter "zig-*" | Select-Object -First 1
    if (-not $zigDir) { throw "extracted archive contains no 'zig-*' directory" }

    $installRoot = Join-Path $toolCache "setup-zig"
    New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
    $dest = Join-Path $installRoot "zig"
    Remove-Item -Path $dest -Recurse -Force -ErrorAction SilentlyContinue  # avoid nesting into a stale install
    Move-Item -Path $zigDir.FullName -Destination $dest

    $installed = Join-Path $installRoot "zig"
    # Zig >= 0.15 ships the binary at the archive root (zig\zig.exe);
    # older releases use zig\bin\zig.exe.
    if (Test-Path (Join-Path $installed "zig.exe")) {
        $binDir = $installed
    } elseif (Test-Path (Join-Path $installed "bin\zig.exe")) {
        $binDir = Join-Path $installed "bin"
    } else {
        throw "zig.exe not found under $installed (tried root and bin\zig.exe)"
    }
    & (Join-Path $binDir "zig.exe") version | Out-Null
    Add-Content -Path $gitHubPath -Value $binDir
    Write-Host "setup-zig: installed to $installed"
} finally {
    Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
