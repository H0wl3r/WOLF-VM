##################################
#####     INITIALISATION     #####
##################################

# dot sourcing variables
. "C:\WOLF\Var.ps1"

# So we can run other powershell scripts within this script
Set-ExecutionPolicy Bypass -Scope Process -f | Out-Null

# Create Wolf Directory 
New-Item -type Directory $dirPath -force | Out-Null

# Define the list of scripts and URL locations.
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
    $outputPath = "$dirPath\" + $file.FileName
    Invoke-WebRequest -Uri $file.URL -OutFile $outputPath
}

Start-Sleep -Seconds 5

# Disable screen saver
powercfg -change -standby-timeout-ac 0
powercfg -change -monitor-timeout-ac 0

# Set battery sleep settings to never
powercfg -change -standby-timeout-dc 0
powercfg -change -monitor-timeout-dc 0

# Disable UAC Prompt pop ups
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0
Stop-Process -Name explorer -Force
start-sleep -Seconds 5
