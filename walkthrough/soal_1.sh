# ==========================================
# === JICHI (Router / DHCP Relay / NAT) ===
# ==========================================
cat <<EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 192.213.1.1
    netmask 255.255.255.0

auto eth2
iface eth2 inet static
    address 192.213.2.1
    netmask 255.255.255.0

auto eth3
iface eth3 inet static
    address 192.213.3.1
    netmask 255.255.255.0

auto eth4
iface eth4 inet static
    address 192.213.4.1
    netmask 255.255.255.0
EOF

cat <<EOF > /root/.bashrc
apt update
apt install iptables -y
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE -s 192.213.0.0/16
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Verifikasi khusus jichi
echo "=== VERIFIKASI JICHI ==="
ip -br a
sysctl net.ipv4.ip_forward
iptables -t nat -S POSTROUTING
ping -c2 8.8.8.8
EOF


# ==========================================
# === KELOMPOK SERVER & NODE STATIS       ===
# ==========================================

# Template fungsi pembuat konfigurasi node statis agar lebih rapi
configure_static_node() {
    local node_name=\$1
    local ip_addr=\$2
    local gateway=\$3

    cat <<EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address \$ip_addr
    netmask 255.255.255.0
    gateway \$gateway
EOF

    cat <<EOF > /root/.bashrc
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Verifikasi node statis
echo "=== VERIFIKASI \$node_name (\$ip_addr) ==="
ip -br a ; ip route
ping -c2 \$gateway
ping -c2 8.8.8.8
ping -c2 google.com
EOF
}

# Terapkan ke masing-masing node (jalankan blok di bawah ini sesuai nama nodenya):

# --- Utahime (DNS Master - 192.213.1.2, Gateway 192.213.1.1) ---
configure_static_node "utahime" "192.213.1.2" "192.213.1.1"

# --- Shoko (DNS Slave - 192.213.1.3) ---
configure_static_node "shoko" "192.213.1.3" "192.213.1.1"

# --- Gojo (192.213.1.4) ---
configure_static_node "gojo" "192.213.1.4" "192.213.1.1"

# --- Tengen (DHCP Server - 192.213.4.10, Gateway 192.213.4.1) ---
configure_static_node "tengen" "192.213.4.10" "192.213.4.1"

# --- Geto (192.213.4.20) ---
configure_static_node "geto" "192.213.4.20" "192.213.4.1"

# --- Maki (192.213.4.31) ---
configure_static_node "maki" "192.213.4.31" "192.213.4.1"

# --- Panda (192.213.4.32) ---
configure_static_node "panda" "192.213.4.32" "192.213.4.1"

# --- Nanami (192.213.4.41) ---
configure_static_node "nanami" "192.213.4.41" "192.213.4.1"

# --- Todo (192.213.4.42) ---
configure_static_node "todo" "192.213.4.42" "192.213.4.1"

# --- Kirara (192.213.4.43) ---
configure_static_node "kirara" "192.213.4.43" "192.213.4.1"

# --- Yaga (192.213.4.51) ---
configure_static_node "yaga" "192.213.4.51" "192.213.4.1"

# --- Inumaki (192.213.4.52) ---
configure_static_node "inumaki" "192.213.4.52" "192.213.4.1"