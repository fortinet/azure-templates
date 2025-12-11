# Deployment configuration

After deployment, the below configuration has been automatically injected during the deployment. The bold sections are the default values. If parameters have been changed during deployment these values will be different.

## FortiGate Hub A

<pre><code>
config system sdn-connector
  edit AzureSDN
    set type azure
  next
end
config router static
  edit 1
    set gateway <b>172.16.120.1</b>
    set device port1
  next
  edit 2
    set dst <b>172.16.120.0/24</b>
    set device port2
    set gateway <b>172.16.120.17</b>
  next
end
config system interface
  edit port1
    set mode static
    set ip <b>172.16.120.4/28</b>
    set description external
    set allowaccess probe-response
  next
  edit port2
    set mode static
    set ip <b>172.16.120.20/28</b>
    set description internal
    set allowaccess probe-response
  next
end
config router bgp
  set as <b>65007</b>
  set keepalive-timer 1
  set holdtime-timer 3
  set ebgp-multipath enable
  set graceful-restart enable
  config neighbor
    edit "<b>172.16.110.68</b>"
      set capability-default-originate enable
      set ebgp-enforce-multihop enable
      set soft-reconfiguration enable
      set interface "port1"
      set remote-as 65515
    next
    edit "<b>172.16.110.69</b>"
      set capability-default-originate enable
      set ebgp-enforce-multihop enable
      set soft-reconfiguration enable
      set interface "port1"
      set remote-as 65515
    next
  end
end
  config network
    edit 1
      set prefix "<b>172.16.121.0/24</b>"
    next
    edit 2
      set prefix "<b>172.16.122.0/24</b>"
    next
  end
end
config router static
  edit 3
    set dst <b>172.16.121.0/24</b>
    set gateway <b>172.16.120.17</b>
    set device port2
  next
  edit 4
    set dst <b>172.16.122.0/24</b>
    set gateway <b>172.16.120.17</b>
    set device port2
  next
  edit 5
    set dst <b>172.16.110.0/24</b>
    set gateway <b>172.16.120.17</b>
    set device port2
  next
end
config firewall policy
  edit 1
    set name Inbound
    set srcintf port1
    set dstintf port2
    set action accept
    set srcaddr all
    set dstaddr all
    set schedule always
    set service ALL
    set logtraffic all
    set logtraffic-start enable
  next
  edit 2
    set name Outbound
    set srcintf port2
    set dstintf port1
    set action accept
    set srcaddr all
    set dstaddr all
    set schedule always
    set service ALL
    set logtraffic all
    set logtraffic-start enable
  next
end
</code></pre>

## FortiGate Hub B

<pre><code>
config system sdn-connector
  edit AzureSDN
    set type azure
  next
end
config router static
  edit 1
    set gateway <b>172.16.130.1</b>
    set device port1
  next
  edit 2
    set dst <b>172.16.130.0/24</b>
    set device port2
    set gateway <b>172.16.130.17</b>
  next
end
config system interface
  edit port1
    set mode static
    set ip <b>172.16.130.4/28</b>
    set description external
    set allowaccess probe-response
  next
  edit port2
    set mode static
    set ip <b>172.16.130.20/28</b>
    set description internal
    set allowaccess probe-response
  next
end
config router bgp
  set as <b>65007</b>
  set keepalive-timer 1
  set holdtime-timer 3
  set ebgp-multipath enable
  set graceful-restart enable
  config neighbor
    edit "<b>172.16.111.68</b>"
      set capability-default-originate enable
      set ebgp-enforce-multihop enable
      set soft-reconfiguration enable
      set interface "port1"
      set remote-as 65515
    next
    edit "<b>172.16.111.69</b>"
      set capability-default-originate enable
      set ebgp-enforce-multihop enable
      set soft-reconfiguration enable
      set interface "port1"
      set remote-as 65515
    next
  end
  config network
    edit 1
      set prefix "<b>172.16.131.0/24</b>"
    next
    edit 2
      set prefix "<b>172.16.132.0/24</b>"
    next
  end
end
config router static
  edit 3
    set dst <b>172.16.131.0/24</b>
    set gateway <b>172.16.130.17</b>
    set device port2
  next
  edit 4
    set dst <b>172.16.132.0/24</b>
    set gateway <b>172.16.130.17</b>
    set device port2
  next
  edit 5
    set dst <b>172.16.111.0/24</b>
    set gateway <b>172.16.130.17</b>
    set device port2
  next
end
config firewall policy
  edit 1
    set name Inbound
    set srcintf port1
    set dstintf port2
    set action accept
    set srcaddr all
    set dstaddr all
    set schedule always
    set service ALL
    set logtraffic all
    set logtraffic-start enable
  next
  edit 2
    set name Outbound
    set srcintf port2
    set dstintf port1
    set action accept
    set srcaddr all
    set dstaddr all
    set schedule always
    set service ALL
    set logtraffic all
    set logtraffic-start enable
  next
end
</code></pre>
