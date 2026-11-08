# Толкает PULSE в GitHub-репозиторий и запускает сборку IPA.
#
# Использование (из папки проекта):
#   .\Tools\push.ps1 https://github.com/твой-логин/pulse.git
#
# Если репозиторий ещё не создан: создай пустой репозиторий на github.com
# (без README и .gitignore) и скопируй его HTTPS-ссылку.

param(
    [Parameter(Mandatory = $true)]
    [string]$RepoUrl,
    [string]$Branch = "main",
    [string]$Message = "PULSE: обновление"
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $PSScriptRoot)

if (-not (Test-Path ".git")) {
    git init -b $Branch
}

git add -A
git -c core.hooksPath=.git/hooks commit -m $Message 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Нечего коммитить — отправляю то, что есть." -ForegroundColor Yellow
}

$remotes = git remote
if ($remotes -contains "origin") {
    git remote set-url origin $RepoUrl
} else {
    git remote add origin $RepoUrl
}

git branch -M $Branch
git push -u origin $Branch

Write-Host ""
Write-Host "Готово. Сборка IPA: $RepoUrl/actions" -ForegroundColor Green
Write-Host "Готовый файл:   $RepoUrl/releases/download/latest/PULSE-unsigned.ipa" -ForegroundColor Green
