Content-Type: multipart/mixed; boundary="===============0086047718136476635=="
MIME-Version: 1.0

--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="config"

config system global
    set hostname "${fmg_vm_name}"
    set adom-status enable
    set clone-name-option keep
    set create-revision enable
    set device-view-mode tree
    set disable-module fortiview-noc
    set import-ignore-addr-cmt enable
    set partial-install enable
    set partial-install-force enable
    set partial-install-rev enable
    set perform-improve-by-ha enable
    set policy-hit-count enable
    set policy-object-icon enable
    set search-all-adoms enable
end
config system admin setting
    set gui-theme spring
    set idle_timeout 480
    set sdwan-monitor-history enable
    set show-add-multiple enable
    set show-checkbox-in-table enable
    set show-device-import-export enable
    set show-hostname enable
    set show_automatic_script enable
    set show_schedule_script enable
    set show_tcl_script enable
end
config system admin user
    edit devops
    set password', parameters('adminPassword'), '
    set profileid Super_User
    set adom all_adoms
    set policy-package all_policy_packages
    set rpc-permit read-write
end
config system interface
    edit "port1"
        set ip ${fmg_ipaddr}/${fmg_mask}
        set allowaccess ping https ssh
    next
end
config system route
    edit 1
        set device "port1"
        set gateway ${fmg_gw}
    next
end
%{ if fmg_ssh_public_key != "" }
config system admin user
    edit "${fmg_username}"
        set ssh-public-key1 "${trimspace(file(fmg_ssh_public_key))}"
    next
end
%{ endif }

%{ if fmg_license_file != "" }
--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="${fmg_license_file}"

${file(fmg_license_file)}

%{ endif }
--===============0086047718136476635==--
