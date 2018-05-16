param (
    [switch]$Repair = $false,
    [switch]$ClearHome = $false,
    [switch]$Dry = $false,
    [String]$Account,
    [parameter(Mandatory=$true)]
    [String]$Path

 )
Import-Module "activedirectory"-Cmdlet Get-ADuser, Set-ADuser -ErrorAction Stop

If($PSBoundParameters['Verbose']) {Write-Host "Set-Homedrive"; Write-Host "Version .12";Write-Host "By Matthew Greenlaw (mgreenlaw@cetechno.com)"; Write-Host ""; Write-Host "Where Users live.";Write-Host ""}

####### ARG CHecking #######
If (!($Path.EndsWith("\"))){
    $Path = $Path + "\"
    If($PSBoundParameters['Verbose']) {Write-Host -NoNewline "Chaning Path to:["$Path"]"; Write-Host ""}
}
If(!(Test-Path -Path $Path)){
    Write-Host -NoNewline "Path not valid:" $Path 
    Write-Host ""
    exit
}
If ($Account -ne ""){
    If($PSBoundParameters['Verbose']) {Write-Host -NoNewline "Single user mode:["$Account.ToString()"]"; Write-Host ""}
    $ADuser = Get-ADUser -Filter { SamAccountName -eq $Account }
} Else {
    If($PSBoundParameters['Verbose']) {Write-Host -NoNewline "Auto AD user Mode"; Write-Host ""}
    $ADuser = Get-ADUser -LDAPFilter "(&(objectCategory=person)(objectClass=user)(!userAccountControl:1.2.840.113556.1.4.803:=2))"
}

############################

$AdjustTokenPrivileges = @"
using System;
using System.Runtime.InteropServices;

 public class TokenManipulator
 {
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
  ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
  [DllImport("kernel32.dll", ExactSpelling = true)]
  internal static extern IntPtr GetCurrentProcess();
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr
  phtok);
  [DllImport("advapi32.dll", SetLastError = true)]
  internal static extern bool LookupPrivilegeValue(string host, string name,
  ref long pluid);
  [StructLayout(LayoutKind.Sequential, Pack = 1)]
  internal struct TokPriv1Luid
  {
   public int Count;
   public long Luid;
   public int Attr;
  }
  internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
  internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
  internal const int TOKEN_QUERY = 0x00000008;
  internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
  public static bool AddPrivilege(string privilege)
  {
   try
   {
    bool retVal;
    TokPriv1Luid tp;
    IntPtr hproc = GetCurrentProcess();
    IntPtr htok = IntPtr.Zero;
    retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
    tp.Count = 1;
    tp.Luid = 0;
    tp.Attr = SE_PRIVILEGE_ENABLED;
    retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
    retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    return retVal;
   }
   catch (Exception ex)
   {
    throw ex;
   }
  }
  public static bool RemovePrivilege(string privilege)
  {
   try
   {
    bool retVal;
    TokPriv1Luid tp;
    IntPtr hproc = GetCurrentProcess();
    IntPtr htok = IntPtr.Zero;
    retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
    tp.Count = 1;
    tp.Luid = 0;
    tp.Attr = SE_PRIVILEGE_DISABLED;
    retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
    retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    return retVal;
   }
   catch (Exception ex)
   {
    throw ex;
   }
  }
 }
"@
add-type $AdjustTokenPrivileges

#Activate necessary admin privileges to make changes without NTFS perms
[void][TokenManipulator]::AddPrivilege("SeSecurityPrivilege") #Optional if you want to manage auditing (SACL) on the objects
[void][TokenManipulator]::AddPrivilege("SeRestorePrivilege") #Necessary to set Owner Permissions
[void][TokenManipulator]::AddPrivilege("SeBackupPrivilege") #Necessary to bypass Traverse Checking
[void][TokenManipulator]::AddPrivilege("SeTakeOwnershipPrivilege") #Necessary to override FilePermissions
# Metrics
$countACL = 0
$Domain = ([ADSI]'').name
If($PSBoundParameters['Verbose']) {Write-Host -NoNewline "Domain Detected:[$Domain]"; Write-Host ""}
# Rights
$readOnly = [System.Security.AccessControl.FileSystemRights]"ReadAndExecute"
$readWrite = [System.Security.AccessControl.FileSystemRights]"Modify"
$fullControl = [System.Security.AccessControl.FileSystemRights]"FullControl"
# Inheritance
$inheritanceFlag = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
# Propagation
$propagationFlag = [System.Security.AccessControl.PropagationFlags]::None
# Type
$type = [System.Security.AccessControl.AccessControlType]::Allow
# Root ACL Access
$ITAdmin = New-Object System.Security.Principal.NTAccount("$Domain\ceadm1n")
$ITDomain = New-Object System.Security.Principal.NTAccount("$Domain\Domain Admins")
$accessControlAdmin = New-Object System.Security.AccessControl.FileSystemAccessRule @("BUILTIN\Administrators", $fullControl, $inheritanceFlag, $propagationFlag, $type)
$accessControlSystem = New-Object System.Security.AccessControl.FileSystemAccessRule @("NT AUTHORITY\SYSTEM", $fullControl, $inheritanceFlag, $propagationFlag, $type)
$accessControlOwner = New-Object System.Security.AccessControl.FileSystemAccessRule @("CREATOR OWNER", $fullControl, $inheritanceFlag, $propagationFlag, $type)
$accessControlITAdmin = New-Object System.Security.AccessControl.FileSystemAccessRule @($ITAdmin, $fullControl, $inheritanceFlag, $propagationFlag, $type)
$accessControlDomainAdmin = New-Object System.Security.AccessControl.FileSystemAccessRule @($ITDomain, $fullControl, $inheritanceFlag, $propagationFlag, $type)
# Subdir ACL

# Main run
If ($ADuser -ne $Null){
    Foreach ($User in $ADuser) {    
        If($PSBoundParameters['Verbose']) {Write-Host -NoNewline "Processing:["$User.SamAccountName"]"; Write-Host ""}
        
        # Make User Object
        $userRW = New-Object System.Security.Principal.NTAccount($User.sAMAccountName)
        $accessControlEntryRW = New-Object System.Security.AccessControl.FileSystemAccessRule @($userRW, $readWrite, $inheritanceFlag, $propagationFlag, $type)

        # Build ACLs
        $objACL = New-Object System.Security.AccessControl.DirectorySecurity
        $objACL.SetOwner($userRW)
        $objACL.AddAccessRule($accessControlEntryRW)
        $objACL.AddAccessRule($accessControlAdmin)
        $objACL.AddAccessRule($accessControlSystem)
        $objACL.AddAccessRule($accessControlITAdmin)
        $objACL.AddAccessRule($accessControlDomainAdmin)
        #$objACL.AddAccessRule($accessControlOwner)
        
        #Disable Inherit
        $objACL.SetAccessRuleProtection($True, $False)

        #UserFolder
        $userFolderFull = $Path + $User.sAMAccountName
    
        if(!(Test-Path -Path $userFolderFull )){
            If($PSBoundParameters['Verbose']) {Write-Host -NoNewline "Making Folder:["$userFolderFull"]"; Write-Host ""}
            # Make new folder
            If($Dry -eq $False){New-Item $userFolderFull -ItemType Directory | out-null}
            # Write Permissions
            If($Dry -eq $False){Set-ACL $userFolderFull $objACL}
            $countACL++
           
        }Else {
            If($Repair -eq $true){
                # Fix Root Folder's ACL
                If($Dry -eq $False){Set-ACL $userFolderFull $objACL}
                $countACL++
                # Make Sub-dir ACL
                $subDirACL = New-Object System.Security.AccessControl.DirectorySecurity
                $subDirACL.SetOwner($userRW)
                $subDirACL.SetAccessRuleProtection($False, $True)
                $subdirs = Get-ChildItem -path $userFolderFull -force -recurse
                foreach ($subitem in $subdirs) {
                    If ($PSBoundParameters['Verbose']) {Write-Host -NoNewline "Repairing:[$($subitem.FullName)]"; Write-Host ""}
                    try {
                        If($Dry -eq $False){Set-Acl -aclObject $subDirACL -path $subitem.Fullname -ErrorAction Stop}
                        $countACL++
                    }
                    catch {
                        Write-Host -ForegroundColor Yellow "Failed!"
                    }
                    finally {}
                }
            } Else {
                If($PSBoundParameters['Verbose']) {Write-Host -NoNewline "Found:["$userFolderFull"]"; Write-Host " Skipping!"}
            }
        }
        if ($ClearHome -eq $true) {
            If($PSBoundParameters['Verbose']) {Write-Host -NoNewline "Cleared Home Drive: "}

            Try {
                If($Dry -eq $False){Set-ADuser -Identity $User.SamAccountName -HomeDrive $null -HomeDirectory $null}
                If($PSBoundParameters['Verbose']) {Write-Host -NoNewline -ForegroundColor Green "Cleared"}
            }
            Catch{
                If($PSBoundParameters['Verbose']) {Write-Host -NoNewline -ForegroundColor Yellow "Failed!"}               
            }
            Finally {
                If($PSBoundParameters['Verbose']) {Write-Host ""}
            }
        }
        If($PSBoundParameters['Verbose']) {Write-Host "-------------------------------------"}
    }
    Write-Host -NoNewline "Total ACLs Processed: $countACL"
    Write-Host ""
} Else{
    Write-Host "Unable to resolve user into SID. Exiting..."
}