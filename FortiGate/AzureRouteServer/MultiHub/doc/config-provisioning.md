# Deployment configuration

After deployment, the below configuration has been automatically injected during the deployment. The bold sections are the default values. If parameters have been changed during deployment these values will be different.

## FortiGate A

<pre><code>
config system sdn-connector
  edit AzureSDN
    set type azure
  next
end
config router static
  edit 1
    set gateway <b>172.16.136.1</b>
    set device port1
  next
  edit 2
    set dst <b>172.16.136.0/22</b>
    set device port2
    set gateway <b>172.16.136.65</b>
  next
  edit 3
    set dst 168.63.129.16 255.255.255.255
    set device port2
    set gateway <b>172.16.136.65</b>
  next
  edit 4
    set dst 168.63.129.16 255.255.255.255
    set device port1
    set gateway <b>172.16.136.1</b>
  next
end
config system probe-response
  set http-probe-value OK
  set mode http-probe
end
config system interface
  edit port1
    set mode static
    set ip <b>172.16.136.4/26</b>
    set description external
    set allowaccess probe-response
  next
  edit port2
    set mode static
    set ip <b>172.16.136.68/24</b>
    set description internal
    set allowaccess probe-response
  next
  edit port3
    set mode static
    set ip <b>172.16.136.132/24</b>
    set description hasyncport
  next
  edit port4
    set mode static
    set ip <b>172.16.136.196/24</b>
    set description hammgmtport
    set allowaccess ping https ssh ftm
  next
end
config system ha
  set group-name AzureHA
  set mode a-p
  set hbdev port3 100
  set session-pickup enable
  set session-pickup-connectionless enable
  set ha-mgmt-status enable
  config ha-mgmt-interfaces
    edit 1
      set interface port4
      set gateway <b>172.16.136.193</b>
    next
  end
  set override disable
  set priority 255
  set unicast-hb enable
  set unicast-hb-peerip <b>172.16.136.134</b>
end
config router bgp
  set as 65007
  set keepalive-timer 1
  set holdtime-timer 3
  set ebgp-multipath enable
  set graceful-restart enable
  config neighbor
    edit <b>172.16.136.228</b>
      set capability-default-originate enable
      set ebgp-enforce-multihop enable
      set soft-reconfiguration enable
      set remote-as 65515
      set interface port1
    next
    edit <b>172.16.136.229</b>
      set capability-default-originate enable
      set ebgp-enforce-multihop enable
      set soft-reconfiguration enable
      set remote-as 65515
      set interface port1
    next
    edit <b>172.16.135.6</b>
      set capability-default-originate enable
      set ebgp-enforce-multihop enable
      set soft-reconfiguration enable
      set interface vx1
    next
    edit <b>172.16.135.7</b>
      set capability-default-originate enable
      set ebgp-enforce-multihop enable
      set soft-reconfiguration enable
      set interface vx1
    next
  end
end
config system vxlan
  edit vx1
    set interface port1
    set vni 1000
    set remote-ip <b>172.16.144.4 172.16.144.5</b>
  next
end
config system interface
  edit vx1
    set vdom root
    set ip <b>172.16.135.4</b>
    set allowaccess ping
    set type vxlan
    set snmp-index 7
    set interface port1
  next
end
config firewall policy
  edit 1
    set name <b>HUBAVNET-2-HUBBVNET</b>
    set srcintf port2
    set dstintf vx1
    set srcaddr all
    set dstaddr all
    set action accept
    set schedule always
    set service ALL
    set logtraffic all
    set logtraffic-start enable
  next
  edit 2
    set name <b>HUBAVNET-2-HUBBVNET</b>
    set srcintf vx1
    set dstintf port2
    set srcaddr all
    set dstaddr all
    set action accept
    set schedule always
    set service ALL
    set logtraffic all
    set logtraffic-start enable
  next
end
</code></pre>

## FortiGate B

<pre><code>
config system sdn-connector
  edit AzureSDN
    set type azure
  next
end
config router static
  edit 1
    set gateway <b>172.16.136.1</b>
    set device port1
  next
  edit 2
    set dst <b>172.16.136.0/22</b>
    set device port2
    set gateway <b>172.16.136.65</b>
  next
  edit 3
    set dst 168.63.129.16 255.255.255.255
    set device port2
    set gateway <b>172.16.136.65</b>
  next
  edit 4
    set dst 168.63.129.16 255.255.255.255
    set device port1
    set gateway <b>172.16.136.1</b>
  next
end
config system probe-response
  set http-probe-value OK
  set mode http-probe
end
config system interface
  edit port1
    set mode static
    set ip <b>172.16.136.6/26</b>
    set description external
    set allowaccess probe-response
  next
  edit port2
    set mode static
    set ip <b>172.16.136.70/26</b>
    set description internal
    set allowaccess probe-response
  next
  edit port3
    set mode static
    set ip <b>172.16.136.134/26</b>
    set description hasyncport
  next
  edit port4
    set mode static
    set ip <b>172.16.136.198/26</b>
    set description hammgmtport
    set allowaccess ping https ssh ftm
  next
end
config system ha
  set group-name AzureHA
  set mode a-p
  set hbdev port3 100
  set session-pickup enable
  set session-pickup-connectionless enable
  set ha-mgmt-status enable
  config ha-mgmt-interfaces
    edit 1
      set interface port4
      set gateway <b>172.16.136.193</b>
    next
  end
  set override disable
  set priority 1
  set unicast-hb enable
  set unicast-hb-peerip <b>172.16.136.133</b>
end

config system vxlan
  edit vx1
    set interface port1
    set vni 1000
    set remote-ip ', variables('hubBSn1IPfga'), ' ', variables('hubBSn1IPfgb')
  next
end
config system interface
  edit vx1
    set vdom root
    set ip ', variables('overlaySubnetIPhubAfgB'), '/', variables('overlaySubnetCIDRmask'), '\n set allowaccess ping\n set type vxlan\n set snmp-index 7\n set interface port1\n next\n end\n config router bgp\n config neighbor\n edit', variables('overlaySubnetIPhubBfgA'), '\n set ebgp-enforce-multihop enable\n set soft-reconfiguration enable\n set remote-as ', parameters('hubBFortiGateASN'), '\n next\n edit ', variables('overlaySubnetIPhubBfgB'), '\n set ebgp-enforce-multihop enable\n set soft-reconfiguration enable\n set remote-as', parameters('hubBFortiGateASN'), '\n next\n end\n end')]",
</code></pre>

<pre><code>
config router bgp
  set as 65007
  set keepalive-timer 1
  set holdtime-timer 3
  set ebgp-multipath enable
  set graceful-restart enable
  config neighbor
    edit 172.16.110.68
      set capability-default-originate enable
      set ebgp-enforce-multihop enable
      set soft-reconfiguration enable
      set remote-as 65515
      set interface port1
    next
    edit 172.16.110.69
      set capability-default-originate enable
      set ebgp-enforce-multihop enable
      set soft-reconfiguration enable
      set remote-as 65515
      set interface port1
    next
  end
end
</code></pre>
