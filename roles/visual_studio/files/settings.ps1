# set the visual studio settings.
# see https://learn.microsoft.com/en-us/visualstudio/ide/reference/resetsettings-devenv-exe?view=visualstudio
# see https://learn.microsoft.com/en-us/visualstudio/ide/how-to-change-fonts-and-colors-in-visual-studio?view=visualstudio
# see https://github.com/rgl/visual-studio-community-vagrant/blob/master/provision-vs.ps1#L55-L70

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$vsHome = 'C:\Program Files\Microsoft Visual Studio\18\Community'
$devenv = "$vsHome\Common7\IDE\devenv.com"
$settingsHomePath = "$env:LOCALAPPDATA\Microsoft\VisualStudio"
$changed = $false

# set the visual studio settings.
# NB this is required to initialize the settings before Visual Studio actually
#    starts for the first time.
# e.g. C:\Users\Administrator\AppData\Local\Microsoft\VisualStudio\17.0_4265cb20\Settings\CurrentSettings.vssettings
$currentSettingsPath = if (Test-Path $settingsHomePath) {
    Get-ChildItem -Recurse $settingsHomePath -Include CurrentSettings.vssettings
} else {
    $null
}
if (!$currentSettingsPath) {
    Write-Host 'Resetting Settings to Default...'
    if (Test-Path $settingsHomePath) {
        Remove-Item -Recurse -Force $settingsHomePath
    }
    &$devenv /NoSplash /ResetSettings General /Command Exit | Out-String -Stream
    Write-Host 'Modifying the Default Settings...'
    $currentSettingsPath = Get-ChildItem -Recurse "$settingsHomePath\CurrentSettings.vssettings"
    $defaultSettingsPath = "$(Split-Path -Parent $currentSettingsPath)\DefaultSettings.vssettings"
    Move-Item $currentSettingsPath $defaultSettingsPath
    $xsl = New-Object System.Xml.Xsl.XslCompiledTransform
    $xsl.Load("$env:USERPROFILE\.ansible-visual-studio\settings.xsl")
    $xsl.Transform($defaultSettingsPath, $currentSettingsPath)
    $changed = $true
}

$Ansible.Changed = $changed
