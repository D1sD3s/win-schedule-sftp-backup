param(
    [string]$action,
    [string]$inputVariable
)

# Configuration
$workingDirectory = (Get-Location).Path
$actionScriptPath = "$workingDirectory\create-backup.ps1"
$taskName = "ScheduledBackupTask"
$taskDescription = "This task runs the minecraft sftp backup script."
$interval = 1  # Interval in hours


function Start-Backup {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$actionScriptPath`"" -WorkingDirectory $workingDirectory
    $trigger = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(1)) -RepetitionInterval (New-TimeSpan -Hours $interval) -RepetitionDuration (New-TimeSpan -Days 1)
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive -RunLevel Highest
    Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName $taskName -Description $taskDescription
}
function Handle-Error {
    param (
        [string]$message
    )
    Write-Host "Fehler: $message" -ForegroundColor Red
    exit 1
}
function Stop-Backup {

	try {
		$task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
		Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
		Write-Host "Scheduled task '$taskName' removed successfully."
	} catch [Microsoft.Management.Infrastructure.CimInstance] {
		if ($_.FullyQualifiedErrorId -eq 'CmdletizationQuery_NotFound_TaskName,Unregister-ScheduledTask') {
        Write-Host "Scheduled task '$taskName' does not exist." -ForegroundColor Yellow
    } else {
        Handle-Error "Fehler beim Entfernen der geplanten Aufgabe: $_"
    }
} catch {
    Handle-Error "Fehler beim Entfernen der geplanten Aufgabe: $_"
}
}

function Print-Details {
	try {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop

    # Print general information
    Write-Host "Task Name: $($task.TaskName)"
    Write-Host "Description: $($task.Description)"
    Write-Host "State: $($task.State)"
    Write-Host "Last Run Time: $($task.LastRunTime)"
    Write-Host "Next Run Time: $($task.NextRunTime)"
    Write-Host "Author: $($task.Principal.UserId)"
    Write-Host ""

    # Print triggers
    Write-Host "Triggers:"
    foreach ($trigger in $task.Triggers) {
        Write-Host "  - Type: $($trigger.TriggerType)"
        Write-Host "    Start Boundary: $($trigger.StartBoundary)"
        Write-Host "    End Boundary: $($trigger.EndBoundary)"
        Write-Host "    Enabled: $($trigger.Enabled)"
        Write-Host "    Repetition Interval: $($trigger.Repetition.Interval)"
        Write-Host "    Repetition Duration: $($trigger.Repetition.Duration)"
        Write-Host ""
    }

    # Print actions
    Write-Host "Actions:"
    foreach ($action in $task.Actions) {
        Write-Host "  - Type: $($action.ActionType)"
        Write-Host "    Path: $($action.Path)"
        Write-Host "    Arguments: $($action.Arguments)"
        Write-Host "    Working Directory: $($action.WorkingDirectory)"
        Write-Host ""
    }

    # Print settings
    Write-Host "Settings:"
    Write-Host "  - Allow Demand Start: $($task.Settings.AllowDemandStart)"
    Write-Host "  - Start When Available: $($task.Settings.StartWhenAvailable)"
    Write-Host "  - Run Only If Idle: $($task.Settings.RunOnlyIfIdle)"
    Write-Host "  - Idle Duration: $($task.Settings.IdleSettings.IdleDuration)"
    Write-Host "  - Stop If Going On Battery: $($task.Settings.StopIfGoingOnBatteries)"
    Write-Host "  - Disallow Start If On Battery: $($task.Settings.DisallowStartIfOnBatteries)"
    Write-Host "  - Allow Hard Terminate: $($task.Settings.AllowHardTerminate)"
    Write-Host "  - Start When On AC Power: $($task.Settings.RunOnlyIfNetworkAvailable)"
    Write-Host "  - Enabled: $($task.Enabled)"
    Write-Host "  - Hidden: $($task.Hidden)"

} catch [Microsoft.Management.Infrastructure.CimInstance] {
    if ($_.FullyQualifiedErrorId -eq 'CmdletizationQuery_NotFound_TaskName,Get-ScheduledTask') {
        Write-Host "Scheduled task '$taskName' does not exist." -ForegroundColor Yellow
    } else {
        Handle-Error "Fehler beim Abrufen der geplanten Aufgabe: $_"
    }
} catch {
    Handle-Error "Fehler beim Abrufen der geplanten Aufgabe: $_"
}
}


function Set-Variable {
    param(
        [string]$variable
    )
    Write-Host "set to $variable"
}

switch ($action) {
    "start" { Start-Backup }
    "stop" { Stop-Backup }
    "set" { 
        if ($inputVariable) {
            Set-Variable -variable $inputVariable
			$interval = $inputVariable
        } else {
            Write-Host "Please provide an interval to set. (hours)"
        }
    }
	"details"{ Print-Details }
    default { 
        Write-Host "Unknown action. Please use start, stop, or set <input_variable>."
    }
}


