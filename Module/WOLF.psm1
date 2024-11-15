function WOLF-Remove-All_logs {
    $indexPatterns = @("winlogbeat-*", "hayabusa", "filebeat-*")
    $version = "8.16.0"
    $elasticsearchServer = "https://localhost:9200"
    $elastic_password = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-$version\elastic_password.txt"
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

    $deletedCount = 0
    # Send the request to delete all documents in the index pattern list
    foreach ($indexPattern in $indexPatterns) {
        $result = Invoke-RestMethod -Uri "$elasticsearchServer/$indexPattern/_delete_by_query" -Method Post -ContentType "application/json" -Body $requestBody -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
        $deletedCount = $result.deleted
        Write-Host ""
        Write-Host -NoNewline " "([char]0x2611)  
        Write-Host -NoNewline "  $deletedCount " -ForegroundColor Yellow 
        Write-Host -NoNewline "Documents Deleted From $indexPattern" 
        Write-Host "`n"
    }
    Set-Content -Path "C:\WOLF\WinlogBeat\winlogbeat-$version-windows-x86_64\data\evtx-registry.yml" -Value ""
    Remove-Item -Path "C:\WOLF\Logs\Zeek\*" -Recurse -Force
}

function WOLF-Remove-Filebeat_logs {
    $version = "8.16.0"
    $elasticsearchServer = "https://localhost:9200"
    $indexName = "filebeat-*"
    $elastic_password = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-$version\elastic_password.txt"
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
    Write-Host -NoNewline " "([char]0x2611)  
    Write-Host -NoNewline "  $output " -ForegroundColor Yellow 
    Write-Host -NoNewline "FileBeat Documents Deleted" 
    Write-Host "`n"
    Remove-Item -Path "C:\WOLF\Logs\Zeek\*" -Recurse -Force
}

function WOLF-Remove-Hayabusa_logs {
    $version = "8.16.0"
    $elasticsearchServer = "https://localhost:9200"
    $indexName = "hayabusa"
    $elastic_password = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-$version\elastic_password.txt"
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
    Write-Host -NoNewline " "([char]0x2611)  
    Write-Host -NoNewline " $output " -ForegroundColor Yellow 
    Write-Host -NoNewline "Hayabusa Documents Deleted" 
    Write-Host "`n"
}

function WOLF-Remove-WinLogBeat_logs {
    $version = "8.16.0"
    $elasticsearchServer = "https://localhost:9200"
    $indexName = "winlogbeat-*"
    $elastic_password = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-$version\elastic_password.txt"
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
    Write-Host -NoNewline " "([char]0x2611)
    Write-Host -NoNewline "  $output " -ForegroundColor Yellow 
    Write-Host -NoNewline "WinLogBeat Documents Deleted" 
    Write-Host "`n"
    Set-Content -Path "C:\WOLF\WinlogBeat\winlogbeat-$version-windows-x86_64\data\evtx-registry.yml" -value ""
}

function WOLF-Import-Windows_logs {
    $version = "8.16.0"
    cd C:\WOLF\WinlogBeat\winlogbeat-$version-windows-x86_64
    # Filter by EVTX extension
    $winlogs = "C:\WOLF\Logs\WinLogs"
    $dirs = Get-ChildItem -Path $winlogs -filter *.evtx
    $elastic_password = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-$version\elastic_password.txt"
    $ca_trust_fingerprint = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-$version\fingerprint.txt"
    Write-Host ""

    # Create a list to hold all the event log entries
    $eventLogsConfig = @()

    foreach($file in $dirs) {
        $filePath = $winlogs + "\" + $file.Name
        # Add the file to the list of event log entries
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
    # Execute Winlogbeat w/custom vars
	.\winlogbeat.exe -c .\winlogbeat.yml | Out-Null
    foreach($file in $dirs) {
        Write-Host -NoNewline " "([char]0x2611)
        Write-Host -NoNewline "  $file " -ForegroundColor Yellow
        Write-Host -NoNewline "has been added to the winlogbeat-* index`n" 
    }
    Write-Host ""
}

function WOLF-Import-PCAP {
    $pcap_files = "C:\WOLF\Logs\PCAP"
    $zeek = "/opt/zeek/bin/zeek"
    $pcap_wsl = "/mnt/c/WOLF/Logs/PCAP"
    $dirs = Get-ChildItem -Path $pcap_files -filter *.pcap
    foreach($file in $dirs){
        Write-Host " "
        Write-Host -NoNewline " "([char]0x2611)
        Write-Host -NoNewline "  $file " -ForegroundColor Yellow
        Write-Host -NoNewline "is being analysed by Zeek`n"
        cd C:\WOLF\Logs\Zeek\
        wsl $zeek -C -r $pcap_wsl/$file LogAscii::use_json=T
        Write-Host -NoNewline " "([char]0x2611)
        Write-Host -NoNewline "  $file " -ForegroundColor Yellow
        Write-Host -NoNewline "has been analysed and added to the filebeat-* index`n"
        $i++
        Start-Sleep -Seconds 30
        Write-Host " "
    }
}

function WOLF-Import-Hayabusa_logs {
    $version = "8.16.0"
    $elasticsearchServer = "https://localhost:9200"
    $indexName = "hayabusa"
    $pipelineName = "hayabusa-pipeline"  # Add your pipeline name here
    $elasticPasswordFile = "C:\WOLF\ElasticSearch\elasticsearch-$version\elastic_password.txt"
    $elastic_password = Get-Content $elasticPasswordFile
    $hayabusa_Output = "C:\WOLF\Logs\Hayabusa\results.jsonl"
    $inputFilePath = $hayabusa_Output
    
    # Analysis EVTX logs with hayabusa
    C:\WOLF\Hayabusa\hayabusa.exe json-timeline --no-wizard --output $hayabusa_Output --sort-events --GeoIP "\\wsl.localhost\Ubuntu-22.04\var\lib\GeoIP" --exclude-status deprecated,unsupported,experimental --min-level low --remove-duplicate-detections --clobber --JSONL-output --ISO-8601 --directory "C:\WOLF\Logs\WinLogs\" | Out-Null

    # Set username and password for authentications with Elasticsearch server.
    $username = "elastic"
    $password = $elastic_password

    # Convert username and password to Base64 for Basic Authentication
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))

    # Verify that the input file exists
    if (-not (Test-Path -Path $inputFilePath)) {
        Write-Host "Error: Input file '$inputFilePath' not found." -ForegroundColor Red
        return
    }

    # Initialise bulkData variable
    $bulkData = ""

    # Read the file in chunks (streaming approach)
    Get-Content -Path $inputFilePath -Encoding utf8 | ForEach-Object {
        $line = $_

        # Skip empty lines
        if ([string]::IsNullOrWhiteSpace($line)) {
            return
        }

        # Manually format the index action line as a string without using document IDs
        $indexLine = "{ `"index`": { `"_index`": `"$indexName`" } }"

        # Append the index line and document line to the bulk request data
        $bulkData += "$indexLine`n"
        $bulkData += "$line`n"
    }

    # Perform the bulk ingestion to Elasticsearch using the Bulk API with a pipeline
    try {
        $bulkUri = "$elasticsearchServer/_bulk?pipeline=$pipelineName"
        $bulkBytes = [System.Text.Encoding]::UTF8.GetBytes($bulkData)  # Ensure the data is UTF-8 encoded
        $response = Invoke-RestMethod -Method Post -Uri $bulkUri `
                                      -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} `
                                      -Body $bulkBytes -ContentType "application/x-ndjson; charset=utf-8"

        # Check for errors in the response
        if ($response.errors -eq $false) {
            Write-Host -NoNewline "`n "([char]0x2611)
            Write-Host -NoNewline "  Hayabusa " -ForegroundColor Yellow
            Write-Host -NoNewline "Analysis Complete! The results have been successfully added to the Hayabusa index`n"
            Write-Host " "
        } else {
            Write-Host "Errors occurred during bulk ingestion:" -ForegroundColor Red
            $response.items | Where-Object { $_.index.error } | ForEach-Object {
                Write-Host $_.index.error.reason -ForegroundColor Red
            }
        }
    } catch {
        Write-Host " "
        Write-Host "Error occurred during the bulk ingestion: $_" -ForegroundColor Red
        Write-Host " "
    }
}

function WOLF-Update-Hayabusa_Rules {
    C:\WOLF\Hayabusa\hayabusa.exe update-rules
}

function WOLF-Update-GeoIP{
    wsl -u root -- wget https://raw.githubusercontent.com/H0wl3r/WOLF-VM/refs/heads/main/GeoIP/GeoLite2-City.mmdb -O /var/lib/GeoIP/GeoLite2-City.mmdb
    wsl -u root -- wget https://raw.githubusercontent.com/H0wl3r/WOLF-VM/refs/heads/main/GeoIP/GeoLite2-Country.mmdb -O /var/lib/GeoIP/GeoLite2-Country.mmdb
    wsl -u root -- wget https://raw.githubusercontent.com/H0wl3r/WOLF-VM/refs/heads/main/GeoIP/GeoLite2-ASN.mmdb -O /var/lib/GeoIP/GeoLite2-ASN.mmdb
}


