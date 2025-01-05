# dot sourcing variables
. "C:\WOLF\Scripts\Var.ps1"

$elasticsearchServer = "https://localhost:9200"
$indexName = "hayabusa"
$pipelineName = "hayabusa-pipeline"
$elasticPasswordFile = "C:\WOLF\ElasticSearch\elasticsearch-$version\elastic_password.txt"
$elastic_password = Get-Content $elasticPasswordFile
$username = "elastic"
$password = $elastic_password
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))
$hayabusa_Output = "C:\WOLF\Logs\Hayabusa\results.jsonl"
function HayabusaAnalysis {
    try {
        C:\WOLF\Hayabusa\hayabusa.exe json-timeline --no-wizard --output $hayabusa_Output --sort-events --GeoIP "\\wsl.localhost\Ubuntu-22.04\var\lib\GeoIP" --exclude-status deprecated,unsupported,experimental --min-level low --remove-duplicate-detections --clobber --JSONL-output --ISO-8601 --directory "C:\WOLF\Logs\WinLogs\" | Out-Null
        if (-not(Test-Path -Path $hayabusa_Output)) {
            exit 1
        }
    } catch {
        exit 1
    }
}
function HayabusaChunk {
    try {
        wsl bash /mnt/c/WOLF/Hayabusa/hayabusa.sh 2>$null
        $chunkDir = 
        if (-not(Get-ChildItem -Path "C:\WOLF\Logs\Hayabusa\chunks" | Where-Object { -not $_.PSIsContainer })) {
            Write-Host "Error: No Chunk files were found" -ForegroundColor Red
            exit 1
        }
    } catch {
        exit 1
    }
}
function HayabusaBulk {
    $chunkDir = "C:\WOLF\Logs\Hayabusa\chunks"
    $files = Get-ChildItem -Path $chunkDir -Filter "*.ndjson"
    
    foreach ($file in $files) {
        $bulkData = Get-Content -Path $file.FullName -Raw
        
        try {
            $bulkUri = "$elasticsearchServer/_bulk?pipeline=$pipelineName"
            $response = Invoke-RestMethod -Method Post -Uri $bulkUri `
                                          -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} `
                                          -Body ([System.Text.Encoding]::UTF8.GetBytes($bulkData)) `
                                          -ContentType "application/x-ndjson; charset=utf-8"
    
            if ($response.errors -eq $false) {
            } else {
                $hasErrors = $true
                $response.items | Where-Object { $_.index.error } | ForEach-Object {
                    $errorDetails += $_.index.error.reason
                }
            }
        } catch {
            $hasErrors = $true
            $errorDetails += $_.Exception.Message
        }
    }
    if (-not $hasErrors) {
        Write-Host -NoNewline " "([char]0x2611)
        Write-Host -NoNewline "  Hayabusa " -ForegroundColor Yellow
        Write-Host -NoNewline "Analysis Complete! The results have been successfully added to the Hayabusa index"
    } else {
        Write-Host "Errors occurred during bulk ingestion:" -ForegroundColor Red
        $errorDetails | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    }

}

# Main
HayabusaAnalysis
HayabusaChunk
HayabusaBulk
Remove-Item "C:\WOLF\Logs\Hayabusa\results.jsonl"
Remove-Item "C:\WOLF\Logs\Hayabusa\chunks" -Recurse -Force


