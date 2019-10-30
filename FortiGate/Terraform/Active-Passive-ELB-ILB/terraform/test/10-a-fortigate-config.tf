provider "fortios" {
    hostname = "52.137.47.196:8443"
    token = "Hpd5yy171z44zdtH5dmktcyqbpmkns"
}

resource "fortios_firewall_object_address" "s1" {
    name = "s1"
    type = "iprange"
    start_ip = "1.0.0.0"
    end_ip = "2.0.0.0"
    comment = "dd"
}
