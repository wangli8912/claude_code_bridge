# Lizi PowerShell outer entrypoint.
# First version keeps only the minimum safe shell behavior:
# 1. Show that the personal shell entry works.
# 2. Show where the future personal config lives.
# 3. Do not invoke or modify upstream core files yet.

param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$ArgsFromCmd
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LiziRoot = Split-Path -Parent $ScriptDir
$ConfigPath = Join-Path $LiziRoot "config\lizi.workbench.json"

Write-Host "Lizi shell entry is ready."
Write-Host "Config placeholder: $ConfigPath"

if ($ArgsFromCmd -and $ArgsFromCmd.Count -gt 0) {
  Write-Host ("Received arguments: " + ($ArgsFromCmd -join " "))
} else {
  Write-Host "Received arguments: <none>"
}

Write-Host "Next step: this script can later translate personal defaults into an upstream ccb launch."
