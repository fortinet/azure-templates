Content-Type: multipart/mixed; boundary="===============0086047718136476635=="
MIME-Version: 1.0

--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="config"

config system global
    set hostname "${faz_vm_name}"
end
config system interface
    edit "port1"
        set ip ${faz_ipaddr}/${faz_mask}
        set allowaccess ping https ssh
    next
end
config system route
    edit 1
        set device "port1"
        set gateway ${faz_gw}
    next
end

%{ if faz_license_file != "" }
--===============0086047718136476635==
Content-Type: text/plain; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="${faz_license_file}"

${file(faz_license_file)}

%{ endif }
--===============0086047718136476635==--
