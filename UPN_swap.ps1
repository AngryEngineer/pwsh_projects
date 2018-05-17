param (
    [Switch]$Dry = $False,
    [String]$ChangeFrom,

    [parameter(Mandatory = $true)]
    [String]$ChangeTo
)

If ($ChangeFrom -ne "") {
    $ADUsers = Get-ADUser -Filter {UserPrincipalName -like $ChangeFrom} -Properties userPrincipalName -ResultSetSize $null
}
Else {
    $ADUsers = Get-ADUser-Properties userPrincipalName -ResultSetSize $null
}

If ($ADUsers -ne $null) {
    foreach ($User in $ADusers) {
        $newUpn = $User.UserPrincipalName.Replace("contoso.local", $ChangeTo)
        If (!($dry)) {
            #Set-ADUser -UserPrincipalName $newUpn
        } 
        else {
            Write-Host "Changing "$User.UserPrincipalName" to "$newUpn
        }
        
    }
    
}


