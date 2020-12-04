## Troubleshooting Active/Active loadbalanced pair of standalone FortiGates for resilience and scale


Public Load Balancer
---


The Azure Public Load Balancer is primarily situated for inbound public connections.  It has two types of inbound connections supported - "Load balancer rules" and "NAT rules".  Load balancer rules are for that traffic which you wish to be resliant and/or scaled.  These rules can be configured to use DNAT (default) or Direct Server Return (preferred). This is the typical use case, and there are some sample rules in place, defined by the template set.  NAT rules are primarily for management purposes.  These rules forward traffic (using DNAT) to only one of the backend pool (in this case either FortiGate A or FortiGate B).  By default port 443 and 22 for the first frontend are forwarded to FortiGate A, the same ports for the second frontend are forwarded to FortiGate B. 

### Possible Problem: Unable to use port 22 or 443 for Load Balancer rules
#### Reason: 
These ports are used in the "NAT rules"
#### Solution:
##### Option1 - 
You can add new frontends and public IPs to support this traffic.  
##### Option2 - 
You can change the management interface or management TCP ports on the ForiGates, delete or modify the NAT rules accordingly, and then ports 22 and 443 will be available to use for load balancer rules using the default frontends and public IPs.

### Possible Problem: Unable to communicate outbound from the FortiGate

#### Likely Reason: 
Public Load balancer misconfigured.  The public load balancer is also involved in outbound communication.  The public IPs associated with the LB frontends will be used for Source-NAT to communicate over the public internet. Thus, it needs to be configured correctly to allow this communication.

#### Solution: 
Verify that at least one inbound UDP and one inbound TCP rule is enabled on the public load balancer. 
See Azure documentation for more information:
https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-outbound-connections
Follow-up: If the problem persists, you can verify that packets are leaving the FortiGate correctly using the FortiOS CLI commands below:
From one terminal:

    diag sniffer packet any "host 8.8.8.8" 4

From a second terminal connected to the same FortiGate:

    execute telnet 8.8.8.8 53

The first terminal should then show packets leaving port1 destined for 8.8.8.8.  If that's the case the FortiGate is operating correctly.  However, if the telnet connection doesn't 'connect,' there's still a problem with the outbound SNAT through Azure.  You can try directly assigning public IPs to the primary vNICs of the FortiGates (in the Azure portal).  This will force the SNAT to use that public IP on the vNIC.  However, if you are using FGSP to support asymmetric routing, this will break the asymmetric support.  Another option is to call Azure support and ask them to troubleshoot the load balancer source NAT process.


### Possible Problem: Inbound conections through the public load balancer fail to establish when routed in via one FortiGate and out via the peer.

#### Reason: 
Public IPs associated with primary vNICs.  There are reasons to do this, such as establishing direct VPN tunnels to the FortiGates.  However, this results in a situation where return traffic is not properly matched to the incoming session.  Instead, it appears to be SNATed to the directly assigned IP.  Thus the return packets are sourced from the wrong public IP and the sessions will not establish.

#### Solution: 
Remove the public IPs from the primary vNICs or enable Source NAT for inbound policies.  

