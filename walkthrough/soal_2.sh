# ==== SCRIPT UNTUK TENGEN ====

# 1. Install paket DHCP Server
apt-get update -y && apt-get install -y isc-dhcp-server

# 2. Tentukan interface yang melayani DHCP
sed -i 's/^INTERFACESv4=.*/INTERFACESv4="eth0"/' /etc/default/isc-dhcp-server

# 3. Buat file konfigurasi utama DHCP
cat <<EOF > /etc/dhcp/dhcpd.conf
authoritative;
default-lease-time 600;
max-lease-time 7200;

option domain-name-servers 192.213.1.2, 192.213.1.3;
option domain-search "K04.com";

# Network 4 (lokal) -- TANPA range
subnet 192.213.4.0 netmask 255.255.255.0 {
    option routers 192.213.4.1;
}

# Scope Network 2 (Divisi A)
subnet 192.213.2.0 netmask 255.255.255.0 {
    option routers 192.213.2.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.213.2.255;

    pool {
        range 192.213.2.10 192.213.2.35;
    }
    pool {
        range 192.213.2.70 192.213.2.95;
    }
}

# Scope Network 3 (Divisi B)
subnet 192.213.3.0 netmask 255.255.255.0 {
    option routers 192.213.3.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.213.3.255;

    # Short Lease (30 menit)
    pool {
        range 192.213.3.10 192.213.3.89;
        default-lease-time 1800;
        max-lease-time 1800;
    }

    # Long Lease (12 jam)
    pool {
        range 192.213.3.100 192.213.3.199;
        default-lease-time 43200;
        max-lease-time 43200;
    }

    # Fixed Address untuk kugisaki
    host kugisaki {
        hardware ethernet 02:42:02:1e:9b:00;
        fixed-address 192.213.3.99;
    }
}
EOF

# 4. Siapkan file lease dan validasi konfigurasi
mkdir -p /var/lib/dhcp
touch /var/lib/dhcp/dhcpd.leases
dhcpd -t -cf /etc/dhcp/dhcpd.conf

# 5. Restart service DHCP
service isc-dhcp-server restart
service isc-dhcp-server status

# ==== SCRIPT untuk jichi =====

# 1. Install paket DHCP Relay
apt-get update -y && apt-get install -y isc-dhcp-relay

# 2. Konfigurasi service relay (Menuju Server Tengen di 192.213.4.10)
cat <<EOF > /etc/default/isc-dhcp-relay
SERVERS="192.213.4.10"
INTERFACES="eth1 eth2 eth3 eth4"
EOF

# 3. Aktifkan IP Forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# 4. Restart service relay
service isc-dhcp-relay restart
service isc-dhcp-relay status