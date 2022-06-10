#!powershell
#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        name = @{ type = "list"; elements = "str"; required = $true }
        # TODO support state: present and absent.
    }
    # TODO supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$module.Result.changed = $false

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$setupPath = 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe'
$installPath = 'C:\Program Files\Microsoft Visual Studio\2022\Community'
$configPath = "$env:TEMP\visual-studio-2022-config.json"
$changedSentinel = '**COMPONENTS CHANGED**'

function Install-VisualStudioComponents([string[]]$components) {
    # get the installed components.
    &$setupPath `
        export `
        --noUpdateInstaller `
        --noWeb `
        --installPath $installPath `
        --config $configPath `
        --quiet `
        | Out-String -Stream `
        | Write-Host
    $config = Get-Content -Raw $configPath | ConvertFrom-Json
    Remove-Item $configPath

    # detect what are the missing components.
    $missingComponents = @(
        Compare-Object `
            -ReferenceObject $config.components `
            -DifferenceObject $components `
            -PassThru `
            | Where-Object { $_.SideIndicator -eq '=>' })

    # install the missing components.
    if ($missingComponents) {
        $arguments = @(
            'modify'
            '--installPath'
            $installPath
            '--norestart'
            '--quiet'
        )
        $missingComponents | ForEach-Object {
            $arguments += '--add'
            $arguments += $_
        }
        &$setupPath @arguments `
            | Out-String -Stream `
            | Write-Host
        return $changedSentinel
    }
}

$components = $module.Params.name

if ((Install-VisualStudioComponents $components) -ieq $changedSentinel) {
    $module.Result.changed = $true
}

$module.ExitJson()
