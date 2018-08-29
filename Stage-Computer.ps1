<#
.SYNOPSIS

Add a computer object to the AD.

.DESCRIPTION
Stage a computer object in a default or specified OU, and
add a user that has full privileges to the object so they
can join the machine to the domain.

.PARAMETER Name
Specifies the computer object name

.PARAMETER OU
Specifies the OU to create the computer object in.

.PARAMETER User
Specifies the user to grant control of the computer object.

.INPUTS

None. You cannot pip objects to Stage-Computer.

.OUTPUTS

None.

.EXAMPLE

C> Stage-Computer -Name NEWComputer

Create the computer object named NEWComputer to the default OU, but does not add a user with full control to the object.

.EXAMPLE

C> Stage-Computer -Name NEWComputer -User foo

Creates the computer object named NEWComputer to the default OU, and grants the user "foo" full control of the object.

#>

param (
    [Parameter(Mandatory=$true)][string]$Name,
    [string]$OU = "OU=CSSD-ManagedDesktop Exceptions,OU=Workstations,OU=CSSD,OU=Departments,DC=univ,DC=pitt,DC=edu",
    [string]$User
)

    
$OU            = "OU=CSSD-ManagedDesktop Exceptions,OU=Workstations,OU=CSSD,OU=Departments,DC=univ,DC=pitt,DC=edu"
$computerName  = $Name
$computerAdmin = $User


#$userCredential = Get-Credential -Message "Password : " -Username $Username
try {
# Create the new computer object
	New-ADComputer -Name $computerName -Path $OU
} catch {
	Write-Output "Could not add computer [$computerName] to the OU [$OU]."
	# [Environment]::Exit(1)
}

if ( $User.length -gt 0 ) {
    # Create the ACL for the computer and add a user with full control
    # Get the current ACL
    $computerACL = Get-Acl $computerName

    # Get SID of the user account to add to the computer object
    $adUser = GetADUser $computerAdmin
    $SID = [System.Security.Principal.SecurityIdentifier] $adUser.SID
    $identity = [System.Security.Principal.IdentityReference] $SID
    $adRights = [System.DirectoryServices.ActiveDirectoryRights] "GenericAll"
    $type = [System.Security.AccessControl.AccessControlType] "Allow"
    $inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "All"
    $ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity,$adRights,$type,$inheritanceType

    #Build the new ACL obkect
    $computerACL.AddAccessRule($ace) 

    # Apply the new ACL to the computer object
	try {
		Set-Acl -AclObject $computerACL $computerName
	} catch {
		Write-Output "Could not grant privileges to user [$computerAdmin]."
	}
}