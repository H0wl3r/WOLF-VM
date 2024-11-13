##########################
#####     KIBANA     #####
##########################

# dot sourcing variables
. "C:\WOLF\Scripts\Var.ps1"

# Install Kibana
New-Item -type Directory "$dirPath\Kibana" | Out-Null
Invoke-WebRequest -Uri $kibana_URL -OutFile "$dirPath\Kibana\kibana-$version-windows-x86_64.zip"
Expand-Archive "$dirPath\Kibana\kibana-$version-windows-x86_64.zip" -DestinationPath "$dirPath\Kibana\"
Remove-Item "$dirPath\Kibana\kibana-$version-windows-x86_64.zip"
Start-Sleep -Seconds 1

# Install NSSM
New-Item -type Directory "$dirPath\NSSM" | Out-Null
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $nssm_URL -OutFile "$dirPath\NSSM\nssm.exe"
Start-Sleep -Seconds 1

# Install Kibana Service
& "$dirPath\NSSM\nssm.exe" install Kibana "$kibana_Path\bin\kibana.bat"
& "$dirPath\NSSM\nssm.exe" set Kibana AppDirectory "$kibana_Path\bin" 
& "$dirPath\NSSM\nssm.exe" set Kibana Start SERVICE_DELAYED_AUTO_START 
Start-Sleep -Seconds 1

# Enroll Kibana to ElasticSearch
$enrollment_token = & $elasticsearch_Path\bin\elasticsearch-create-enrollment-token.bat -s kibana
start-sleep -Seconds (1*60)
Start-Process cmd.exe -ArgumentList "/c $kibana_Path\bin\kibana-setup.bat --enrollment-token $enrollment_token" -WindowStyle Normal
Start-Sleep -Seconds (3*60)

# To set a persistent key, add the xpack.encryptedSavedObjects.encryptionKey setting with any text value of 32 or more characters to the kibana.yml file. 
Add-Content -Path "c:\WOLF\Kibana\kibana-$version\config\kibana.yml" -Value "xpack.encryptedSavedObjects.encryptionKey: AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"

# Edit host name for kibana server
Add-Content -Path "c:\Windows\System32\Drivers\etc\hosts" -Value "# WOLF VM DNS name"
Add-Content -Path "c:\Windows\System32\Drivers\etc\hosts" -Value "127.0.0.1 wolf.local.vm"

# Define the path to the Kibana configuration file
$configFilePath = "$kibana_Path\config\kibana.yml"
$configContent = Get-Content -Path $configFilePath
# This will match both localhost and IP addresses like 'https://127.0.0.1:9200' or 'https://192.168.x.x:9200'
$pattern = 'https://[^\s:]+:9200'
# Replace the matched URL with 'https://wolf.local.vm:9200'
$kibanaconfupdate = $configContent -replace $pattern, 'https://localhost:9200'
$kibanaconfupdate | Set-Content -Path $configFilePath

# Start Kibana
Start-Service -name Kibana
Start-Sleep -Seconds (1*60)








