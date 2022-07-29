# Failover configuration

Once, licensed and rebooted, the FortiGate Fabric Connector needs to be configured to enable the cluster IP and route table to failover. Most of this config will be specific to your environment and so must be modified. The authentication part by default is configured using [managed identities](https://docs.fortinet.com/vm/azure/fortigate/7.0/azure-administration-guide/7.0.0/236610/creating-a-fabric-connector-using-a-managed-identity). It can be done a service principal as well more information can be found [here](https://docs.fortinet.com/vm/azure/fortigate/7.0/azure-administration-guide/7.0.0/948968/creating-an-azure-fabric-connector-using-service-principal)

## FortiGate A

```text
config system sdn-connector
  edit "AzureSDN"
  set type azure
  set ha-status enable
  set resource-group "fortigateapha"
  set subscription-id 00000000-0000-0000-0000-000000000000
  config nic
    edit "FortiGate-A-NIC1"
      config ip
        edit "ipconfig1"
        set public-ip "FGTAPClusterPublicIP"
      next
    end
    next
  end
  config route-table
    edit "FGTDefaultAPRouteTable"
    config route
    edit "toDefault"
      set next-hop "172.16.136.68"
    next
  end
  next
 end
end
```

For FortiGate B:

```text
config system sdn-connector
  edit "AzureSDN"
  set type azure
  set ha-status enable
  set resource-group "fortigateapha"
  set subscription-id 00000000-0000-0000-0000-000000000000
  config nic
    edit "FortiGate-B-NIC1"
    config ip
      edit "ipconfig1"
      set public-ip "FGTAPClusterPublicIP"
    next
  end
  next
  end
  config route-table
    edit "FGTDefaultAPRouteTable"
      config route
      edit "toDefault"
         set next-hop "172.16.136.69"
      next
    end
    next
  end
end
```
