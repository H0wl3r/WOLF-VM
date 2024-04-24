<#
    .SYNOPSIS
        Installation script for WOLF VM.
        ** Only install on a virtual machine! **

    .DESCRIPTION
        Installation script for WOLF VM leverages Chocolatey and Elastic
        Script verifies minimal settings necessary to install WOLF VM on a virtual machine..

        To execute this script:
          1) Open PowerShell window as administrator
          2) Allow script execution by running command "Set-ExecutionPolicy Bypass -Scope Process -Force"
          3) Unblock the install script by running "Unblock-File ./wolfvm_install.ps1"
          4) Execute the script by running ".\wolfvm_install.ps1"

    #.PARAMETER password
        Current user password to allow reboot resiliency via Boxstarter. The script prompts for the password if not provided.

    .EXAMPLE
        .\wolfvm_install.ps1

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
        $frames = '|', '/', '-', '\' 
        $jobName = Start-Job -ScriptBlock $scriptBlock
    
        while($jobName.JobStateInfo.State -eq "Running") {
            $frame = $frames[$counter % $frames.Length]
            
            Write-Host "$message $frame" -NoNewLine
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
        Write-Host "`t[!] Please run this script as administrator" -ForegroundColor Red
        Read-Host "Press any key to exit..."
        exit 1

####################################
#####     Download Scripts     #####
####################################

$VarScript_URL = "1"
$InitialisationScript_URL = "2"
$ElasticSearchScript_URL = "3"
$KibanaScript_URL = "4"
$WinlogBeatScript_URL = "5"

$ScriptDownloads = @($VarScript_URL, $InitialisationScript_URL, $ElasticSearchScript_URL, $KibanaScript_URL, $WinlogBeatScript_URL)


# Define a list of objects
$fileList = @(
    [PSCustomObject]@{
        FileName = "Var.ps1"
        URL = "https://raw.githubusercontent.com/username/repository/branch/path/to/file1.txt"
    },
    [PSCustomObject]@{
        FileName = "Initialisation.ps1"
        URL = "https://raw.githubusercontent.com/username/repository/branch/path/to/file2.txt"
    },
        [PSCustomObject]@{
        FileName = "ElasticSearch.ps1"
        URL = "https://raw.githubusercontent.com/username/repository/branch/path/to/file2.txt"
    },
        [PSCustomObject]@{
        FileName = "Kibana.ps1"
        URL = "https://raw.githubusercontent.com/username/repository/branch/path/to/file2.txt"
    },
        [PSCustomObject]@{
        FileName = "WinlogBeat.ps1"
        URL = "https://raw.githubusercontent.com/username/repository/branch/path/to/file2.txt"
    }
)

# Loop through the list and download each file
foreach ($file in $fileList) {
    $outputPath = "C:\WOLF\" + $file.FileName
    Invoke-WebRequest -Uri $file.URL -OutFile $outputPath
}


##################################
#####     INITIALISATION     #####
##################################

LoadingAnimation { & "C:\WOLF\Initialisation.ps1" } "    Initialising    "
Write-Host ([char]0x2611)"  Initalisation Complete"

#################################
#####     ElasticSearch     #####
#################################

LoadingAnimation { & "C:\WOLF\ElasticSearch.ps1" } "    Installing ElasticSearch    "
Write-Host ([char]0x2611)"  Installation of ElasticSearch Complete"

##########################
#####     KIBANA     #####
##########################

LoadingAnimation { & "C:\WOLF\Kibana.ps1" } "    Installing Kibana    "
Write-Host ([char]0x2611)"  Installation of Kibana Complete"


##############################
#####     WINLOGBEAT     #####
##############################

LoadingAnimation { & "C:\WOLF\WinlogBeat.ps1" } "    Installing WinlogBeat    "
Write-Host ([char]0x2611)"  Installation of WinlogBeat Complete"


############################
#####     FileBeat     #####
############################

#Install WinlogBeat
#New-Item -Path "$dirPath\FileBeat" -ItemType Directory -Force | Out-Null



#############################
#####     WOLF.psm1     #####
#############################

# Download .psm1 file from github and install module
#$PS_module = "WOLF"
#$PS_modules = "C:\Program Files\WindowsPowerShell\Modules"
#New-Item -Type Directory "$PS_modules\$PS_module" | Out-Null
#Invoke-WebRequest -Uri $WOLF_psm1_URL -OutFile "$PS_modules\$PS_module\WOLF.psm1"
