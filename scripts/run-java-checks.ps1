$ErrorActionPreference = "Stop"
$failures = @()

Write-Host "[Maven Checks] Running Spotless..."
try {
    mvn spotless:check -q
    Write-Host "PASS: Maven Checks (Spotless)"
} catch {
    Write-Host "FAIL: Maven Checks (Spotless)"
    $failures += "Spotless"
}

Write-Host "[Maven Checks] Running Checkstyle..."
try {
    mvn checkstyle:check -q
    Write-Host "PASS: Maven Checks (Checkstyle)"
} catch {
    Write-Host "FAIL: Maven Checks (Checkstyle)"
    $failures += "Checkstyle"
}

Write-Host "[Maven Checks] Running Unit Tests..."
try {
    mvn test -q
    Write-Host "PASS: Maven Checks (Tests)"
} catch {
    Write-Host "FAIL: Maven Checks (Tests)"
    $failures += "Tests"
}

Write-Host "[Maven Checks] Generating JaCoCo Coverage Report..."
try {
    mvn jacoco:report -q
} catch {
    Write-Host "FAIL: Maven Checks (Coverage Report Generation)"
    $failures += "Coverage Report"
}

$coverageFile = "target/site/jacoco/jacoco.xml"
if (Test-Path $coverageFile) {
    $xml = [xml](Get-Content $coverageFile)
    $counter = $xml.report.counter | Where-Object { $_.type -eq "INSTRUCTION" }
    $covered = [int]$counter.covered

    if ($covered -lt 80) {
        Write-Host "FAIL: Maven Checks (Coverage < 80%) [$covered%]"
        $failures += "Coverage < 80%"
    } else {
        Write-Host "PASS: Maven Checks (Coverage >= 80%) [$covered%]"
    }
} else {
    Write-Host "FAIL: Maven Checks (Coverage File Missing)"
    $failures += "Coverage File Missing"
}

if ($failures.Count -gt 0) {
    Write-Host "`nBLOCKED: Commit failed due to the following checks:"
    foreach ($fail in $failures) {
        Write-Host " - $fail"
    }
    exit 1
} else {
    Write-Host "`nSUCCESS: All Maven checks passed!"
}
