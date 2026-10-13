# ==== SCRIPT untuk jichi ====

# 1. Install paket DHCP Relay
apt-get update && apt-get install -y isc-dhcp-relay

# 2. Buat konfigurasi isc-dhcp-relay
cat <<EOF > /etc/default/isc-dhcp-relay
SERVERS="192.213.4.10"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
EOF

# 3. Pastikan IP Forwarding aktif
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# 4. Restart dan cek status service relay
service isc-dhcp-relay restart
service isc-dhcp-relay status

# ==== SCRIPT untuk kugisaki ====

# 1. Konfigurasi interface agar menggunakan DHCP
cat <<EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

# 2. Aktifkan interface dan minta alokasi IP baru
ifup eth0 2>/dev/null || ip link set eth0 up
ip addr flush dev eth0
udhcpc -i eth0 -n -q

# 3. Verifikasi hasil konfigurasi IP dan routing
ip -br a ; ip route