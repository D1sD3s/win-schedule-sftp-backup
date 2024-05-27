param (
    [Parameter(Mandatory = $true)]
    [string]$ftpServer,
    
    [Parameter(Mandatory = $false)]
    [string]$ftpUsername,
    
    [Parameter(Mandatory = $false)]
    [string]$ftpPath = "/",

    [Parameter(Mandatory = $true)]
    [string]$ftpPassword,
    
    [Parameter(Mandatory = $false)]
    [string]$localBackupDirectory = ".\backup-data",
    
    [Parameter(Mandatory = $false)]
    [int]$maxBackups = 5,
    
    [Parameter(Mandatory = $false)]
    [string]$winscpPath = "C:\Program Files (x86)\WinSCP\WinSCP.com",
    
    [Parameter(Mandatory = $false)]
    [string]$config
)

if ($config) {
    if ($PSBoundParameters.Count -gt 1) {
        Write-Host "When using --config, no other arguments are allowed." -ForegroundColor Red
        exit 1
    }
    if (-Not (Test-Path $config)) {
        Write-Host "Config file not found: $config" -ForegroundColor Red
        exit 1
    }
    try {
        $configData = Get-Content -Raw -Path $config | ConvertFrom-Json
    } catch {
        Write-Host "Failed to read or parse the config file: $_" -ForegroundColor Red
        exit 1
    }
    $requiredParams = @("ftpServer", "ftpPassword", "ftpUsername")
    foreach ($param in $requiredParams) {
        if (-Not $configData.PSObject.Properties[$param]) {
            Write-Host "Missing required parameter '$param' in config file." -ForegroundColor Red
            exit 1
        }
    }
    $ftpServer = $configData.ftpServer
    $ftpPath = $configData.ftpPath
    $ftpUsername = $configData.ftpUsername
    $ftpPassword = $configData.ftpPassword
    $localBackupDirectory = $configData.localBackupDirectory
    $maxBackups = $configData.maxBackups
    $winscpPath = $configData.winscpPath
    $logFilePath = ".\error.log"
}
if (-Not $ftpServer) {
    Write-Host "Parameter -ftpServer is required." -ForegroundColor Red
    exit 1
}
if (-Not $ftpPassword) {
    Write-Host "Parameter -ftpPassword is required." -ForegroundColor Red
    exit 1
}
if (-Not $ftpUsername) {
    Write-Host "Parameter -ftpUsername is required." -ForegroundColor Red
    exit 1
}

function Handle-Error {
    param (
        [string]$message
    )
	Show-Notification -notificationText "backup FAILED! See error log."
    $errorMessage = "ERROR: $message"
    $errorMessage | Out-File -FilePath $logFilePath -Append
    exit 1
}

function Show-Notification {
    param (
        [string]$notificationText
    )
    Add-Type -AssemblyName System.Windows.Forms
    
    $notifyIcon = New-Object System.Windows.Forms.NotifyIcon
    $notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
    $notifyIcon.BalloonTipTitle = "FTP-Backup"
    $notifyIcon.BalloonTipText = $notificationText
    $notifyIcon.Visible = $true

    $notifyIcon.ShowBalloonTip(10000)
    Start-Sleep -Seconds 10
    $notifyIcon.Dispose()
}

#
# Do actual backup...
#

Show-Notification -notificationText "backup has been started..."
if (-Not (Test-Path $localBackupDirectory)) {
    New-Item -ItemType Directory -Path $localBackupDirectory -ErrorAction Stop
}

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$tempDownloadDir = Join-Path $localBackupDirectory "temp_$timestamp"
New-Item -ItemType Directory -Path $tempDownloadDir -ErrorAction Stop

try {
    $sessionOptions = @"
open sftp://USERNAME:PASSWORD@SERVER -hostkey=""*""
cd PATH
lcd $tempDownloadDir
get *.*
exit
"@

    $sessionOptions = $sessionOptions -replace "USERNAME", $ftpUsername
    $sessionOptions = $sessionOptions -replace "PASSWORD", $ftpPassword
    $sessionOptions = $sessionOptions -replace "SERVER", $ftpServer
    $sessionOptions = $sessionOptions -replace "PATH", $ftpPath

    $scriptPath = Join-Path $env:TEMP "sftp_script.txt"
    $sessionOptions | Set-Content -Path $scriptPath

    & "$winscpPath" /script=$scriptPath

    Remove-Item -Path $scriptPath
} catch {
    Handle-Error "Fehler beim Herunterladen des Ordners vom SFTP-Server: $_"
}

try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zipFilePath = Join-Path $localBackupDirectory "backup_$timestamp.zip"
    [System.IO.Compression.ZipFile]::CreateFromDirectory($tempDownloadDir, $zipFilePath)
} catch {
    Handle-Error "Fehler beim Zippen des Verzeichnisses: $_"
}

try {
    Remove-Item -Recurse -Force $tempDownloadDir
} catch {
    Handle-Error "Fehler beim Löschen des temporären Verzeichnisses: $_"
}

try {
    $backups = Get-ChildItem -Path $localBackupDirectory -Filter "*.zip" | Sort-Object LastWriteTime
    if ($backups.Count -gt $maxBackups) {
        $backupsToDelete = $backups | Select-Object -First ($backups.Count - $maxBackups)
        foreach ($backup in $backupsToDelete) {
            Remove-Item -Path $backup.FullName -ErrorAction Stop
        }
    }
} catch {
    Handle-Error "Fehler beim Verwalten der Backups: $_"
}
Show-Notification -notificationText "backup finished."
Write-Host "Backup erfolgreich erstellt und veraltete Backups entfernt, falls vorhanden."
Start-Sleep -Seconds 5

