# Deployment configuration

After deployment, the below configuration has been automatically injected during the deployment. The bold sections are the default values. If parameters have been changed during deployment these values will be different.

## FortiGate A

<pre>
config system global
  set admin-sport 8443
end
config router static
  edit 1
    set gateway 10.0.1.1
    set device port1
  next
  edit 2
    set dst 10.0.0.0/16
    set gateway 10.0.2.1
    set device "port2"
  next
end
config system interface
  edit "port1"
    set vdom "root"
    set mode static
    set ip 10.0.1.4 255.255.255.0
    set allowaccess ping https ssh
    set description "external"
  next
  edit "port2"
    set vdom "root"
    set mode static
    set ip 10.0.2.4 255.255.255.0
    set description "internal"
  next
  edit "port3"
    set vdom "root"
    set mode static
    set ip 10.0.3.4 255.255.255.240
    set description "hasyncport"
  next
  edit "port4"
    set vdom "root"
    set mode static
    set ip 10.0.4.4 255.255.255.240
    set allowaccess ping https ssh
    set description "management"
  next
end

config system ha
  set group-name "AzureHA"
  set mode a-p
  set hbdev "port3" 100
  set session-pickup enable
  set session-pickup-connectionless enable
  set ha-mgmt-status enable
  config ha-mgmt-interfaces
    edit 1
      set interface "port4"
      set gateway 10.0.4.1
    next
  end
  set override disable
  set priority 255
  set unicast-hb enable
  set unicast-hb-peerip 10.0.3.5
end

</pre>

## FortiGate B

<pre>
config system global
  set admin-sport 8443
end
config router static
  edit 1
set gateway 10.0.1.1
set device port1
  next
  edit 2
set dst 10.0.0.0 255.255.0.0
    set gateway 10.0.2.1
  set device "port2"
  next
end
config system interface
  edit "port1"
    set vdom "root"
    set mode static
    set ip 10.0.1.5 255.255.255.0
    set allowaccess ping https ssh
    set description "external"
  next
  edit "port2"
    set vdom "root"
    set mode static
    set ip 10.0.2.5 255.255.255.0
    set description "internal"
  next
  edit "port3"
    set mode static
    set ip 10.0.3.5 255.255.255.240
    set description "hasyncport"
  next
  edit "port4"
    set vdom "root"
    set mode static
    set ip 10.0.4.5 255.255.255.240
    set allowaccess ping https ssh
    set description "management"
  next
end
config system ha
  set group-name "AzureHA"
  set mode a-p
  set hbdev "port3" 100
  set session-pickup enable
  set session-pickup-connectionless enable
  set ha-mgmt-status enable
  config ha-mgmt-interfaces
    edit 1
      set interface "port4"
      set gateway 10.0.4.1
    next
  end
  set override disable
  set priority 1
  set unicast-hb enable
  set unicast-hb-peerip 10.0.3.4
end
</pre>