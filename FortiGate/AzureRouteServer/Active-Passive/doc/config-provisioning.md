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
    set ip <b>172.16.136.68/26</b>
    set description internal
    set allowaccess probe-response
  next
  edit port3
    set mode static
    set ip <b>172.16.136.132/26</b>
    set description hasyncport
  next
  edit port4
    set mode static
    set ip <b>172.16.136.196/27</b>
    set description hamanagement
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
  set unicast-hb-peerip <b>172.16.136.132</b>
end
config router bgp
    set as <b>65005</b>
    set keepalive-timer 1
    set holdtime-timer 3
    set ebgp-multipath enable
    set graceful-restart enable
    config neighbor
        edit "<b>172.16.136.228</b>"
            set capability-default-originate enable
            set ebgp-enforce-multihop enable
            set soft-reconfiguration enable
            set interface "port2"
            set remote-as 65515
        next
        edit "<b>172.16.136.229</b>"
            set capability-default-originate enable
            set ebgp-enforce-multihop enable
            set soft-reconfiguration enable
            set interface "port2"
            set remote-as 65515
        next
    end
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
    set ip <b>172.16.136.5/26</b>
    set description external
    set allowaccess probe-response
  next
  edit port2
    set mode static
    set ip <b>172.16.136.69/26</b>
    set description internal
    set allowaccess probe-response
  next
  edit port3
    set mode static
    set ip <b>172.16.136.133/26</b>
    set description hasyncport
  next
  edit port4
    set mode static
    set ip <b>172.16.136.197/27</b>
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
      set gateway <b>172.16.136.196</b>
    next
  end
  set override disable
  set priority 1
  set unicast-hb enable
  set unicast-hb-peerip <b>172.16.136.132</b>
end
config router bgp
    set as <b>65005</b>
    set keepalive-timer 1
    set holdtime-timer 3
    set ebgp-multipath enable
    set graceful-restart enable
    config neighbor
        edit "<b>172.16.136.228</b>"
            set capability-default-originate enable
            set ebgp-enforce-multihop enable
            set soft-reconfiguration enable
            set interface "port2"
            set remote-as 65515
        next
        edit "<b>172.16.136.229</b>"
            set capability-default-originate enable
            set ebgp-enforce-multihop enable
            set soft-reconfiguration enable
            set interface "port2"
            set remote-as 65515
        next
    end
end
</code></pre>
