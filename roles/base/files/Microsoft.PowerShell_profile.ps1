[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingInvokeExpression', '')]
param()

# Configure PSReadLine.
#Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

# Configure oh-my-posh.
if ($PSVersionTable.PSEdition -eq 'Desktop') {
    oh-my-posh init powershell --config ~/.rgl.omp.json | Invoke-Expression
} else {
    oh-my-posh init pwsh --config ~/.rgl.omp.json | Invoke-Expression
}
