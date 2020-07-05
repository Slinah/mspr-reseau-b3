# ~~~~~~ Variables ~~~~~~

$csv = Import-csv 'Utilisateurs.csv' -Delimiter ';'
$agences = Import-csv 'Utilisateurs.csv' -Delimiter ';' | Sort-Object Agence -Unique | % {$_.Agence}
$services = Import-csv 'Utilisateurs.csv' -Delimiter ';' | % {$_.Service, $_.Agence}

$domaineDNS = "XXXXXX.lan"
$netBIOS = "XXXXXX"
$foret = @{
'-DatabasePath'= 'C:\Windows\NTDS';
'-DomainMode' = 'Default';
'-DomainName' = $domaineDNS;
'-DomainNetbiosName' = $netBIOS;
'-ForestMode' = 'Default';
'-InstallDns' = $true;
'-LogPath' = 'C:\Windows\NTDS';
'-NoRebootOnCompletion' = $false;
'-SysvolPath' = 'C:\Windows\SYSVOL';
'-Force' = $true;
'-CreateDnsDelegation' = $false }
$ADIP = "xxx"
$mask = "24"
$defaultGateway = "xxx"
$install = @("AD-Domain-Services","DNS", "DHCP", "FS-DFS-namespace", "RSAT-DFS-Mgmt-Con")
$defaultPassword = "XXXXXXDefaultPassword"
$defaultDirectory = "\\server\home$\"

# ~~~~~~ Configuration Machine  ~~~~~~

New-NetIpAddress -ipaddress $ADIP -prefixlength $mask -interfaceindex (Get-NetAdapter).ifindex -defaultgateway $defaultgateway

set-dnsclientserveraddress -interfaceindex (get-netadapter).ifindex -serveraddresses("127.0.0.1")

rename-computer -newname "ServerAD"
rename-netadapter -name Ethernet0 -newname LAN 

import-module ADDSDeployment
import-module ActiveDirectory
import-module 'Microsoft.Powershell.Security'

# ~~~~~~ Installation DNS, DHCP, AD ~~~~~~

# Install-WindowsFeature DNS -IncludeManagementTools
# Install-WindowsFeature DHCP -IncludeManagementTools
# Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

ForEach ($function in $install){
    if ((( Get-WindowsFeature -name $function).installstate) -eq "Available"){
        try {
            Install-WindowsFeature -name $function -includemanagementtools -includeallsubfeature
        }catch{
            write-output "$function : L'installation a plantée."
        }
    }
}

#  ~~~~~~ Configuration DNS ~~~~~~

Add-DnsServerPrimaryZone -Name $domaineDNS -ReplicationScope "Forest" 

#  ~~~~~~ Configuration DHCP ~~~~~~

Add-DhcpServerv4Scope -Name "Paris-Administratif" -StartRange 192.168.20.1 -EndRange 192.168.20.126 -SubnetMask 255.255.255.128 -State Active
Add-DhcpServerv4Scope -Name "Paris-Invites" -StartRange 192.168.20.128 -EndRange 192.168.20.254 -SubnetMask 255.255.255.128 -State Active

Add-DhcpServerv4Scope -Name "Bordeaux-Administratif" -StartRange 192.168.10.1 -EndRange 192.168.10.126 -SubnetMask 255.255.255.128 -State Active
Add-DhcpServerv4Scope -Name "Bordeaux-Invites" -StartRange 192.168.10.128 -EndRange 192.168.10.254 -SubnetMask 255.255.255.128 -State Active
Add-DhcpServerv4Scope -Name "Bordeaux-Entrepots" -StartRange 192.168.11.1 -EndRange 192.168.11.126 -SubnetMask 255.255.255.128 -State Active

Add-DhcpServerv4Scope -Name "Lyon-Administratif" -StartRange 192.168.30.1 -EndRange 192.168.30.126 -SubnetMask 255.255.255.128 -State Active
Add-DhcpServerv4Scope -Name "Lyon-Invites" -StartRange 192.168.30.128 -EndRange 192.168.30.254 -SubnetMask 255.255.255.128 -State Active

Add-DhcpServerv4Scope -Name "Marseille-Administratif" -StartRange 192.168.40.1 -EndRange 192.168.40.126 -SubnetMask 255.255.255.128 -State Active
Add-DhcpServerv4Scope -Name "Marseille-Invites" -StartRange 192.168.40.128 -EndRange 192.168.40.254 -SubnetMask 255.255.255.128 -State Active

#  ~~~~~~ Configuration ADDS ~~~~~~

install-addsforest @foret -DomainName $domaineDNS

ForEach ($ou in $agences){
    new-adorganizationalunit -Name $ou -Path "dc=XXXXXX, dc=lan"
    ForEach ($all in $csv){
        if ($ou -eq $all.Agence){
            $service = $all.Service
            new-adorganizationalunit -name $g -path "ou=$ou, dc=XXXXXX, dc=lan"
            new-adgroup -Name "gp_$service" -GroupScope DomainLocal -GroupCategory Security -Path "ou=$service, ou=$ou, dc=XXXXXX, dc=lan"
            set-adorganizationalunit -ProtectedFromAccidentalDeletion $true

            new-aduser -name $all.Prénom -SamAccoutName $all.Prénom -userprincipalname $all.Nom -accountpassword (ConvertTo-SecureString $defaultPassword -AsPlainText -Force) -path "ou=$service, ou=$ou, dc=XXXXXX, dc=lan"
            $directory = $defaultDirectory + $all.Prénom
            New-Item -Path $directory -Type Directory -Force
            set-aduser $all.Prénom.$all.Nom -homedrive "C:" -homedirectory "/user/" + $all.Prénom
        } else {
            Write-Host "Ne correspond pas."
        }
    }
}

#  ~~~~~~ Configuration DFS ~~~~~~

