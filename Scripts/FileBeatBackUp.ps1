##############################
#####     FileBeat     #####
##############################

# dot sourcing variables
. "C:\WOLF\Var.ps1"
. "C:\WOLF\ElasticSearch.ps1"

# Install FileBeat
New-Item -Path "$dirPath\FileBeat" -ItemType Directory -Force | Out-Null
Invoke-WebRequest $filebeat_URL -OutFile "$dirPath\FileBeat\filebeat-$version-windows-x86_64.zip"
Expand-Archive "$dirPath\FileBeat\filebeat-$version-windows-x86_64.zip" -DestinationPath "$dirPath\filebeat"
Remove-Item "$dirPath\FileBeat\filebeat-$version-windows-x86_64.zip"

Get-ChildItem -Path $dirPath\FileBeat\filebeat-$version-windows-x86_64\module -Directory | Where-Object { $_.Name -ne 'zeek' -and $_.Name -ne 'system'} | Remove-Item -Recurse -Force

& "$dirPath\FileBeat\filebeat-$version-windows-x86_64\install-service-filebeat.ps1"

$filebeat_template = @"
# WOLF FileBeat config
filebeat.inputs:

filebeat.config.modules:
  path: $dirPath/FileBeat/filebeat-$version-windows-x86_64/modules.d/*.yml
  reload.enabled: true

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

$filebeat_template | Out-File $dirPath\FileBeat\filebeat-$version-windows-x86_64\filebeat.yml -Encoding UTF8

& "$dirPath\FileBeat\filebeat-$version-windows-x86_64\filebeat.exe" module enable zeek, system

Remove-Item -Path $dirPath\FileBeat\filebeat-$version-windows-x86_64\modules.d\*.disabled

$zeek_module = @"
- module: zeek
  capture_loss:
    enabled: true
  connection:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/conn.log]
  dce_rpc:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/dce_rpc.log]
  dhcp:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/dhcp.log]
  dnp3:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/dnp3.log]
  dns:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/dns.log]
  dpd:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/dpd.log]
  files:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/files.log]
  ftp:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/ftp.log]
  http:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/http.log]
  intel:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/intel.log]
  irc:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/irc.log]
  kerberos:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/kerberos.log]
  modbus:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/modbus.log]
  mysql:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/mysql.log]
  notice:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/notice.log]
  ntp:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/ntp.log]
  ntlm:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/ntlm.log]
  ocsp:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/ocsp.log]
  pe:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/pe.log]
  radius:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/radius.log]
  rdp:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/rdp.log]
  rfb:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/rfb.log]
  signature:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/signature.log]
  sip:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/sip.log]
  smb_cmd:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/smb_cmd.log]
  smb_files:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/smb_files.log]
  smb_mapping:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/smb_mapping.log]
  smtp:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/smtp.log]
  snmp:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/snmp.log]
  socks:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/socks.log]
  ssh:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/ssh.log]
  ssl:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/ssl.log]
  stats:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/stats.log]
  syslog:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/syslog.log]
  traceroute:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/traceroute.log]
  tunnel:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/tunnel.log]
  weird:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/weird.log]
  x509:
    enabled: true
    var.paths: [C:/WOLF/Logs/Zeek/x509.log]
"@

$zeek_module | Out-File "$dirPath/FileBeat/filebeat-$version-windows-x86_64/modules.d/zeek.yml"

$system_module = @"
- module: system
  syslog:
    enabled: true
    var.paths: ["C:\WOLF\Logs\System\syslog*"]
  auth:
    enabled: true
    var.paths: ["C:\WOLF\Logs\System\auth.log*"]
"@

$system_module | Out-File "$dirPath/FileBeat/filebeat-$version-windows-x86_64/modules.d/system.yml"

remove-item -Path "$dirPath\FileBeat\filebeat-$version-windows-x86_64\kibana\8" -Recurse -Force
remove-item -Path "$dirPath\FileBeat\filebeat-$version-windows-x86_64\kibana\7" -Recurse -Force
# remove-item -Path "$dirPath\FileBeat\filebeat-$version-windows-x86_64\kibana\7\map" -Recurse -Force
# remove-item -Path "$dirPath\FileBeat\filebeat-$version-windows-x86_64\kibana\7\tag" -Recurse -Force
# remove-item -Path "$dirPath\FileBeat\filebeat-$version-windows-x86_64\kibana\7\lens" -Recurse -Force

$dashboardsFolder = "$dirPath\FileBeat\filebeat-$version-windows-x86_64\kibana\7\dashboard"  
$filesToKeep = @(
    "0d3f2380-fa78-11e6-ae9b-81e5311e8cab-ecs.json",
    "277876d0-fa2c-11e6-bbd3-29c986c96e5a-ecs.json",
    "5517a150-f9ce-11e6-8115-a7c18106d86a-ecs.json",
    "Filebeat-syslog-dashboard-ecs.json",
    "Filebeat-Zeek-Overview.json"
)
$allFiles = Get-ChildItem -Path $dashboardsFolder -File
foreach ($file in $allFiles) {
    if ($filesToKeep -notcontains $file.Name) {
        Remove-Item -Path $file.FullName -Force
    }
}

$visualizationFolder = "$dirPath\FileBeat\filebeat-$version-windows-x86_64\kibana\7\visualization" 
$filesToKeep = @(
    "f469f230-370c-11e9-aa6d-ff445a78330c.json",
    "1df7ea80-370d-11e9-aa6d-ff445a78330c.json",
    "466e5850-370d-11e9-aa6d-ff445a78330c.json",
    "649acd40-370d-11e9-aa6d-ff445a78330c.json",
    "9436c270-370d-11e9-aa6d-ff445a78330c.json",
    "bec2f0e0-370d-11e9-aa6d-ff445a78330c.json",
    "e042fda0-370d-11e9-aa6d-ff445a78330c.json",
    "f8c40810-370d-11e9-aa6d-ff445a78330c.json",
    "Syslog-events-by-hostname-ecs.json",
    "Syslog-hostnames-and-processes-ecs.json",
    "327417e0-8462-11e7-bab8-bd2f0fb42c54-ecs.json",
    "d16bb400-f9cc-11e6-8115-a7c18106d86a-ecs.json",
    "78b74f30-f9cd-11e6-8115-a7c18106d86a-ecs.json",
    "341ffe70-f9ce-11e6-8115-a7c18106d86a-ecs.json",
    "3cec3eb0-f9d3-11e6-8a3e-2b904044ea1d-ecs.json",
    "327417e0-8462-11e7-bab8-bd2f0fb42c54-ecs.json",
    "5c7af030-fa2a-11e6-bbd3-29c986c96e5a-ecs.json",
    "51164310-fa2b-11e6-bbd3-29c986c96e5a-ecs.json",
    "dc589770-fa2b-11e6-bbd3-29c986c96e5a-ecs.json",
    "327417e0-8462-11e7-bab8-bd2f0fb42c54-ecs.json",
    "f398d2f0-fa77-11e6-ae9b-81e5311e8cab-ecs.json",
    "5dd15c00-fa78-11e6-ae9b-81e5311e8cab-ecs.json",
    "e121b140-fa78-11e6-a1df-a78bd7504d38-ecs.json",
    "d56ee420-fa79-11e6-a1df-a78bd7504d38-ecs.json",
    "12667040-fa80-11e6-a1df-a78bd7504d38-ecs.json",
    "346bb290-fa80-11e6-a1df-a78bd7504d38-ecs.json",
    "327417e0-8462-11e7-bab8-bd2f0fb42c54-ecs.json"
)
$allFiles = Get-ChildItem -Path $visualizationFolder -File
foreach ($file in $allFiles) {
    if ($filesToKeep -notcontains $file.Name) {
        Remove-Item -Path $file.FullName -Force
    }
}

$searchFolder = "$dirPath\FileBeat\filebeat-$version-windows-x86_64\kibana\7\search"  
$filesToKeep = @(
    "Syslog-system-logs-ecs.json",
    "62439dc0-f9c9-11e6-a747-6121780e0414-ecs.json",
    "8030c1b0-fa77-11e6-ae9b-81e5311e8cab-ecs.json",
    "b6f321e0-fa25-11e6-bbd3-29c986c96e5a-ecs.json"
)
$allFiles = Get-ChildItem -Path $searchFolder -File
foreach ($file in $allFiles) {
    if ($filesToKeep -notcontains $file.Name) {
        Remove-Item -Path $file.FullName -Force
    }
}

& "$dirPath\FileBeat\filebeat-$version-windows-x86_64\filebeat.exe" setup -e -c "$dirPath\FileBeat\filebeat-$version-windows-x86_64\FileBeat.yml"
# & "$dirPath\FileBeat\filebeat-$version-windows-x86_64\filebeat.exe" setup --modules zeek -e -E 'setup.dashboards.enabled=true'
# & "$dirPath\FileBeat\filebeat-$version-windows-x86_64\filebeat.exe" setup --modules system -e -E 'setup.dashboards.enabled=true'
Start-Service filebeat