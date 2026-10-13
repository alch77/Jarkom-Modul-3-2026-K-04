# ==== script untuk jichi ====

service isc-dhcp-relay stop

# ==== script untuk itadori ====

ip addr flush dev eth0
udhcpc -i eth0 -n -q -t 3 -T 2
ip -br a

# ==== script untuk jichi ====

service isc-dhcp-relay start

# ==== script untuk itadori ====

udhcpc -i eth0 -n -q
ip -br a