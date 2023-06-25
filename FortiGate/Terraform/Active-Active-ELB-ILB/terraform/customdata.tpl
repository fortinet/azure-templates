Content-Type: multipart/mixed; boundary="===============0086047718136476635=="
MIME-Version: 1.0

--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="config"

config system sdn-connector
	edit AzureSDN
		set type azure
	end
end
config sys global
    set admintimeout 120
    set hostname "${fgt_vm_name}"
    set timezone 26
    set gui-theme mariner
end
config vpn ssl settings
    set port 7443
end
config router static
    edit 1
        set gateway ${fgt_external_gw}
        set device port1
    next
    edit 2
        set dst ${vnet_network}
        set gateway ${fgt_internal_gw}
        set device port2
    next
    edit 3
        set dst 168.63.129.16 255.255.255.255
        set device port2
        set gateway ${fgt_internal_gw}
    next
    edit 4
        set dst 168.63.129.16 255.255.255.255
        set device port1
        set gateway ${fgt_external_gw}
    next
end
config system probe-response
    set http-probe-value OK
    set mode http-probe
end
config system interface
    edit port1
        set mode static
        set ip ${fgt_external_ipaddr}/${fgt_external_mask}
        set description external
        set allowaccess probe-response ping https ssh ftm
    next
    edit port2
        set mode static
        set ip ${fgt_internal_ipaddr}/${fgt_internal_mask}
        set description internal
        set allowaccess probe-response ping https ssh ftm
    next
end
%{ if fgt_ssh_public_key != "" }
config system admin
    edit "${fgt_username}"
        set ssh-public-key1 "${trimspace(file(fgt_ssh_public_key))}"
    next
end
%{ endif }
# API key can be set during cloud-init. The key needs to be exactly 30 chars long.
#config system api-user
#    edit restapi
#         set api-key 123456789012345678901234567890
#         set accprofile "super_admin"
#         config trusthost
#             edit 1
#                 set ipv4-trusthost x.y.z.w 255.255.255.255
#             next
#        end
#    next
#end
#
# Example config to provision an API user which can be used with the FortiGate Terraform Provider
# The API key is either an encrypted version. An unencrypted key can provided (exact 30 char long)
#config system api-user
#    edit restapi
#         set api-key Abcdefghijklmnopqrtsuvwxyz1234
#         set accprofile "super_admin"
#         config trusthost
#             edit 1
#                 set ipv4-trusthost w.x.y.z a.b.c.d
#             next
#        end
#    next
#end
#
# Uncomment for FGSP to allow assymetric traffic
# Verify the README
#config system ha
#    set session-pickup enable
#    set session-pickup-connectionless enable
#    set session-pickup-expectation enable
#    set session-pickup-nat enable
#    set override disable
#end
# < 7.2.1
#config system cluster-sync
#    edit 0
#        set peerip ${fgt_ha_peerip}
#        set syncvd "root"
#    next
#end
# > 7.2.1 - https://docs.fortinet.com/document/fortigate/7.2.1/fortios-release-notes/517622/changes-in-cli
#config system standalone-cluster
#    edit 0
#        set peerip ${fgt_ha_peerip}
#        set syncvd "root"
#    next
#end

%{ if fgt_license_fortiflex != "" }
--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="license"

LICENSE-TOKEN:${fgt_license_fortiflex}

%{ endif }
%{ if fgt_license_file != "" }
--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="${fgt_license_file}"

${file(fgt_license_file)}

%{ endif }
--===============0086047718136476635==--
