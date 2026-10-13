# ==== script untuk jichi ====

ip -br a
ip route
sysctl net.ipv4.ip_forward
service isc-dhcp-relay status

# ==== script untuk tengen ====

ip -br a
service isc-dhcp-server status