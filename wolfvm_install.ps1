<#
    .SYNOPSIS
        Installation script for WOLF-VM.
        ** Only install on a virtual machine! **

    .DESCRIPTION
        Installation script for WOLF-VM leverages Elastic, Hayabusa and Zeek.
        Script verifies minimal settings necessary to install WOLF on a virtual machine..

        To execute this script:
          1) Open PowerShell window as administrator
          2) Allow script execution by running command "Set-ExecutionPolicy Unrestricted"
          3) iex (iwr -Uri "https://raw.githubusercontent.com/H0wl3r/WOLF-VM/refs/heads/main/wolfvm_install.ps1").Content

    .EXAMPLE
        iex (iwr -Uri "https://raw.githubusercontent.com/H0wl3r/WOLF-VM/refs/heads/main/wolfvm_install.ps1").Content

        Description
        ---------------------------------------
        Execute the installer to configure WOLF VM.

    .LINK
        https://github.com/h0wl3r/WOLF-VM
#>

#############################
#####     FUNCTIONS     #####
#############################

function LoadingAnimation($scriptBlock, $message) {
    $cursorTop = [Console]::CursorTop
    
    try {
        [Console]::CursorVisible = $false
        $counter = 0
        $frames = ' |', ' /', ' -', ' \' 
        $jobName = Start-Job -ScriptBlock $scriptBlock
    
        while($jobName.JobStateInfo.State -eq "Running") {
            $frame = $frames[$counter % $frames.Length]
            
            Write-Host " $frame  $message" -NoNewLine
            [Console]::SetCursorPosition(0, $cursorTop)
            
            $counter += 1
            Start-Sleep -Milliseconds 125
        }
        
        # Only needed if you use a multiline frames
        Write-Host ($frames[0] -replace '[^\s+]', ' ')
    }
    finally {
        [Console]::SetCursorPosition(0, $cursorTop)
        [Console]::CursorVisible = $true
    }
}

# Check to script is running as administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-Not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host " "([char]0x26A0)"  Please run this script as administrator" -ForegroundColor Red
        Write-Host ""
        Read-Host "      Press Enter to exit..."
        exit 1
    }

# Check if any processes named cmd.exe are running
if (Get-Process -Name cmd -ErrorAction SilentlyContinue) {
    Stop-Process -Name cmd -Force
} 

# Check to see if wsl is enabled
if (-Not (wsl -l | Where-Object {$_.Replace("`0","") -match '^Ubuntu'} )) {
    Write-Host " "([char]0x26A0)"  Please run this script when WSL is installed" -ForegroundColor Red
    Write-Host ""
    Read-Host "      Press Enter to exit..."
    exit 1
}

#######################################
#####     Download Repository     #####
#######################################

$github_URL = "https://github.com/H0wl3r/WOLF-VM/archive/refs/heads/main.zip"
$ProgressPreference = 'SilentlyContinue'
Write-Host " "
try {
    Invoke-WebRequest -Uri $github_URL -OutFile "C:\Users\$env:username\Downloads\WOLF-VM.zip" -ErrorAction Stop
}
catch {
    Write-Host " "([char]0x26A0)"  WOLF VM Repository Download failed: $($_.Exception.Message)" -ForegroundColor Red
    Exit 1
}

Write-Host " "([char]0x2611)"  WOLF VM Repository Downloaded"
Expand-Archive "C:\Users\$env:username\Downloads\WOLF-VM.zip" -DestinationPath "C:\"
Rename-Item -Path "C:\WOLF-VM" -NewName "C:\WOLF"
Remove-Item -Path "C:\Users\$env:username\Downloads\WOLF-VM.zip" -Force
Start-Sleep 1


##################################
#####     INITIALISATION     #####
##################################

LoadingAnimation { & "C:\WOLF\Scripts\Initialisation.ps1" } " Initialising"
Write-Host " "([char]0x2611)"  Initalisation Complete"
Start-Sleep 1


#################################
#####     ElasticSearch     #####
#################################

LoadingAnimation { & "C:\WOLF\Scripts\ElasticSearch.ps1" } " Installing ElasticSearch"
Write-Host " "([char]0x2611)"  ElasticSearch Installation Complete"
Start-Sleep 1


##########################
#####     KIBANA     #####
##########################

LoadingAnimation { & "C:\WOLF\Scripts\Kibana.ps1" } " Installing Kibana"
Write-Host " "([char]0x2611)"  Kibana Installation Complete"
Start-Sleep 1


##############################
#####     WINLOGBEAT     #####
##############################

LoadingAnimation { & "C:\WOLF\Scripts\WinlogBeat.ps1" } " Installing WinlogBeat"
Write-Host " "([char]0x2611)"  WinlogBeat Installation Complete"
Start-Sleep 1


########################
#####     ZEEK     #####
########################

LoadingAnimation { & Start-Process powershell.exe -ArgumentList "& C:\WOLF\Scripts\Zeek.ps1"-Verb RunAs }"Installing Zeek"
Write-Host " "([char]0x2611)"  Zeek Installation Complete"
Start-Sleep -Seconds (2*60)


############################
#####     FileBeat     #####
############################

LoadingAnimation { & "C:\WOLF\Scripts\FileBeat.ps1" } " Installing FileBeat"
Write-Host " "([char]0x2611)"  FileBeat Installation Complete"
Start-Sleep 1


############################
#####     Hayabusa     #####
############################

LoadingAnimation { & "C:\WOLF\Scripts\Hayabusa.ps1" } " Installing Hayabusa"
Write-Host " "([char]0x2611)"  Hayabusa Installation Complete"
Start-Sleep 1


################################
#####     Finalisation     #####
################################

LoadingAnimation { & "C:\WOLF\Scripts\Finalisation.ps1"  }" Finalising"
Write-Host " "([char]0x2611)"  Finalisation Complete"
Start-Sleep 10
Write-Host " "