$ErrorActionPreference = 'Stop'

Write-Host '============================================================='
Write-Host 'Install Dependencies - Outpatient Hospital DB'
Write-Host '============================================================='

function Test-Command($name) {
    return $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

if (Test-Command 'mysql') {
    Write-Host '[OK] mysql client found:'
    mysql --version
    exit 0
}

Write-Host '[INFO] mysql client not found. Trying winget install...'

if (-not (Test-Command 'winget')) {
    Write-Host '[ERROR] winget not found. Please install MySQL manually:'
    Write-Host 'https://dev.mysql.com/downloads/installer/'
    exit 1
}

# MySQL Shell includes mysqlsh, but we need mysql CLI from server/tools package.
# Install MySQL Server package via winget (contains mysql.exe).
winget install -e --id Oracle.MySQL --accept-package-agreements --accept-source-agreements

Write-Host '[INFO] Re-open terminal after install, then run:'
Write-Host 'mysql --version'
