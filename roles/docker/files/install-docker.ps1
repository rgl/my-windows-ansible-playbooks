# see https://github.com/rgl/docker-ce-windows-binaries-vagrant/releases
# see https://github.com/rgl/gitlab-ci-vagrant/blob/master/windows/provision-docker-ce.ps1

param(
    [string]$version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Ansible.Changed = $false

$serviceName = 'docker'
$serviceHome = "$env:ProgramFiles\docker"

# check whether the expected version is already installed.
$installBinaries = if (Test-Path "$serviceHome\dockerd.exe") {
    # e.g. Docker version 20.10.16, build f756502
    $actualVersionText = &"$serviceHome\dockerd.exe" --version
    if ($actualVersionText -notmatch '^Docker version (\d+(\.\d+)+)') {
        throw "unable to parse the dockerd.exe version from: $actualVersionText"
    }
    $Matches[1] -ne $version
} else {
    $true
}

# download install the docker binaries.
if ($installBinaries) {
    # uninstall the service.
    if ((Test-Path "$serviceHome\dockerd.exe") -and (Get-Service -ErrorAction SilentlyContinue $serviceName)) {
        Stop-Service $serviceName
        &"$serviceHome\dockerd.exe" --unregister-service
        if ($LASTEXITCODE) {
            throw "failed to unregister the docker service with exit code $LASTEXITCODE"
        }
        $Ansible.Changed = $true
    }
    # remove the existing binaries.
    if (Test-Path $serviceHome) {
        Remove-Item -Force -Recurse $serviceHome | Out-Null
    }
    # install the binaries.
    $archiveVersion = $version
    $archiveName = "docker-$archiveVersion.zip"
    $archiveUrl = "https://github.com/rgl/docker-ce-windows-binaries-vagrant/releases/download/v$archiveVersion/$archiveName"
    $archivePath = "$env:TEMP\$archiveName"
    (New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
    Expand-Archive $archivePath -DestinationPath $env:ProgramFiles
    Remove-Item $archivePath
    $Ansible.Changed = $true
}

# install the service.
if (!(Get-Service -ErrorAction SilentlyContinue $serviceName)) {
    &"$serviceHome\dockerd.exe" --register-service
    if ($LASTEXITCODE) {
        throw "failed to register the docker service with exit code $LASTEXITCODE"
    }
    $Ansible.Changed = $true
}
