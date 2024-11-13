function New-NetFirewallRuleAllUsers {
    <#
    .SYNOPSIS
    Creates an inbound or outbound firewall rule for all users.

    .DESCRIPTION
    Creates an inbound or outbound firewall rule for all users that have already logged into the machine (checks user folder). This should only be used for rules which need to be created for program file stored in the user profile.
    
    .PARAMETER DisplayName
    Specifies that only matching firewall rules of the indicated display name are created.

    .PARAMETER Description
    Specifies that matching firewall rules of the indicated description are created.

    .PARAMETER Direction
    Specifies that matching firewall rules of the indicated direction are created. This parameter specifies which direction of traffic to match with this rule. The acceptable values for this parameter are: Inbound or Outbound. The default value is Inbound.

    .PARAMETER Profile
    Specifies one or more profiles to which the rule is assigned. The rule is active on the local computer only when the specified profile is currently active. This relationship is many-to-many and can be indirectly modified by the user, by changing the Profiles field on instances of firewall rules. Only one profile is applied at a time. The acceptable values for this parameter are: Any, Domain, Private, Public, or NotApplicable. The default value is Any.

    .PARAMETER Program
    Specifies the path and file name of the program for which the rule allows traffic. This is specified as the full path to an application file MINUS the path to the user profile directory.

    .PARAMETER Action
    Specifies that matching firewall rules of the indicated action are created. This parameter specifies the action to take on traffic that matches this rule. The acceptable values for this parameter are: Allow or Block. The default value is Allow.

    .PARAMETER Protocol
    Specifies that network packets with matching IP addresses match this rule. This parameter specifies the protocol for an IPsec rule. The acceptable values for this parameter are: Any, TCP, or UDP. The default value is Any.
    
    .PARAMETER LocalPort
    Specifies that network packets with matching IP local port numbers match this rule. The acceptable value is a port or range.

    .PARAMETER RemotePort
    Specifies that network packets with matching IP port numbers match this rule. This parameter value is the second end point of an IPsec rule. The acceptable value is a port or range.
    
    .OUTPUTS
    None

    .EXAMPLE
    New-NetFirewallRuleAllUsers -DisplayName "My FW Rule" -Direction "Inbound" -Profile "Domain" -Program "\appdata\local\app\binary.exe" -Action "Allow"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DisplayName,
        [Parameter(Mandatory = $false)]
        [string]$Description,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Inbound","Outbound")]
        [string]$Direction = "Inbound",
        [Parameter(Mandatory = $false)]
        [ValidateSet("Any","Domain", "Private", "Public", "NotApplicable")]
        [string]$Profile = "Any",
        [Parameter(Mandatory = $true)]
        [string]$Program,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Allow","Block")]
        [string]$Action = "Allow",
        [Parameter(Mandatory = $false)]
        [ValidateSet("Any","TCP", "UDP")]
        [string]$Protocol = "Any",
        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 65535)]
        [string]$LocalPort,
        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 65535)]
        [string]$RemotePort        
    )
    BEGIN {
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop 

        # Regex for account type, for matching on later
        $sidToMatch = @(
            "S-1-5-21-\d+-\d+\-\d+\-\d+$" # AD user
            "S-1-12-1-\d+-\d+\-\d+\-\d+$" # Entra user
        )
        $sidRegex = $sidToMatch -join "|"
    }   
    PROCESS {
        # Get a list of user profiles
        $profiles = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" | Where-Object {$_.PSChildName -match $sidRegex}
        
        # Create a custom hash table of parameters for future splatting
        $parameterList = (Get-Command -Name $MyInvocation.InvocationName).Parameters

        foreach ($user in $profiles){
            $params = @{}
            foreach ($key in $parameterList.keys){
                $keyVar = Get-Variable -Name $key -ErrorAction SilentlyContinue
                if ($keyVar.Name -eq "Program"){
                    $programPath = $keyVar.Value.TrimStart("\")
                    $params.Add($keyVar.Name, "$($user.ProfileImagePath)\$programPath")
                }
                elseif ($keyVar.Value){
                    $params.Add($keyVar.Name, $keyVar.Value)
                }
            }
            # Apprend the users name to the DisplayName
            $username = ($user.ProfileImagePath -split '\\')[2]
            $params["DisplayName"] = "$($params.DisplayName) - for $username"
            
            # Add the new firewall rule
            $existingRule = Get-NetFirewallRule -DisplayName $params["DisplayName"] -ErrorAction SilentlyContinue

            if (!($existingRule)){
                New-NetFirewallRule @params
            }
        }
    }
}