function Connect-VMware
{
[CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Server,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$User,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$Password
    )

Connect-VIServer $Server -User $User -Password $Password
}
