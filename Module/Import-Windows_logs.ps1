$version = "9.0.1"

$winlogs = "C:\WOLF\Logs\WinLogs"
$dirs = Get-ChildItem -Path $winlogs -filter *.evtx
$elastic_password = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-$version\elastic_password.txt"
$ca_trust_fingerprint = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-$version\fingerprint.txt"



if (-not $dirs) {
    Write-Host "Error: No .EVTX files were found" -ForegroundColor Red
    exit
}
cd C:\WOLF\WinlogBeat\winlogbeat-$version-windows-x86_64
function WindowsConfig {
    
    $eventLogsConfig = @()
    foreach($file in $dirs) {
        $filePath = $winlogs + "\" + $file.Name
        $eventLogsConfig += "  - name: $filePath"
        $eventLogsConfig += "    no_more_events: stop"
    }
    # Combine all event logs into the Winlogbeat config template
    $winlogbeat_template = @"
# WOLF Winlogbeat config
winlogbeat.event_logs:
$($eventLogsConfig -join "`r`n")
winlogbeat.shutdown_timeout: 60s
winlogbeat.registry_file: evtx-registry.yml

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
    $winlogbeat_template | Out-File "C:\WOLF\WinlogBeat\winlogbeat-$version-windows-x86_64\winlogbeat.yml" -Encoding UTF8
}
WindowsConfig

.\winlogbeat.exe -c .\winlogbeat.yml | Out-Null
Write-Host -NoNewline " "([char]0x2611)
Write-Host -NoNewline "  WinLogBeat " -ForegroundColor Yellow
Write-Host -NoNewline "Import Complete! The .EVTX logs have been successfully added to the winlogbeat-* index"