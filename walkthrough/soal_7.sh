# ==== script untuk itadori, fushiguro, zenin, okkotsu, ino, kusakabe, miwa, dan kugisaki ====

# 1. Cek IP dan subnet (pastikan /24 dan masuk rentang pool yang benar)
ip -br a

# 2. Cek default route (pastikan gateway mengarah ke router/relay .2.1 atau .3.1)
ip route

# 3. Cek file konfigurasi DNS & domain search
cat /etc/resolv.conf

# 4. Cek alamat broadcast interface eth0
ip -4 addr show eth0 | grep brd

# ==== tengen ====

cat /var/lib/dhcp/dhcpd.leases
awk '/^lease/{ip=$2} /binding state/{st[ip]=$3} /hardware ethernet/{mac[ip]=$3} END{for(i in st) print i, mac[i, st[i]]}' /var/lib/dhcp/dhcpd.leases