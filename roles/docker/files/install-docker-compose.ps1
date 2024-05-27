# see https://github.com/docker/compose/releases
# see https://github.com/rgl/gitlab-ci-vagrant/blob/master/windows/provision-docker-compose.ps1

param(
    [string]$version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$archiveUrl = "https://github.com/docker/compose/releases/download/v$version/docker-compose-windows-x86_64.exe"
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"
$dockerCliPluginsPath = "$env:ProgramData\docker\cli-plugins"
$dockerComposePath = "$dockerCliPluginsPath\docker-compose.exe"

# check whether the expected version is already installed.
$installBinaries = if (Test-Path $dockerComposePath) {
    # e.g. Docker Compose version v2.27.1
    $actualVersionText = &$dockerComposePath version
    if ($actualVersionText -notmatch '^Docker Compose version v(\d+(\.\d+)+)') {
        throw "unable to parse the docker-compose.exe version from: $actualVersionText"
    }
    $Matches[1] -ne $version
} else {
    $true
}

# download install the binaries.
if ($installBinaries) {
    # remove the existing binaries.
    if (Test-Path $dockerComposePath) {
        Remove-Item -Force -Recurse $dockerComposePath | Out-Null
    }
    # install the binaries.
    (New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
    mkdir -Force $dockerCliPluginsPath | Out-Null
    Move-Item -Force $archivePath $dockerComposePath
    $Ansible.Changed = $true
}
