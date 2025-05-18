function LoadingAnimation($scriptBlock, $message) {
    $cursorTop = [Console]::CursorTop

    try {
        [Console]::CursorVisible = $false
        $counter = 0
        $frames = ' |', ' /', ' -', ' \'

        # Start the job to run the script block
        $jobName = Start-Job -ScriptBlock $scriptBlock

        while ($jobName.JobStateInfo.State -eq "Running") {
            $frame = $frames[$counter % $frames.Length]
            
            Write-Host " $frame  $message" -NoNewLine
            [Console]::SetCursorPosition(0, $cursorTop)
            
            $counter += 1
            Start-Sleep -Milliseconds 125
        }

        # Handle job completion
        Receive-Job -Job $jobName -ErrorAction Stop | Out-Null

        if ($jobName.JobStateInfo.State -eq "Failed") {
            Write-Host "Error: " -ForegroundColor Red -NoNewLine
            $errorMessages = ($jobName.ChildJobs | Where-Object { $_.Error -ne $null }).Error
            $errorMessages | ForEach-Object {
                Write-Host $_.Exception.Message
            }
        }
    } catch {
        Write-Host "An unexpected error occurred: $_" -ForegroundColor Red
    } finally {
        [Console]::SetCursorPosition(0, $cursorTop)
        [Console]::CursorVisible = $true
        Write-Host "" # Clear the loading animation

        # Clean up the job
        Remove-Job -Job $jobName -Force -ErrorAction SilentlyContinue
    }
}
function WOLF-Remove-All_logs {
    $indexPatterns = @("winlogbeat-*", "hayabusa", "filebeat-*")
    $version = "9.0.1"
    $elasticsearchServer = "https://localhost:9200"
    $elastic_password = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-$version\elastic_password.txt"
    $requestBody = @{
        query = @{
            match_all = @{}
        }
    } | ConvertTo-Json

    $username = "elastic"
    $password = "$elastic_password"
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))  

    $deletedCount = 0
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
    $version = "9.0.1"
    $elasticsearchServer = "https://localhost:9200"
    $indexName = "filebeat-*"
    $elastic_password = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-$version\elastic_password.txt"
    $requestBody = @{
        query = @{
            match_all = @{}
        }
    } | ConvertTo-Json

    $username = "elastic"
    $password = "$elastic_password"
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))   
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
    $version = "9.0.1"
    $elasticsearchServer = "https://localhost:9200"
    $indexName = "hayabusa"
    $elastic_password = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-$version\elastic_password.txt"
    $requestBody = @{
        query = @{
            match_all = @{}
        }
    } | ConvertTo-Json

    $username = "elastic"
    $password = "$elastic_password"
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))
    $result = Invoke-RestMethod -Uri "$elasticsearchServer/$indexName/_delete_by_query" -Method Post -ContentType "application/json" -Body $requestBody -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
    $output = $result.deleted
    Write-Host ""
    Write-Host -NoNewline " "([char]0x2611)  
    Write-Host -NoNewline "  $output " -ForegroundColor Yellow 
    Write-Host -NoNewline "Hayabusa Documents Deleted" 
    Write-Host "`n"
}

function WOLF-Remove-WinLogBeat_logs {
    $version = "9.0.1"
    $elasticsearchServer = "https://localhost:9200"
    $indexName = "winlogbeat-*"
    $elastic_password = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-$version\elastic_password.txt"
    $requestBody = @{
        query = @{
            match_all = @{}
        }
    } | ConvertTo-Json

    $username = "elastic"
    $password = "$elastic_password"
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))
    
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
    Write-Host ""
    LoadingAnimation { & "C:\WOLF\Module\Import-Windows_logs.ps1" } " Importing Windows Logs"
    Write-Host " "
    Start-Sleep 1
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
    Write-Host ""
    LoadingAnimation { & "C:\WOLF\Module\Import-Hayabusa_logs.ps1" } " Importing Hayabusa Logs"
    Write-Host " "
    Start-Sleep 1
}

function WOLF-Update-Hayabusa_Rules {
    C:\WOLF\Hayabusa\hayabusa.exe update-rules
}

function WOLF-Update-GeoIP{
    wsl -u root -- wget https://raw.githubusercontent.com/H0wl3r/WOLF-VM/refs/heads/main/GeoIP/GeoLite2-City.mmdb -O /var/lib/GeoIP/GeoLite2-City.mmdb
    wsl -u root -- wget https://raw.githubusercontent.com/H0wl3r/WOLF-VM/refs/heads/main/GeoIP/GeoLite2-Country.mmdb -O /var/lib/GeoIP/GeoLite2-Country.mmdb
    wsl -u root -- wget https://raw.githubusercontent.com/H0wl3r/WOLF-VM/refs/heads/main/GeoIP/GeoLite2-ASN.mmdb -O /var/lib/GeoIP/GeoLite2-ASN.mmdb
}


