#!powershell
#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        language = @{ type = "str"; required = $true }
    }
    # TODO supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.InternationalSettings.Commands') | Out-Null

$language = $module.Params.language

# NB you can get the language from the list:
#      [System.Globalization.CultureInfo]::GetCultures('InstalledWin32Cultures') | Out-GridView
# NB "HKEY_CURRENT_USER\Keyboard Layout\Preload" will have the keyboard layout list.
function Set-UserKeyboard {
    [OutputType([bool])]
    [CmdletBinding(SupportsShouldProcess)]
    param([Microsoft.InternationalSettings.Commands.WinUserLanguage]$language)
    $actual = Get-WinDefaultInputMethodOverride
    $desired = (New-WinUserLanguageList $language.LanguageTag).InputMethodTips | Select-Object -First 1
    if ($actual -ne $desired) {
        if ($PSCmdlet.ShouldProcess('language')) {
            Set-WinDefaultInputMethodOverride $desired
        }
        return $true
    }
    return $false
}

$module.Result.changed = Set-UserKeyboard $language
$module.ExitJson()
