# ~~~~~~ Variables ~~~~~~

$csv = import-csv 'Utilisateurs.csv' -Delimiter ';'
$agences = import-csv 'Utilisateurs.csv' -Delimiter ';' | Sort-Object Agence -Unique | % {$_.Agence}
$services = import-csv 'Utilisateurs.csv' -Delimiter ';' | % {$_.Service, $_.Agence}

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
$DNS = @("AD-Domain-Services","DNS", "DHCP")
$p = "XXXXXXDefaultPassword"

# ~~~~~~ Configuration Machine  ~~~~~~

new-netipAddress -ipaddress $ADIP -prefixlength $mask -interfaceindex (get-netadapter).ifindex -defaultgateway $defaultgateway
set-dnsclientserveraddress -interfaceindex (get-netadapter).ifindex -serveraddresses("127.0.0.1")
rename-computer -newname "ServerAD"
rename-netadapter -name Ethernet0 -newname LAN 

# ~~~~~~ Installation DNS, DHCP, AD ~~~~~~

ForEach ($function in $DNS){
    if ((( Get-WindowsFeature -name $function).installstate) -eq "Available"){
        try {
            Add-WindowsFeature -name $function -includemanagementtools -includeallsubfeature
        }catch{
            write-output "$function : L'installation a plantée."
        }
    }
}

#  ~~~~~~ Configuration DNS ~~~~~~

#  ~~~~~~ Configuration DHCP ~~~~~~

Add-DhcpServerv4Scope -Name "Paris-Administratif" -StartRange 192.168.20.1 -EndRange 192.168.20.126 -SubnetMask 255.255.255.0 

#  ~~~~~~ Configuration ADDS ~~~~~~

import-module ADDSDeployment
install-addsforest @foret
import-module ActiveDirectory
import-module 'Microsoft.Powershell.Security'

ForEach ($ou in $agences){
    new-adorganizationalunit -Name $ou -Path "dc=XXXXXX, dc=lan"
    ForEach ($all in $csv){
        if ($ou -eq $all.Agence){
            $service = $all.Service
            new-adorganizationalunit -name $g -path "ou=$ou, dc=XXXXXX, dc=lan"
            new-adgroup -Name "gp_$service" -GroupScope DomainLocal -GroupCategory Security -Path "ou=$service, ou=$ou, dc=XXXXXX, dc=lan"
            set-adorganizationalunit -ProtectedFromAccidentalDeletion $true

            new-aduser -name $all.Prénom -SamAccoutName $all. -userprincipalname "$n 1" -accountpassword (ConvertTo-SecureString $p -AsPlainText -Force) -path $p
            New-Item -Path $hd -Type Directory -Force
            set-aduser $l.$l -homedrive "C:" -homedirectory "$HomeDirectory"
            add-groupmember -identify $g -member $l.$l
         net user "$n 1" /times:M,8AM-8PM,F,8AM-8PM
        } else {
            Write-Host "Ne correspond pas."
        }
    }
}

# ForEach ($data in $agences){
#     Write-Host $data
# }
