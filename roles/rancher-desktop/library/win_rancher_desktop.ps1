#!powershell
#AnsibleRequires -CSharpUtil Ansible.Basic
# NB this installs the binaries at C:\Program Files\Rancher Desktop.
# NB this also installs an uninstaller named Rancher Desktop 1.3.0.

$spec = @{
    options = @{
        version = @{ type = "str"; required = $true }
        container_engine = @{ type = "str"; required = $true }
        kubernetes_version = @{ type = "str"; required = $true }
        # TODO support state: present and absent.
    }
    # TODO supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$module.Result.changed = $false

function Install-RancherDesktop($version) {
    #
    # bail when its already installed.

    $value = Get-ItemProperty `
        HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* `
        | Where-Object {
            (Get-Member -InputObject $_ -Name DisplayVersion) -and
            $_.DisplayVersion -eq $version -and
            $_.DisplayName -match '^Rancher Desktop'
        }
    if ($value) {
        return $false
    }

    #
    # download and (re)install.

    $artifactHashUrl = "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v$version/Rancher.Desktop.Setup.$version.exe.sha512sum"
    $artifactUrl = "https://github.com/rancher-sandbox/rancher-desktop/releases/download/v$version/Rancher.Desktop.Setup.$version.exe"
    $artifactPath = "$env:TEMP\$(Split-Path -Leaf $artifactUrl)"

    Write-Host "Downloading $artifactHashUrl..."
    $artifactHash = (New-Object System.Net.WebClient).DownloadString($artifactHashUrl) -split '\s+',2 | Select-Object -First 1

    Write-Host "Downloading $artifactUrl..."
    (New-Object System.Net.WebClient).DownloadFile($artifactUrl, $artifactPath)
    $artifactActualHash = (Get-FileHash -Algorithm SHA512 $artifactPath).Hash
    if ($artifactActualHash -ne $artifactHash) {
        throw "the $artifactUrl file hash $artifactActualHash does not match the expected $artifactHash"
    }

    Write-Host "Installing $artifactUrl..."
    &$artifactPath /S /allusers | Out-String -Stream

    return $true
}

function Set-RancherDesktop($containerEngine, $kubernesVersion) {
    $rancherHome = 'C:\Program Files\Rancher Desktop'
    $rdctlPath = "$rancherHome\resources\resources\win32\bin\rdctl.exe"
    $rdPath = "$rancherHome\Rancher Desktop.exe"

    # TODO implement.
    #      see https://github.com/rancher-sandbox/rancher-desktop/issues/2340

    return $false
}

$version = $module.Params.version
$containerEngine = $module.Params.container_engine
$kubernesVersion = $module.Params.kubernetes_version

# install.
if (Install-RancherDesktop $version) {
    $module.Result.changed = $true
}

# configure.
if (Set-RancherDesktop $containerEngine $kubernesVersion) {
    $module.Result.changed = $true
}

$module.ExitJson()
