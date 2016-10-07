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






