### Configure network information for target system and activate network devices in the installer environment (optional)
### ref: https://www.golinuxcloud.com/wp-content/uploads/2020/04/Red_Hat_CentOS_8_Kickstart_Example.txt
### --onboot	  enable device at a boot time
### --device	  device to be activated and / or configured with the network command
### --bootproto	  method to obtain networking configuration for device (default dhcp)
### --noipv6	  disable IPv6 on this device
###
%{ if ip != null && ip != "" ~}
network --device=${device} --bootproto=static --ip=${ip} --netmask=${cidrnetmask("${ip}/${netmask}")} --gateway=${gateway} --nameserver=${join(",", dns)}
%{ else ~}
#network --device=${device} --bootproto=dhcp --noipv6 --bootproto=dhcp --hostname=${hostname}
network --device=${device} --bootproto=dhcp --bootproto=dhcp --hostname=${hostname}
%{ endif ~}
