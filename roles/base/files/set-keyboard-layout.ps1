param(
    [string[]]$languageTag
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.InternationalSettings.Commands') | Out-Null

# set the current user keyboard layout.
# NB you can get the name from the list:
#      [System.Globalization.CultureInfo]::GetCultures('InstalledWin32Cultures') | out-gridview
# NB "HKEY_CURRENT_USER\Keyboard Layout\Preload" will have the keyboard layout list.
function Set-KeyboardLayout([Microsoft.InternationalSettings.Commands.WinUserLanguage[]]$languageTags) {
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

# set the current user keyboard layout.
$Ansible.Changed = Set-KeyboardLayout $languageTag

# TODO set the login screen keyboard.
