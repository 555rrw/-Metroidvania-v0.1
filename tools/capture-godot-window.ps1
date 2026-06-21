param(
    [string]$OutputPath = ".scratch\godot-window-capture.png",
    [string]$GodotPath = "",
    [string]$ProjectPath = ".",
    [string]$Scene = "",
    [string]$TitlePattern = "",
    [int]$WaitSeconds = 15,
    [int]$DelaySeconds = 1,
    [switch]$Launch,
    [switch]$IncludeEditor,
    [switch]$CloseAfterCapture
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

namespace GodotCapture
{
    public struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    public struct POINT
    {
        public int X;
        public int Y;
    }

    public static class NativeMethods
    {
        [DllImport("user32.dll")]
        public static extern bool GetClientRect(IntPtr hWnd, out RECT lpRect);

        [DllImport("user32.dll")]
        public static extern bool ClientToScreen(IntPtr hWnd, ref POINT lpPoint);

        [DllImport("user32.dll")]
        public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

        [DllImport("user32.dll")]
        public static extern bool IsIconic(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
    }
}
"@

function Resolve-AbsolutePath {
    param([string]$PathValue, [string]$BasePath)

    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return [System.IO.Path]::GetFullPath($PathValue)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $BasePath $PathValue))
}

function Find-GodotExecutable {
    if ($GodotPath -and (Test-Path -LiteralPath $GodotPath)) {
        return (Resolve-Path -LiteralPath $GodotPath).Path
    }

    $candidates = @()

    if ($env:GODOT4) {
        $candidates += $env:GODOT4
    }

    $knownDownload = Join-Path $env:USERPROFILE "Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe"
    $candidates += $knownDownload

    foreach ($commandName in @("godot4", "godot")) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command) {
            $candidates += $command.Source
        }
    }

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw "Godot executable not found. Pass -GodotPath or set GODOT4."
}

function Start-GodotProject {
    param([string]$ExecutablePath, [string]$ResolvedProjectPath, [string]$ScenePath)

    $escapedProject = $ResolvedProjectPath.Replace('"', '\"')
    $arguments = "--path `"$escapedProject`""

    if ($ScenePath) {
        $escapedScene = $ScenePath.Replace('"', '\"')
        $arguments = "$arguments `"$escapedScene`""
    }

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $ExecutablePath
    $startInfo.Arguments = $arguments
    $startInfo.WorkingDirectory = $ResolvedProjectPath
    # Keep the launched Godot process detached from this shell pipe; otherwise
    # screenshots may work but command output can block until the game exits.
    $startInfo.UseShellExecute = $true

    return [System.Diagnostics.Process]::Start($startInfo)
}

function Get-GodotGameWindows {
    param([int]$PreferredProcessId = 0)

    $processes = Get-Process | Where-Object {
        $_.ProcessName -like "Godot*" -and $_.MainWindowHandle -ne 0
    }

    if ($PreferredProcessId -gt 0) {
        $processes = $processes | Where-Object { $_.Id -eq $PreferredProcessId }
    }

    if ($TitlePattern) {
        $processes = $processes | Where-Object { $_.MainWindowTitle -match $TitlePattern }
    }

    if (-not $IncludeEditor) {
        $processes = $processes | Where-Object { $_.MainWindowTitle -notmatch "^Godot Engine" }
    }

    return @($processes | Sort-Object Id -Descending)
}

function Wait-GodotGameWindow {
    param([int]$PreferredProcessId = 0)

    $deadline = (Get-Date).AddSeconds($WaitSeconds)

    do {
        $windows = @(Get-GodotGameWindows -PreferredProcessId $PreferredProcessId)
        if ($windows.Count -gt 0) {
            return $windows[0]
        }

        Start-Sleep -Milliseconds 250
    } while ((Get-Date) -lt $deadline)

    return $null
}

function Capture-WindowClientArea {
    param(
        [System.Diagnostics.Process]$Process,
        [string]$ResolvedOutputPath
    )

    $handle = [IntPtr]$Process.MainWindowHandle

    if ([GodotCapture.NativeMethods]::IsIconic($handle)) {
        [GodotCapture.NativeMethods]::ShowWindow($handle, 9) | Out-Null
    }

    [GodotCapture.NativeMethods]::SetForegroundWindow($handle) | Out-Null
    Start-Sleep -Seconds $DelaySeconds

    $rect = New-Object GodotCapture.RECT
    $point = New-Object GodotCapture.POINT

    $hasClientRect = [GodotCapture.NativeMethods]::GetClientRect($handle, [ref]$rect)
    $point.X = 0
    $point.Y = 0
    $hasScreenPoint = [GodotCapture.NativeMethods]::ClientToScreen($handle, [ref]$point)

    $width = $rect.Right - $rect.Left
    $height = $rect.Bottom - $rect.Top
    $x = $point.X
    $y = $point.Y

    if (-not $hasClientRect -or -not $hasScreenPoint -or $width -le 0 -or $height -le 0) {
        $windowRect = New-Object GodotCapture.RECT
        if (-not [GodotCapture.NativeMethods]::GetWindowRect($handle, [ref]$windowRect)) {
            throw "Could not read Godot window bounds."
        }

        $x = $windowRect.Left
        $y = $windowRect.Top
        $width = $windowRect.Right - $windowRect.Left
        $height = $windowRect.Bottom - $windowRect.Top
    }

    $outputDirectory = Split-Path -Parent $ResolvedOutputPath
    if ($outputDirectory -and -not (Test-Path -LiteralPath $outputDirectory)) {
        New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
    }

    $bitmap = New-Object System.Drawing.Bitmap $width, $height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

    try {
        $size = New-Object System.Drawing.Size $width, $height
        $graphics.CopyFromScreen($x, $y, 0, 0, $size)
        $bitmap.Save($ResolvedOutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }

    return [PSCustomObject]@{
        Path = $ResolvedOutputPath
        Pid = $Process.Id
        Title = $Process.MainWindowTitle
        Width = $width
        Height = $height
        Bytes = (Get-Item -LiteralPath $ResolvedOutputPath).Length
    }
}

$resolvedProjectPath = Resolve-AbsolutePath -PathValue $ProjectPath -BasePath (Get-Location).Path
$resolvedOutputPath = Resolve-AbsolutePath -PathValue $OutputPath -BasePath $resolvedProjectPath
$launchedProcess = $null
$preferredPid = 0

if ($Launch) {
    $resolvedGodotPath = Find-GodotExecutable
    $launchedProcess = Start-GodotProject -ExecutablePath $resolvedGodotPath -ResolvedProjectPath $resolvedProjectPath -ScenePath $Scene
    $preferredPid = $launchedProcess.Id
}

$targetWindow = Wait-GodotGameWindow -PreferredProcessId $preferredPid

if (-not $targetWindow) {
    throw "No Godot game window found. Start the project or run with -Launch."
}

$capture = Capture-WindowClientArea -Process $targetWindow -ResolvedOutputPath $resolvedOutputPath

if ($CloseAfterCapture -and $launchedProcess -and $targetWindow.Id -eq $launchedProcess.Id) {
    $targetWindow.CloseMainWindow() | Out-Null
    Start-Sleep -Milliseconds 500
    if (-not $targetWindow.HasExited) {
        $targetWindow.Kill()
    }
}

Write-Output ("CAPTURE_OK path=""{0}"" pid={1} size={2}x{3} bytes={4} title=""{5}""" -f $capture.Path, $capture.Pid, $capture.Width, $capture.Height, $capture.Bytes, $capture.Title)
