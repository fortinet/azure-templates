# Deployment configuration

After deployment, the below configuration has been automatically injected during the deployment. The bold sections are the default values. If parameters have been changed during deployment these values will be different.

## FortiGate A

<pre><code>
config system global
  set admin-sport 8443
end
config router static
  edit 1
    set gateway <b>10.0.1.1</b>
    set device port1
  next
  edit 2
    set dst <b>10.0.0.0/16</b>
    set gateway <b>10.0.2.1</b>
    set device "port2"
  next
end
config system interface
  edit "port1"
    set vdom "root"
    set mode static
    set ip <b>10.0.1.4 255.255.255.0</b>
    set allowaccess ping https ssh
    set description "external"
  next
  edit "port2"
    set vdom "root"
    set mode static
    set ip <b>10.0.2.4 255.255.255.0</b>
    set description "internal"
  next
  edit "port3"
    set vdom "root"
    set mode static
    set ip <b>10.0.3.4 255.255.255.240</b>
    set description "hasyncport"
  next
  edit "port4"
    set vdom "root"
    set mode static
    set ip <b>10.0.4.4 255.255.255.240</b>
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
      set gateway <b>10.0.4.1</b>
    next
  end
  set override disable
  set priority 255
  set unicast-hb enable
  set unicast-hb-peerip <b>10.0.3.5</b>
end
</code></pre>

## FortiGate B

<pre><code>
config system global
  set admin-sport 8443
end
config router static
  edit 1
    set gateway <b>10.0.1.1</b>
    set device port1
  next
  edit 2
    set dst <b>10.0.0.0 255.255.0.0</b>
    set gateway <b>10.0.2.1</b>
  set device "port2"
  next
end
config system interface
  edit "port1"
    set vdom "root"
    set mode static
    set ip <b>10.0.1.5 255.255.255.0</b>
    set allowaccess ping https ssh
    set description "external"
  next
  edit "port2"
    set vdom "root"
    set mode static
    set ip <b>10.0.2.5 255.255.255.0</b>
    set description "internal"
  next
  edit "port3"
    set mode static
    set ip <b>10.0.3.5 255.255.255.240</b>
    set description "hasyncport"
  next
  edit "port4"
    set vdom "root"
    set mode static
    set ip <b>10.0.4.5 255.255.255.240</b>
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
      set gateway <b>10.0.4.1</b>
    next
  end
  set override disable
  set priority 1
  set unicast-hb enable
  set unicast-hb-peerip <b>10.0.3.4</b>
end
</code></pre>
