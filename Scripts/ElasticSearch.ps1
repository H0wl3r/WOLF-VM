#################################
#####     ElasticSearch     #####
#################################

# dot sourcing variables
. "C:\WOLF\Var.ps1"

# Install ElasticSearch
New-Item -type Directory "$dirPath\ElasticSearch" -force
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $elasticsearch_URL -OutFile "$dirPath\ElasticSearch\elasticsearch-$version-windows-x86_64.zip"
Expand-Archive "$dirPath\ElasticSearch\elasticsearch-$version-windows-x86_64.zip" -DestinationPath "$dirPath\ElasticSearch\"
Remove-Item "$dirPath\ElasticSearch\elasticsearch-$version-windows-x86_64.zip"

# Initiate ElasticSearch
$command = "$elasticsearch_Path\bin\elasticsearch.bat -s -p pid.txt"
$es_process = Start-Process cmd.exe -ArgumentList "/c $command"-WindowStyle hidden
start-sleep -seconds (3*60)
$es_pid = Get-Content "$elasticsearch_Path\pid.txt"
Stop-Process $es_pid
Remove-Item "$elasticsearch_Path\pid.txt"
Start-Sleep -Seconds (1*60)

# Get SHA256 Fingerprint from elasticsearch log
$eslog_file = "$elasticsearch_Path\logs\elasticsearch.log"
$content = Get-Content -Path $eslog_file -Raw
$pattern = 'SHA-256 fingerprint is \[([A-Fa-f0-9]+)\]'
$matches = [regex]::Matches($content, $pattern)
foreach ($match in $matches) {
    $fingerprint = $match.Groups[1].Value
}
$fingerprint | Out-File $elasticsearch_Path\fingerprint.txt
Start-Sleep -Seconds 1
attrib +h $elasticsearch_Path\fingerprint.txt
$ca_trust_fingerprint = Get-Content "$elasticsearch_Path\fingerprint.txt"

# Install ElasticSearch Service
$elasticsearch_service = "elasticsearch-service-x64"
& $elasticsearch_path\bin\elasticsearch-service.bat install -s
Set-Service -name $elasticsearch_service -StartupType automatic
Start-Service -name $elasticsearch_service
start-sleep -seconds (2*60)

# Import the certificate into the Windows Certificate Store
$certificateFilePath = "$elasticsearch_Path\config\certs\http_ca.crt"
Import-Certificate -FilePath $certificateFilePath -CertStoreLocation Cert:\LocalMachine\Root

# Ensure that the [System.Windows.Forms] assembly is loaded correctly 
[Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

# Reset elastic password
$password_reset = Start-Process cmd.exe -ArgumentList "/c $elasticsearch_Path\bin\elasticsearch-reset-password -u elastic -s -f > $elasticsearch_Path\elastic_password.txt" -WindowStyle normal
start-sleep -seconds 15
[System.Windows.Forms.SendKeys]::SendWait("y")
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
start-sleep -seconds 15
attrib +h $elasticsearch_Path\elastic_password.txt
$elastic_password = Get-content "$elasticsearch_Path\elastic_password.txt"
Start-Sleep -Seconds 1

# New User
$elasticsearch_user = "wolf"
$wolf_password = "forensics"
Start-Process cmd.exe -ArgumentList "/c $elasticsearch_Path\bin\elasticsearch-users.bat useradd $elasticsearch_user -p $wolf_password -r superuser" -WindowStyle Normal
Start-Sleep -Seconds 1