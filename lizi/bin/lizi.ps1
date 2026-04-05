param(
  [ValidateSet("Menu", "CheckEnvironment", "OpenWorkspace", "RunTask", "OpenResult")]
  [string]$Action = "Menu",

  [string]$TaskId,
  [string]$ResultId,

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$ArgsFromCmd
)

$ErrorActionPreference = "Stop"

try {
  [Console]::InputEncoding = [System.Text.Encoding]::UTF8
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LiziRoot = Split-Path -Parent $ScriptDir
$ConfigPath = Join-Path $LiziRoot "config\lizi.workbench.json"

function Write-LiziHeader {
  param(
    [string]$Title
  )

  Write-Host ""
  Write-Host "========================================"
  Write-Host $Title
  Write-Host "========================================"
}

function Pause-Lizi {
  param(
    [string]$Message = "Press Enter to return to menu"
  )

  [void](Read-Host $Message)
}

function Get-ConfigItems {
  param(
    [object]$Value
  )

  if ($null -eq $Value) {
    return @()
  }

  return @($Value)
}

function Read-MenuChoice {
  param(
    [string]$Prompt,
    [int]$MaxNumber
  )

  while ($true) {
    $choice = Read-Host $Prompt

    if ([string]::IsNullOrWhiteSpace($choice)) {
      return $null
    }

    if ($choice -match "^[Qq]$") {
      return "Q"
    }

    $number = 0
    if ([int]::TryParse($choice, [ref]$number)) {
      if ($number -ge 1 -and $number -le $MaxNumber) {
        return $number
      }
    }

    Write-Host "Input is invalid. Please try again." -ForegroundColor Yellow
  }
}

function Get-WorkbenchConfig {
  if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Config file was not found: $ConfigPath"
  }

  $raw = Get-Content -LiteralPath $ConfigPath -Raw
  $config = $raw | ConvertFrom-Json

  if ($null -eq $config) {
    throw "Config file is empty or cannot be parsed: $ConfigPath"
  }

  return $config
}

function Get-WorkspaceById {
  param(
    [object]$Config,
    [string]$WorkspaceId
  )

  $workspaces = Get-ConfigItems $Config.workspaces

  if ($workspaces.Count -eq 0) {
    throw "No workspaces are defined in config."
  }

  if (-not [string]::IsNullOrWhiteSpace($WorkspaceId)) {
    foreach ($workspace in $workspaces) {
      if ($workspace.id -eq $WorkspaceId) {
        return $workspace
      }
    }
  }

  foreach ($workspace in $workspaces) {
    if ($workspace.default -eq $true) {
      return $workspace
    }
  }

  return $workspaces[0]
}

function Invoke-CommandCheck {
  param(
    [string]$CommandText
  )

  $previousPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"

  try {
    $outputLines = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -Command $CommandText 2>&1)
    $exitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }
  } catch {
    $outputLines = @($_.Exception.Message)
    $exitCode = 1
  } finally {
    $ErrorActionPreference = $previousPreference
  }

  return [PSCustomObject]@{
    ExitCode = $exitCode
    Output   = ($outputLines | ForEach-Object { $_.ToString() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  }
}

function Show-EnvironmentChecks {
  param(
    [object]$Config
  )

  $checks = Get-ConfigItems $Config.environmentChecks

  Write-LiziHeader "Environment Check"

  if ($checks.Count -eq 0) {
    Write-Host "No environment checks are configured."
    return
  }

  $successCount = 0
  $warningCount = 0
  $failureCount = 0

  foreach ($check in $checks) {
    Write-Host ""
    Write-Host ("[{0}] {1}" -f $check.id, $check.name)

    $required = $check.required -eq $true

    if ($check.type -eq "command") {
      Write-Host "Type: command"
      Write-Host ("Command: {0}" -f $check.command)

      $result = Invoke-CommandCheck -CommandText ([string]$check.command)

      if ($result.ExitCode -eq 0) {
        $successCount++
        Write-Host "Result: success" -ForegroundColor Green
      } elseif ($required) {
        $failureCount++
        Write-Host "Result: failed" -ForegroundColor Red
      } else {
        $warningCount++
        Write-Host "Result: optional item missing" -ForegroundColor Yellow
      }

      if ($result.Output.Count -gt 0) {
        Write-Host "Output:"
        foreach ($line in $result.Output) {
          Write-Host ("  {0}" -f $line)
        }
      }
    } elseif ($check.type -eq "path") {
      Write-Host "Type: path"
      Write-Host ("Path: {0}" -f $check.path)

      if (Test-Path -LiteralPath ([string]$check.path)) {
        $successCount++
        Write-Host "Result: success" -ForegroundColor Green
      } elseif ($required) {
        $failureCount++
        Write-Host "Result: failed" -ForegroundColor Red
      } else {
        $warningCount++
        Write-Host "Result: optional item missing" -ForegroundColor Yellow
      }
    } else {
      if ($required) {
        $failureCount++
        Write-Host ("Result: failed, unsupported check type: {0}" -f $check.type) -ForegroundColor Red
      } else {
        $warningCount++
        Write-Host ("Result: optional item missing, unsupported check type: {0}" -f $check.type) -ForegroundColor Yellow
      }
    }
  }

  Write-Host ""
  Write-Host ("Summary: success {0}, failed {1}, optional missing {2}" -f $successCount, $failureCount, $warningCount)
}

function Open-DefaultWorkspace {
  param(
    [object]$Config
  )

  $workspace = Get-WorkspaceById -Config $Config -WorkspaceId $null

  Write-LiziHeader "Open Workspace"
  Write-Host ("Workspace: {0}" -f $workspace.name)
  Write-Host ("Path: {0}" -f $workspace.path)

  if (-not (Test-Path -LiteralPath ([string]$workspace.path))) {
    Write-Host "Default workspace path does not exist." -ForegroundColor Red
    return
  }

  Invoke-Item -LiteralPath ([string]$workspace.path)
  Write-Host "Workspace was opened with the Windows default action."
}

function Invoke-ShellTask {
  param(
    [object]$Task,
    [object]$Workspace,
    [object]$Config
  )

  Write-Host ("Task: {0}" -f $Task.name)
  Write-Host ("Command: {0}" -f $Task.command)

  if ($Task.id -eq "check-env") {
    Write-Host "This task is mapped to the built-in environment check." -ForegroundColor Cyan
    Show-EnvironmentChecks -Config $Config
    return
  }

  if (-not (Test-Path -LiteralPath ([string]$Workspace.path))) {
    Write-Host ("Workspace path does not exist: {0}" -f $Workspace.path) -ForegroundColor Red
    return
  }

  Push-Location ([string]$Workspace.path)
  try {
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    try {
      & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ([string]$Task.command)
      $exitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }
    } catch {
      Write-Host $_.Exception.Message -ForegroundColor Red
      $exitCode = 1
    } finally {
      $ErrorActionPreference = $previousPreference
    }
  } finally {
    Pop-Location
  }

  if ($exitCode -eq 0) {
    Write-Host "Task completed." -ForegroundColor Green
  } else {
    Write-Host ("Task finished with exit code: {0}" -f $exitCode) -ForegroundColor Yellow
  }
}

function Run-SelectedTask {
  param(
    [object]$Config,
    [string]$TargetTaskId
  )

  $tasks = Get-ConfigItems $Config.tasks

  Write-LiziHeader "Run Task"

  if ($tasks.Count -eq 0) {
    Write-Host "No tasks are configured."
    return
  }

  $task = $null

  if (-not [string]::IsNullOrWhiteSpace($TargetTaskId)) {
    foreach ($item in $tasks) {
      if ($item.id -eq $TargetTaskId) {
        $task = $item
        break
      }
    }

    if ($null -eq $task) {
      Write-Host ("Task was not found: {0}" -f $TargetTaskId) -ForegroundColor Red
      return
    }
  } else {
    for ($i = 0; $i -lt $tasks.Count; $i++) {
      $item = $tasks[$i]
      Write-Host ("{0}) {1}" -f ($i + 1), $item.name)
      Write-Host ("   Type: {0}" -f $item.type)
      Write-Host ("   Command: {0}" -f $item.command)
    }

    $choice = Read-MenuChoice -Prompt "Choose a task number, or press Enter to go back" -MaxNumber $tasks.Count
    if ($null -eq $choice -or $choice -eq "Q") {
      return
    }

    $task = $tasks[$choice - 1]
  }

  if ($task.type -ne "shell") {
    Write-Host ("Only shell tasks are supported right now. Current type: {0}" -f $task.type) -ForegroundColor Yellow
    return
  }

  $workspace = Get-WorkspaceById -Config $Config -WorkspaceId ([string]$task.workspaceId)

  Write-Host ""
  Write-Host ("About to run task: {0}" -f $task.name) -ForegroundColor Cyan
  Invoke-ShellTask -Task $task -Workspace $workspace -Config $Config
}

function Open-SelectedResult {
  param(
    [object]$Config,
    [string]$TargetResultId
  )

  $results = Get-ConfigItems $Config.results

  Write-LiziHeader "View Result"

  if ($results.Count -eq 0) {
    Write-Host "No result items are configured."
    return
  }

  $result = $null

  if (-not [string]::IsNullOrWhiteSpace($TargetResultId)) {
    foreach ($item in $results) {
      if ($item.id -eq $TargetResultId) {
        $result = $item
        break
      }
    }

    if ($null -eq $result) {
      Write-Host ("Result item was not found: {0}" -f $TargetResultId) -ForegroundColor Red
      return
    }
  } else {
    for ($i = 0; $i -lt $results.Count; $i++) {
      $item = $results[$i]
      Write-Host ("{0}) {1}" -f ($i + 1), $item.name)
      Write-Host ("   Type: {0}" -f $item.type)
      Write-Host ("   Path: {0}" -f $item.path)
    }

    $choice = Read-MenuChoice -Prompt "Choose a result number, or press Enter to go back" -MaxNumber $results.Count
    if ($null -eq $choice -or $choice -eq "Q") {
      return
    }

    $result = $results[$choice - 1]
  }

  Write-Host ""
  Write-Host ("Result: {0}" -f $result.name)
  Write-Host ("Path: {0}" -f $result.path)

  if (-not (Test-Path -LiteralPath ([string]$result.path))) {
    Write-Host "Target path does not exist." -ForegroundColor Red
    return
  }

  Invoke-Item -LiteralPath ([string]$result.path)
  Write-Host "Target was opened with the Windows default action."
}

function Show-MainMenu {
  param(
    [object]$Config
  )

  while ($true) {
    Clear-Host
    Write-LiziHeader "Lizi CCB Workbench"
    Write-Host ("Version: {0}" -f $Config.version)
    Write-Host ("Config: {0}" -f $ConfigPath)
    Write-Host ""
    Write-Host "1) Check environment"
    Write-Host "2) Open workspace"
    Write-Host "3) Run task"
    Write-Host "4) View result"
    Write-Host "5) Exit"
    Write-Host ""

    $choice = Read-Host "Enter menu number"

    switch ($choice) {
      "1" {
        Show-EnvironmentChecks -Config $Config
        Pause-Lizi
      }
      "2" {
        Open-DefaultWorkspace -Config $Config
        Pause-Lizi
      }
      "3" {
        Run-SelectedTask -Config $Config -TargetTaskId $null
        Pause-Lizi
      }
      "4" {
        Open-SelectedResult -Config $Config -TargetResultId $null
        Pause-Lizi
      }
      "5" {
        Write-Host "Workbench closed."
        return
      }
      default {
        Write-Host "Input is invalid. Enter a number from 1 to 5." -ForegroundColor Yellow
        Pause-Lizi
      }
    }
  }
}

try {
  $config = Get-WorkbenchConfig

  switch ($Action) {
    "CheckEnvironment" {
      Show-EnvironmentChecks -Config $config
    }
    "OpenWorkspace" {
      Open-DefaultWorkspace -Config $config
    }
    "RunTask" {
      Run-SelectedTask -Config $config -TargetTaskId $TaskId
    }
    "OpenResult" {
      Open-SelectedResult -Config $config -TargetResultId $ResultId
    }
    default {
      Show-MainMenu -Config $config
    }
  }
} catch {
  Write-LiziHeader "Workbench Startup Failed"
  Write-Host $_.Exception.Message -ForegroundColor Red
  exit 1
}
