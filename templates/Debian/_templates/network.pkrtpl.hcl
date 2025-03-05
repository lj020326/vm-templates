d-i netcfg/choose_interface select ${device}
d-i netcfg/get_domain string ${domain}
d-i netcfg/get_hostname string ${hostname}
%{ if ip != null && ip != "" ~}
d-i netcfg/disable_autoconfig boolean true
d-i netcfg/get_ipaddress string ${ip}
d-i netcfg/get_netmask string ${cidrnetmask("${ip}/${netmask}")}
d-i netcfg/get_gateway string ${gateway}
d-i netcfg/get_nameservers string ${join(" ", dns)}
d-i netcfg/confirm_static boolean true
%{ endif ~}
# Disable annoying WEP key dialog
d-i netcfg/wireless_wep string
