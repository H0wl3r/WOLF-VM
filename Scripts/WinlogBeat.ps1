##############################
#####     WINLOGBEAT     #####
##############################

# dot sourcing variables
. "C:\WOLF\Scripts\Var.ps1"
. "C:\WOLF\Scripts\ElasticSearch.ps1"

# Install WinlogBeat
New-Item -Path "$dirPath\WinlogBeat" -ItemType Directory -Force | Out-Null
Invoke-WebRequest $winlogbeat_URL -OutFile "$dirPath\WinlogBeat\winlogbeat-$version-windows-x86_64.zip"
Expand-Archive "$dirPath\WinlogBeat\winlogbeat-$version-windows-x86_64.zip" -DestinationPath "$dirPath\WinlogBeat"
Remove-Item "$dirPath\WinlogBeat\winlogbeat-$version-windows-x86_64.zip"

& "$dirPath\WinlogBeat\winlogbeat-$version-windows-x86_64\install-service-winlogbeat.ps1"

$winlogbeat_template = @"
# WOLF Winlogbeat config
winlogbeat.event_logs:
 - name: $filePath
   no_more_events: stop
winlogbeat.shutdown_timeout: 60s
winlogbeat.registry_file: evtx-registry.yml

setup.kibana:

# Allow ELK to see active connections
monitoring.enabled: true
output.elasticsearch:
  hosts: ["https://localhost:9200"]
  username: "elastic"
  password: "$elastic_password"
  ssl:
    enabled: true
    ca_trusted_fingerprint: "$ca_trust_fingerprint"
"@

Remove-Item -Path "$dirPath\WinlogBeat\winlogbeat-$version-windows-x86_64\kibana\7" -Recurse -Force

$winlogbeat_template | Out-File $dirPath\WinlogBeat\winlogbeat-$version-windows-x86_64\winlogbeat.yml -Encoding UTF8
& "$dirPath\WinlogBeat\winlogbeat-$version-windows-x86_64\winlogbeat.exe" setup -e -E 'setup.dashboards.enabled=false' -c "$dirPath\WinlogBeat\winlogbeat-$version-windows-x86_64\winlogbeat.yml"
Start-Sleep -Seconds 10
Start-Service winlogbeat
Start-Sleep -Seconds 10