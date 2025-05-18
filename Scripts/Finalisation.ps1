###############################
#####     Finalisation    #####
###############################

# dot sourcing variables
. "C:\WOLF\Scripts\Var.ps1"

#############################
#####     WOLF.psm1     #####
#############################

$WOLF_psm1 = "C:\WOLF\Module\WOLF.psm1"
$PS_modules = "C:\Program Files\WindowsPowerShell\Modules"
New-Item -Type Directory "$PS_modules\WOLF" -Force -ErrorAction Stop | Out-Null
Copy-Item -Path "$WOLF_psm1" -Destination "$PS_modules\WOLF\" -ErrorAction Stop
Import-Module -Name WOLF -ErrorAction Stop


#######################################
#####     WOLF Kibana Objects     #####
#######################################

function WOLF-Import-WOLFObjects {
    $version = "9.0.1"
    $kibanaServer = "http://localhost:5601"  # Your Kibana server URL
    $savedObjectsFile = "C:\WOLF\KibanaObjects\wolf.ndjson"  # Path to your NDJSON file containing the saved objects
    $elastic_password = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-$version\elastic_password.txt"

    # Define your Kibana username and password for authentication
    $username = "elastic"
    $password = $elastic_password

    # Convert username and password to Base64 for basic authentication
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))

    # Set the URL
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

    # Send the request
    try {
        Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body -ContentType "multipart/form-data; boundary=$boundary"
    } catch {
        Write-Host "An error occurred: $_"
    }
}
function WOLF-Import-WinObjects {
    $version = "9.0.1"
    $kibanaServer = "http://localhost:5601"  # Your Kibana server URL
    $savedObjectsFile = "C:\WOLF\KibanaObjects\windows.ndjson"  # Path to your NDJSON file containing the saved objects
    $elastic_password = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-$version\elastic_password.txt"

    # Define your Kibana username and password for authentication
    $username = "elastic"
    $password = $elastic_password

    # Convert username and password to Base64 for basic authentication
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))

    # Set the URL
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

    # Send the request
    try {
        Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body -ContentType "multipart/form-data; boundary=$boundary"
    } catch {
        Write-Host "An error occurred: $_"
    }
}
function WOLF-Import-ZeekObjects {
    $version = "9.0.1"
    $kibanaServer = "http://localhost:5601"  # Your Kibana server URL
    $savedObjectsFile = "C:\WOLF\KibanaObjects\zeek.ndjson"  # Path to your NDJSON file containing the saved objects
    $elastic_password = Get-Content "C:\WOLF\ElasticSearch\elasticsearch-$version\elastic_password.txt"

    # Define your Kibana username and password for authentication
    $username = "elastic"
    $password = $elastic_password

    # Convert username and password to Base64 for basic authentication
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))

    # Set the URL
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

    # Send the request
    try {
        Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body -ContentType "multipart/form-data; boundary=$boundary"
    } catch {
        Write-Host "An error occurred: $_"
    }
}
WOLF-Import-WOLFObjects
WOLF-Import-WinObjects
WOLF-Import-ZeekObjects


#################################
#####     Desktop Image     #####
#################################

# Define the image path
$imagePath = "$dirPath\Images\wolfvm.png"

# Set the wallpaper style to 'Fit' in the registry
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -Value '6'
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -Value '0'

# Define the C# code to call SystemParametersInfo
$setwallpapersrc = @"
using System.Runtime.InteropServices;

public class Wallpaper
{
  public const int SetDesktopWallpaper = 20;
  public const int UpdateIniFile = 0x01;
  public const int SendWinIniChange = 0x02;

  [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
  private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);

  public static void SetWallpaper(string path)
  {
    int result = SystemParametersInfo(SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange);
    if (result == 0)
    {
      throw new System.ComponentModel.Win32Exception();
    }
  }
}
"@

# Add the type to the PowerShell session
Add-Type -TypeDefinition $setwallpapersrc

# Apply the wallpaper
[Wallpaper]::SetWallpaper($imagePath)


####################################
#####     Google Bookmarks     #####
####################################

# Define the path to the Chrome Bookmarks file
$chromeBookmarksPath = "C:\Users\$env:USERNAME\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"

# Check if the Chrome User Data folder exists, create it if necessary
$chromeUserDataPath = "C:\Users\$env:USERNAME\AppData\Local\Google\Chrome\User Data\Default"
if (-Not (Test-Path -Path $chromeUserDataPath)) {
    New-Item -Path $chromeUserDataPath -ItemType Directory
    Write-Host "Created Chrome User Data directory at $chromeUserDataPath"
}

# Create a template for the Bookmarks file with favorite links
$bookmarksTemplate = @{
    roots = @{
        bookmark_bar = @{
            children = @(
                @{
                    name = "Kibana"
                    url = "http://wolf.local.vm:5601"
                    type = "url"
                    guid = [guid]::NewGuid().ToString()
                },
                @{
                    name = "WOLF-VM Github"
                    url = "https://github.com/H0wl3r/WOLF-VM"
                    type = "url"
                    guid = [guid]::NewGuid().ToString()
                },
                @{
                    name = "H0wl3r Github"
                    url = "https://github.com/h0wl3r"
                    type = "url"
                    guid = [guid]::NewGuid().ToString()
                }
            )
            date_added = "13200000000000000"
            id = "1"
            name = "Bookmarks bar"
            type = "folder"
        }
        other = @{
            children = @()
            date_added = "13200000000000000"
            id = "2"
            name = "Bookmarks bar"
            type = "folder"
        }
        synced = @{
            children = @()
            date_added = "13200000000000000"
            id = "3"
            name = "Bookmarks bar"
            type = "folder"
        }
    }
    version = 1
}

# Convert the template to JSON and save it as the Bookmarks file
$bookmarksTemplate | ConvertTo-Json -Depth 10 | Set-Content -Path $chromeBookmarksPath


############################
#####     CLEAN UP     #####
############################

Remove-Item -Path "C:\WOLF\.git" -Recurse -Force
Remove-Item -Path "C:\WOLF\.obsidian" -Recurse -Force
wevtutil el | ForEach-Object { wevtutil cl $_ }
stop-computer -computername localhost -Force