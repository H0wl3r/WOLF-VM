############################
#####     HAYABUSA     #####
############################

# dot sourcing variables
. "C:\WOLF\Scripts\Var.ps1"

# Install Hayabusa
Expand-Archive "$dirPath\Hayabusa\hayabusa-$hayabusa_version-win-x64.zip" -DestinationPath "$dirPath\Hayabusa\"
Rename-Item -Path "$dirPath\Hayabusa\hayabusa-$hayabusa_version-win-x64.exe" -NewName "$dirPath\Hayabusa\hayabusa.exe"
Remove-Item "$dirPath\Hayabusa\hayabusa-$hayabusa_version-win-x64.zip"
C:\WOLF\Hayabusa\hayabusa.exe update-rules

function WOLF-Create-HayabusaPipeline {
    $version = "8.17.0"
    $elasticsearchServer = "https://localhost:9200"
    $pipelineName = "hayabusa-pipeline"
    $elastic_password = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-$version\elastic_password.txt"
    
    # request body for the ingest pipeline
    $requestBody = @{
        description = "Pipeline for parsing hayabusa JSONL logs"
        processors = @(
            @{
                script = @{
                    source = "if (ctx.containsKey('Details') && ctx.Details.containsKey('')) { ctx.Details.put('AdditionalInfo', ctx.Details.remove(''));}"
                }
            },
            @{
                date = @{
                    field = "Timestamp"
                    formats = @("ISO8601")
                    output_format = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSSXXX"
                }
            }
        )
    } | ConvertTo-Json -Depth 10

    $username = "elastic"
    $password = "$elastic_password"
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))
    # Send the request to create the ingest pipeline
    $result = Invoke-RestMethod -Uri "$elasticsearchServer/_ingest/pipeline/$pipelineName" -Method Put -ContentType "application/json" -Body $requestBody -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
}
WOLF-Create-HayabusaPipeline

function WOLF-Create-HayabusaIndex {
    $version = "8.17.0"
    $elasticsearchServer = "https://localhost:9200"
    $indexName = "hayabusa"  
    $elastic_password = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-$version\elastic_password.txt"
    $username = "elastic"
    $password = "$elastic_password"

    # index body with settings and mappings
    $indexBody = @{
        settings = @{
            number_of_shards = 1
            number_of_replicas = 0
        }
        mappings = @{
            properties = @{
                "@timestamp" = @{
                    type = "date_nanos"
                }
                "Channel" = @{
                    type = "keyword"
                }
                "Computer" = @{
                    type = "keyword"
                }
                "Details" = @{
                    type = "object"
                    properties = @{
                        "PID" =@{
                            type = "keyword"
                        }
                        "AdditionalInfo" = @{
                            type = "keyword"
                        }
                    }
                }
                "EventID" = @{
                    type = "long"
                }
                "EvtxFile" = @{
                    type = "keyword"
                }
                "ExtraFieldInfo" = @{
                    type = "object"
                    properties = @{
                        "ProcessId" = @{
                            type = "keyword"
                        }
                        "Data[1]" = @{
                            type = "keyword"
                        }
                        "Data[2]" = @{
                            type = "keyword"
                        }
                        "Data[3]" = @{
                            type = "keyword"
                        }
                        "Data[4]" = @{
                            type = "keyword"
                        }
                        "Data[5]" = @{
                            type = "keyword"
                        }
                    }
                }
                "Level" = @{
                    type = "keyword"
                }
                "MitreTactics" = @{
                    type = "keyword"
                }
                "MitreTags" = @{
                    type = "keyword"
                }
                "OtherTags" = @{
                    type = "keyword"
                }
                "RecordID" = @{
                    type = "keyword"
                }
                "RuleFile" = @{
                    type = "keyword"
                }
                "RuleTitle" = @{
                    type = "keyword"
                }
            }
        }
    }

    
    $indexBodyJson = $indexBody | ConvertTo-Json -Depth 10
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))

    # Set the Elasticsearch index API URL
    $indexUrl = "$elasticsearchServer/$indexName"

    # Send the PUT request to create the index with settings and mappings
    $result = Invoke-RestMethod -Uri $indexUrl -Method Put -ContentType "application/json" -Body $indexBodyJson -Headers @{
        Authorization = ("Basic {0}" -f $base64AuthInfo)
    }
    Write-Host "Index '$indexName' has been successfully created in Elasticsearch."
}
WOLF-Create-HayabusaIndex

function WOLF-Create-DataViewFromJson {
    $version = "8.17.0"
    $kibanaServer = "http://localhost:5601"
    $dataViewFile = "C:\WOLF\Hayabusa\hayabusa_dataview.json"
    $elastic_password = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-$version\elastic_password.txt"
    $username = "elastic"
    $password = "$elastic_password"

    $dataViewBodyJson = Get-Content $dataViewFile -Raw
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))

    # Set the Kibana Data View API URL
    $dataViewUrl = "$kibanaServer/api/data_views/data_view"

    # Create the Data View using the body from the JSON file
    $result = Invoke-RestMethod -Uri $dataViewUrl -Method Post -ContentType "application/json" -Body $dataViewBodyJson -Headers @{
        Authorization = ("Basic {0}" -f $base64AuthInfo)
        "kbn-xsrf" = "true"
    }

    # Output success message
    Write-Host "Data View has been successfully created in Kibana."
}
WOLF-Create-DataViewFromJson

function WOLF-Upload-HayabusaObjects {
    $version = "8.17.0"
    $kibanaServer = "http://localhost:5601"  
    $savedObjectsFile = "C:\WOLF\KibanaObjects\hayabusa.ndjson" 
    $elastic_password = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-$version\elastic_password.txt"
    $username = "elastic"
    $password = $elastic_password

    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))
    $url = "$kibanaServer/api/saved_objects/_import"

    # Create the request headers
    $headers = @{
        "kbn-xsrf" = "true"
        "Authorization" = "Basic $base64AuthInfo"
    }

    # Create the multipart form data body
    $boundary = "----WebKitFormBoundary" + [guid]::NewGuid().ToString("N")
    $fileContent = Get-Content -Path $savedObjectsFile -Raw
    $body = "--$boundary`r`n" +
            "Content-Disposition: form-data; name=`"file`"; filename=`"$(Split-Path $savedObjectsFile -Leaf)`"`r`n" +
            "Content-Type: application/x-ndjson`r`n`r`n" +
            "$fileContent`r`n" +
            "--$boundary--"

    try {
        Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body -ContentType "multipart/form-data; boundary=$boundary"
    } catch {
        Write-Host "An error occurred: $_"
    }
}
WOLF-Upload-HayabusaObjects


