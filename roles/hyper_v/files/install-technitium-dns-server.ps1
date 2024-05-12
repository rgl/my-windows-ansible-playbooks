# see https://github.com/TechnitiumSoftware/DnsServer/releases

param(
    [string]$version,
    [string]$forwarders
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

Add-Type -AssemblyName System.Net

$serviceName = 'DnsService'
$serviceHome = "C:\Program Files (x86)\Technitium\DNS Server"

# check whether the expected version is already installed.
$installBinaries = if (Test-Path "$serviceHome\DnsService.exe") {
    # NB ProductVersion is alike 12.0.1+765723c26439d63c52f4a374d18bfa7473befd0f
    $actualVersion = (Get-ChildItem "$serviceHome\DnsService.exe").VersionInfo.ProductVersion -split '\+' | Select-Object -First 1
    $actualVersion -ne $version
} else {
    $true
}

# download and install the binaries.
if ($installBinaries) {
    $archiveVersion = $version
    $archiveName = "DnsService-$archiveVersion.zip"
    $archiveUrl = "https://download.technitium.com/dns/DnsServerSetup.zip"
    $archivePath = "$env:TEMP\$archiveName"
    $setupPath = "$env:TEMP\DnsServerSetup.exe"
    if (Test-Path $setupPath) {
        Remove-Item $setupPath
    }
    (New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
    Expand-Archive $archivePath -DestinationPath $env:TEMP
    Remove-Item $archivePath
    &$setupPath /VERYSILENT "/LOG=$setupPath.log" | Out-String
    if ($LASTEXITCODE) {
        throw "failed with exit code $LASTEXITCODE"
    }
    Remove-Item $setupPath
    $Ansible.Changed = $true
}

# start the service.
$service = Get-Service -ErrorAction SilentlyContinue $serviceName
if (!$service) {
    throw "failed to find the $serviceName service"
} elseif ($service.Status -ne 'Running') {
    Restart-Service $serviceName
    $Ansible.Changed = $true
}

function Invoke-Api($method, $api, $query) {
    $uriBuilder = New-Object System.UriBuilder("http://localhost:5380/api/$api")
    foreach ($param in $query.GetEnumerator()) {
        $uriBuilder.Query = $uriBuilder.Query.TrimStart('?') + [System.Web.HttpUtility]::UrlEncode($param.Key) + "=" + [System.Web.HttpUtility]::UrlEncode($param.Value) + "&"
    }
    $uriBuilder.Query = $uriBuilder.Query.TrimStart('?').TrimEnd('&')
    $uri = $uriBuilder.Uri
    Invoke-RestMethod `
        -Method $method `
        -Uri $uri
}

function Get-RandomPassword([int]$length = 16) {
    $chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#%^*()'
    -join ((1..$length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

# configure the service.

$adminPasswordFilePath = "$serviceHome\config\admin-password.txt"
$adminPassword = if (Test-Path $adminPasswordFilePath) {
    (Get-Content -Raw $adminPasswordFilePath).Trim()
} else {
    'admin'
}
# see https://github.com/TechnitiumSoftware/DnsServer/blob/master/APIDOCS.md#login
$response = Invoke-Api post user/login @{
    user = "admin"
    pass = $adminPassword
}
if ($response.status -ne 'ok') {
    throw "failed to login: $response"
}
$token = $response.token

if ($adminPassword -eq 'admin') {
    $adminPassword = Get-RandomPassword
    $response = Invoke-Api post user/changePassword @{
        token = $token
        pass  = $adminPassword
    }
    if ($response.status -ne 'ok') {
        throw "failed to change password: $response"
    }
    Set-Content -NoNewline -Encoding ascii $adminPasswordFilePath ''
    $acl = New-Object System.Security.AccessControl.FileSecurity
    $acl.SetAccessRuleProtection($true, $false)
    $acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "Allow")))
    Set-Acl -Path $adminPasswordFilePath -AclObject $acl
    Set-Content -NoNewline -Encoding ascii $adminPasswordFilePath $adminPassword
}

# see https://github.com/TechnitiumSoftware/DnsServer/blob/master/APIDOCS.md#get-dns-settings
$response = Invoke-Api post settings/get @{
    token = $token
}
if ($response.status -ne 'ok') {
    throw "failed get settings: $response"
}

# TODO update iif required.
# see https://github.com/TechnitiumSoftware/DnsServer/blob/master/APIDOCS.md#set-dns-settings
$response = Invoke-Api post settings/set @{
    token                   = $token
    dnsServerDomain         = 'test'
    dnsServerLocalEndPoints = '192.168.192.1:53'
    dnssecValidation        = 'false' # NB must be disabled when the forwarders do not support it.
    forwarders              = $forwarders
    forwarderProtocol       = 'Udp'
}
if ($response.status -ne 'ok') {
    throw "failed to set the settings: $response"
}

# see https://github.com/TechnitiumSoftware/DnsServer/blob/master/APIDOCS.md#get-dhcp-scope
$response = Invoke-Api post dhcp/scopes/get @{
    token = $token
    name  = 'Default'
}
if ($response.status -ne 'ok') {
    throw "failed to get dhcp scope: $response"
}

# TODO update iif required.
# see https://github.com/TechnitiumSoftware/DnsServer/blob/master/APIDOCS.md#set-dhcp-scope
$response = Invoke-Api post dhcp/scopes/set @{
    token                                = $token
    name                                 = 'Default'
    routerAddress                        = '192.168.192.1'
    startingAddress                      = '192.168.192.1'
    endingAddress                        = '192.168.192.254'
    subnetMask                           = '255.255.255.0'
    networkAddress                       = '192.168.192.0'
    broadcastAddress                     = '192.168.192.255'
    leaseTimeDays                        = 1
    leaseTimeHours                       = 0
    leaseTimeMinutes                     = 0
    offerDelayTime                       = 0
    pingCheckEnabled                     = 'false'
    domainName                           = 'test'
    dnsUpdates                           = 'true'
    dnsTtl                               = 900
    useThisDnsServer                     = 'true'
    dnsServers                           = '192.168.192.1'
    exclusions                           = '192.168.192.1|192.168.192.99'
    reservedLeases                       = ''
    allowOnlyReservedLeases              = 'false'
    blockLocallyAdministeredMacAddresses = 'false'
    ignoreClientIdentifierOption         = 'true'
}
if ($response.status -ne 'ok') {
    throw "failed to set the default dhcp scope: $response"
}

# see https://github.com/TechnitiumSoftware/DnsServer/blob/master/APIDOCS.md#enable-dhcp-scope
$response = Invoke-Api post dhcp/scopes/enable @{
    token = $token
    name  = 'Default'
}
if ($response.status -ne 'ok') {
    throw "failed to enable the default dhcp scope: $response"
}

# see https://github.com/TechnitiumSoftware/DnsServer/blob/master/APIDOCS.md#logout
$response = Invoke-Api post user/logout @{
    token = $token
}
if ($response.status -ne 'ok') {
    throw "failed to logout: $response"
}
