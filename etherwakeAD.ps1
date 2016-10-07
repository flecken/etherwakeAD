#######################################################
##
## etherwakeAD.ps1
##
#######################################################

<#
.SYNOPSIS
Starts a physical machines by using WOL "Magic Packet"
 
.DESCRIPTION
Takes a mac address and sends a WOL packet to broadcast
address to wake the machine. Alternatively takes a 
hostname of a domain machine and queries DHCP servers
for mac address and then sends appropriate packet.
 
.PARAMETER MacAddress
MacAddress or hostname of the target machine to wake.
 
.EXAMPLE
Wake 00:11:22:33:44:55 

or

Wake Server1
 
.INPUTS
None
 
.OUTPUTS
None
 
.NOTES
Mac address must be supplied in format 00:11:22:33:44:55 or 00-11-22-33-44-55

Must be on AD domain and be AD admin
#>



Param(
    [Parameter(Mandatory=$true,position=0)]
    [STRING]$HostID
    #[STRING]$p     #password - yet to implement
)
import-module ActiveDirectory


function Id_type{ #check if supplied HostID is MAC or hostname
    $id = $HostID -split "[:-]"
    
    switch($($HostID -split "[:-]").length){
        6 {return "mac"}
        default {return "hostname"}
    }
    
}

function Get-Leases{ #query DHCP servers for leases
    $all = @()
    foreach ($srv in Get-DhcpServerInDC){
        try{
            $scopes = Get-DhcpServerv4Scope -ComputerName $srv.DnsName
            
            if($scopes -ne $null){
            foreach($scope in $scopes){
                    $all += Get-DhcpServerv4Lease -ScopeId $scope.ScopeId -ComputerName $srv.DnsName -ErrorAction "SilentlyContinue"     
                }
            }
        }
        catch{#Not a DHCP server
        }    
    }    
    $all = $all | sort Clientid -Unique
    
    return $all
}

function Get-HardwareAddress($Leases,$ComputerName){ #get MAC of hostname from array of leases
    $i = ($ComputerName -split "[.]").Length
    if($i -gt 2){$target = $leases | where-object {$_.Hostname -eq "$ComputerName"}}
    else{$target = $leases | where-object {$_.Hostname -like "$($ComputerName).*"}}
    
    return $target.ClientId
}

function Create-MagicPacket($HardwareAddress){ #create WOL packet from MAC
    $MacByteArray = $HardwareAddress -split "[:-]" | ForEach-Object { [Byte] "0x$_"}
    [Byte[]] $MagicPacket = (,0xFF * 6) + ($MacByteArray  * 16) 

    return $MagicPacket
}


function Send-MagicPacket($MagicPacket){ #Send WOL packet
    $UdpClient = New-Object System.Net.Sockets.UdpClient
    $UdpClient.Connect(([System.Net.IPAddress]::Broadcast),7)
    $UdpClient.Send($MagicPacket,$MagicPacket.Length)
    $UdpClient.Close()

}

$ha = $null
if($(Id_type) -eq "hostname"){ #if HostID is a hostname find MAC
    $l = Get-leases-all
    $ha = Get-HardwareAddress -Leases $l -ComputerName $HostID
}
else {$ha = $HostID}


if($ha -ne $null){ #if we have the MAC send WOL packet
    Write-host "Sending WOL to $ha"
    Send-MagicPacket -MagicPacket (Create-MagicPacket -HardwareAddress $ha)
}else{write-host "No hardware address available"}





