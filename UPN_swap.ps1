param (
    [Switch]$Dry = $False,
    [String]$ChangeFrom,

    [parameter(Mandatory = $true)]
    [String]$ChangeTo
)

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
        Write-Host -ForegroundColor Red -NoNewline $User.UserPrincipalName
        Write-Host -NoNewline " to "
        Write-Host -ForegroundColor Green $newUpn
        If (!($dry)) {
            try {
                #Set-ADUser -UserPrincipalName $newUpn
            }
            catch {
                Write-Host -ForegroundColor Yellow "Failed!"
            }
        } 
        
        
    }
    
}


