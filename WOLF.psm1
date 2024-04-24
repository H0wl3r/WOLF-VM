function WOLF-Remove-all_logs {
    $version = "8.13.2"
    $elasticsearchServer = "https://localhost:9200"
    $indexName = "winlogbeat-*"
    $elastic_password = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-8.13.2\elastic_password.txt"
    $requestBody = @{
        query = @{
            match_all = @{}
        }
    } | ConvertTo-Json

    # Set username and password if your Elasticsearch server requires authentication
    $username = "elastic"
    $password = "$elastic_password"
    # Convert username and password to Base64
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))
    # Send the request to delete all documents in the index
    $result = Invoke-RestMethod -Uri "$elasticsearchServer/$indexName/_delete_by_query" -Method Post -ContentType "application/json" -Body $requestBody -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
    $output = $result.deleted
    Write-Host ""
    Write-Host -NoNewline "["
    Write-Host -NoNewline "+" -ForegroundColor Cyan
    Write-Host -NoNewline "] "
    Write-Host -NoNewline "$output " -ForegroundColor Yellow 
    Write-Host -NoNewline "Windows EVTX Documents Deleted" 
    Write-Host "`n"
    Set-Content -Path "C:\WOLF\WinlogBeat\winlogbeat-$version-windows-x86_64\data\evtx-registry.yml" -value ""
}


function WOLF-Import-Windows_logs {
    $winlogs = "C:\WOLF\Logs\WinLogs"
    $version = "8.13.2"
    cd C:\WOLF\WinlogBeat\winlogbeat-$version-windows-x86_64
    # Filter by EVTX extension
    $dirs = Get-ChildItem -Path $winlogs -filter *.evtx
    $elastic_password = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-8.13.2\elastic_password.txt"
    $ca_trust_fingerprint = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-8.13.2\fingerprint.txt"
    Write-Host ""
    	# Create for loop to grab all .evtx files within selected folder
	foreach($file in $dirs){
        # Add shiny progress bar
		$filePath = $winlogs + "\" + $file
        $winlogbeat_template = @"
# WOLF Winlogbeat config
winlogbeat.event_logs:
 - name: $filePath
   no_more_events: stop
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
        # Execute Winlogbeat w/custom vars
		.\winlogbeat.exe -c .\winlogbeat.yml | Out-Null
        Write-Host -NoNewline "["
        Write-Host -NoNewline "+" -ForegroundColor Cyan
        Write-Host -NoNewline "] " 
        Write-Host -NoNewline "$file " -ForegroundColor Yellow
        Write-Host -NoNewline "has been added to the winlogbeat-* index`n"
        $i++
	}
    Write-Host ""
}

