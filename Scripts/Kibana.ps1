##########################
#####     KIBANA     #####
##########################

# dot sourcing variables
. "C:\WOLF\Var.ps1"

# Install Kibana
New-Item -type Directory "$dirPath\Kibana" | Out-Null
Invoke-WebRequest -Uri $kibana_URL -OutFile "$dirPath\Kibana\kibana-$version-windows-x86_64.zip"
Expand-Archive "$dirPath\Kibana\kibana-$version-windows-x86_64.zip" -DestinationPath "$dirPath\Kibana\"
Remove-Item "$dirPath\Kibana\kibana-$version-windows-x86_64.zip"
Start-Sleep -Seconds 1

# Install NSSM
New-Item -type Directory "$dirPath\NSSM" | Out-Null
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $nssm_URL -OutFile "$dirPath\NSSM\nssm-2.24.zip"
Expand-Archive "$dirPath\NSSM\nssm-2.24.zip" -DestinationPath "$dirPath\NSSM"
Remove-Item "$dirPath\NSSM\nssm-2.24.zip"
Start-Sleep -Seconds 1

# Install Kibana Service
& "$dirPath\NSSM\nssm-2.24\win64\nssm.exe" install Kibana "$kibana_path\bin\kibana.bat"
& "$dirPath\NSSM\nssm-2.24\win64\nssm.exe" set Kibana AppDirectory "$kibana_path\bin" 
& "$dirPath\NSSM\nssm-2.24\win64\nssm.exe" set Kibana Start SERVICE_DELAYED_AUTO_START 
Start-Sleep -Seconds 1

# Enroll Kibana to ElasticSearch
$enrollment_token = & $elasticsearch_Path\bin\elasticsearch-create-enrollment-token.bat -s kibana
Start-Process cmd.exe -ArgumentList "/c $kibana_path\bin\kibana-setup.bat --enrollment-token $enrollment_token" -WindowStyle Normal
Start-Sleep -Seconds (3*60)

# Start Kibana
Start-Service -name Kibana
Start-Sleep -Seconds (1*60)