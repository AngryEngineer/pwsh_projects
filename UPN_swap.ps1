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
        If (!($dry)) {
            #Set-ADUser -UserPrincipalName $newUpn
        } 
        else {
            Write-Host "Changing "$User.UserPrincipalName" to "$newUpn
        }
        
    }
    
}


