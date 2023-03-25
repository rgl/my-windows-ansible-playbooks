#!powershell
#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        show_shadows_under_windows = @{ type = "bool"; default = $false }
        show_translucent_selection_rectangle = @{ type = "bool"; default = $false }
        show_window_contents_while_dragging = @{ type = "bool"; default = $false }
        smooth_edges_of_screen_fonts = @{ type = "bool"; default = $false }
    }
    # TODO supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# NB to get the UserPreferencesMask value, do:
#       $before = [BitConverter]::ToUInt64((Get-ItemProperty 'HKCU:\Control Panel\Desktop' UserPreferencesMask).UserPreferencesMask, 0)
#       # modify the setting using the UI.
#       $after = [BitConverter]::ToUInt64((Get-ItemProperty 'HKCU:\Control Panel\Desktop' UserPreferencesMask).UserPreferencesMask, 0)
#       $mask = $before -bxor $after
$VisualEffects = @{
    ShowShadowsUnderWindows = @{
        UserPreferencesMask = 262144
    }
    ShowTranslucentSelectionRectangle = @{
        Key     = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        Name    = 'ListviewAlphaSelect'
    }
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
    $item = Get-ItemProperty -ErrorAction SilentlyContinue $key $name
    if ($item) {
        $actual = $item.$name
        if ($actual -eq $value) {
            return $false
        }
    }
    Set-ItemProperty $key $name $value
    return $true
}

Add-Type @'
using System;
using Microsoft.Win32;
public static class UserPreferencesMask
{
    private static bool Enabled(ulong mask, ulong value)
    {
        return (value & mask) == mask;
    }
    private static ulong Enable(ulong mask, ulong value)
    {
        return value | mask;
    }
    private static ulong Disable(ulong mask, ulong value)
    {
        return value & ~mask;
    }
    public static bool Set(ulong mask, bool enable)
    {
        const string keyName = @"HKEY_CURRENT_USER\Control Panel\Desktop";
        const string valueName = @"UserPreferencesMask";
        var valueBytes = (byte[])Registry.GetValue(keyName, valueName, null);
        var value = BitConverter.ToUInt64(valueBytes, 0);
        if (Enabled(mask, value) == enable)
        {
            return false;
        }
        var newValue = enable ? Enable(mask, value) : Disable(mask, value);
        var newValueBytes = BitConverter.GetBytes(newValue);
        Registry.SetValue(keyName, valueName, newValueBytes);
        return true;
    }
}
'@

function Set-VisualEffect {
    param(
        [switch]$ShowShadowsUnderWindows,
        [switch]$ShowTranslucentSelectionRectangle,
        [switch]$ShowWindowContentsWhileDragging,
        [switch]$SmoothEdgesOfScreenFonts
    )
    $changed = Set-RegistryValue `
        HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects `
        VisualFXSetting `
        3
    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        $ve = $VisualEffects[$_.Key]
        if ($ve.ContainsKey('UserPreferencesMask')) {
            $changed = $changed -or [UserPreferencesMask]::Set($ve.UserPreferencesMask, $_.Value)
        } else {
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
    }
    return $changed
}

$module.Result.changed = Set-VisualEffect `
    -ShowShadowsUnderWindows:$module.Params.show_shadows_under_windows `
    -ShowTranslucentSelectionRectangle:$module.Params.show_translucent_selection_rectangle `
    -ShowWindowContentsWhileDragging:$module.Params.show_window_contents_while_dragging `
    -SmoothEdgesOfScreenFonts:$module.Params.smooth_edges_of_screen_fonts

$module.ExitJson()
