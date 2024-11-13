##############################
#####     FileBeat     #####
##############################

# dot sourcing variables
. "C:\WOLF\Scripts\Var.ps1"
. "C:\WOLF\Scripts\ElasticSearch.ps1"

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

& "$dirPath\FileBeat\filebeat-$version-windows-x86_64\filebeat.exe" setup -e -c "$dirPath\FileBeat\filebeat-$version-windows-x86_64\FileBeat.yml"
Start-Service filebeat