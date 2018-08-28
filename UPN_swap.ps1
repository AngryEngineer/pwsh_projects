param (
    [Switch]$Dry = $False,
    [String]$ChangeFrom,

    [parameter(Mandatory = $true)]
    [String]$ChangeTo
)

Import-Module "activedirectory"-Cmdlet Get-ADuser, Set-ADuser -ErrorAction Stop

If ($ChangeFrom -ne "") {
    $ADUsers = Get-ADUser -Filter {UserPrincipalName -like $ChangeFrom } -Properties userPrincipalName -ResultSetSize $null
}
Else {
    $ADUsers = Get-ADUser -Filter 'UserPrincipalName -like "*"'  -Properties userPrincipalName -ResultSetSize $null
}

If ($ADUsers -ne $null) {
    foreach ($User in $ADusers) {
        $newUpn = $User.UserPrincipalName.Replace( (($User.UserPrincipalName.Split("@"))[1]) , $ChangeTo)
        
        Write-Host -NoNewline  "Changing "
        Write-Host -NoNewline -ForegroundColor Yellow $User.UserPrincipalName
        Write-Host -NoNewline " to "
        Write-Host -NoNewline -ForegroundColor Green $newUpn
        If (!($dry)) {
            try {
                Set-ADUser -Identity $User.SID -UserPrincipalName $newUpn
            }
            catch {
                Write-Host -NoNewline " - "
                Write-Host -ForegroundColor Red -NoNewline "Failed!"
            }
            Finally {
                Write-Host ""
            }
        } 
        
        
    }
    
}


