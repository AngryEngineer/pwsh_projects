param (

    [parameter(Mandatory = $true)]

    [String]$Path

)

$Names = "C:\Users\mgreenlaw\Documents\Test\dmundy\New folder\desktop.ini"



####### ARG CHecking #######
If (!($Path.EndsWith("\"))) {
    $Path = $Path + "\"
    If ($PSBoundParameters['Verbose']) {Write-Host -NoNewline "Chaning Path to:["$Path"]"; Write-Host ""}
}
If (!(Test-Path -Path $Path)) {
    Write-Host -NoNewline "Path not valid:" $Path 
    Write-Host ""
    exit
}

$Tree = Get-ChildItem $Path -Recurse -Force

# Main run

Foreach ($Folder in $Tree) {    
    If ($PSBoundParameters['Verbose']) {Write-Host -NoNewline "Processing:["(($Folder.FullName).Length + 6)"]"; Write-Host ""}
    $Exclude = $false
    Foreach ($Name in $Names) {
        If ($Folder.FullName -like $name) {
            If ($PSBoundParameters['Verbose']) {Write-Host -NoNewline "Skipping:["$Folder.FullName"]"; Write-Host ""}
            $Exclude = $true
        }
    }
    If (!($Exclude)) {
        $FolderACL = Get-ACL -Path $Folder.FullName
        $Border = $null
        # Make User Object
        If ($FolderACL.AreAccessRulesProtected) { 
            For ($i=0; $i -le (($Folder.FullName).Length + 7); $i++){
                $Border += "#"
            }
            Write-Host -ForegroundColor Red $Border
            Write-Host -ForegroundColor Red "## "$Folder.FullName" ##"
            Write-Host -ForegroundColor Red $Border
            Format-List -InputObject ($Folder.GetAccessControl()).Access
        } 
    }
    
        
}
   