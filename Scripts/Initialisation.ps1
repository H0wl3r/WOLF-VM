##################################
#####     INITIALISATION     #####
##################################

# dot sourcing variables
. "C:\WOLF\Scripts\Var.ps1"

# So we can run other powershell scripts within this script
Set-ExecutionPolicy Bypass -Scope Process -f | Out-Null

# Disable screen saver
powercfg -change -standby-timeout-ac 0
powercfg -change -monitor-timeout-ac 0

# Set battery sleep settings to never
powercfg -change -standby-timeout-dc 0
powercfg -change -monitor-timeout-dc 0

# Disable UAC Prompt pop ups
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 0
New-NetFirewallRule -DisplayName "Allow OpenJDK Inbound" -Direction Inbound -Program "$elasticsearch_path\jdk\bin\java.exe" -Action Allow
New-NetFirewallRule -DisplayName "Allow OpenJDK Outbound" -Direction Outbound -Program "$elasticsearch_path\jdk\bin\java.exe" -Action Allow
Start-Sleep -Seconds 5
Stop-Process -name explorer -Force
Start-Sleep -Seconds 10

# Disable Microsoft Defender
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1

# Install jq
wsl -u root -- apt install jq -y