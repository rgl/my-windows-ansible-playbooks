#!powershell
#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        languages = @{ type = "list"; elements = "str"; required = $true }
    }
    # TODO supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.InternationalSettings.Commands') | Out-Null

$languages = $module.Params.languages

# NB you can get the language tags from the list:
#      [System.Globalization.CultureInfo]::GetCultures('InstalledWin32Cultures') | Out-GridView
# NB "HKEY_CURRENT_USER\Keyboard Layout\Preload" will have the keyboard layout list.
function Set-UserLanguage {
    [OutputType([bool])]
    param([Microsoft.InternationalSettings.Commands.WinUserLanguage[]]$languageTags)
    $changed = $false
    $actualTags = @((Get-WinUserLanguageList).LanguageTag)
    $desiredTags = @($languageTags.LanguageTag)
    $diff = Compare-Object -ReferenceObject $actualTags -DifferenceObject $desiredTags
    if ($diff) {
        Set-WinUserLanguageList $languageTags -Force
        $changed = $true
    }
    return $changed
}

$module.Result.changed = Set-UserLanguage $languages
$module.ExitJson()
