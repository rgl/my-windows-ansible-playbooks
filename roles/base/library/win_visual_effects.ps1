#!powershell
#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        show_window_contents_while_dragging = @{ type = "bool"; default = $false }
        smooth_edges_of_screen_fonts = @{ type = "bool"; default = $false }
    }
    # TODO supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$VisualEffects = @{
    ShowWindowContentsWhileDragging = @{
        Key     = 'HKCU:\Control Panel\Desktop'
        Name    = 'DragFullWindows'
    }
    SmoothEdgesOfScreenFonts = @{
        Key     = 'HKCU:\Control Panel\Desktop'
        Name    = 'FontSmoothing'
        Value   = 2
    }
}

function Set-RegistryValue($key, $name, $value) {
    $actual = (Get-ItemProperty $key $name).$name
    if ($actual -eq $value) {
        return $false
    }
    Set-ItemProperty $key $name $value
    return $true
}

function Set-VisualEffects {
    param(
        [switch]$ShowWindowContentsWhileDragging,
        [switch]$SmoothEdgesOfScreenFonts
    )
    $changed = Set-RegistryValue `
        HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects `
        VisualFXSetting `
        3
    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        $ve = $VisualEffects[$_.Key]
        $value = if ($_.Value) {
            if ($ve.ContainsKey('Value')) {
                $ve.Value
            } else {
                1
            }
        } else {
            0
        }
        $changed = $changed -or (Set-RegistryValue $ve.Key $ve.Name $value)
    }
    return $changed
}

$module.Result.changed = Set-VisualEffects `
    -ShowWindowContentsWhileDragging:$module.Params.show_window_contents_while_dragging `
    -SmoothEdgesOfScreenFonts:$module.Params.smooth_edges_of_screen_fonts

$module.ExitJson()
