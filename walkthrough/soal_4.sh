# ==== script untuk tengen ====

cat <<EOF > /etc/dhcp/dhcpd.conf
authoritative;
default-lease-time 600;
max-lease-time 7200;

option domain-name-servers 192.213.1.2, 192.213.1.3;
option domain-search "K04.com";

# --- NETWORK 4 (Lokal tengen) -- TANPA range ---
subnet 192.213.4.0 netmask 255.255.255.0 {
    option routers 192.213.4.1;
}

# --- NETWORK 2 (DIVISI A) — DHCP Class & Pool Berbasis MAC ---
class "pool1" {
    match if substring(hardware, 1, 6) = 02:42:cc:ae:66:00    
          or substring(hardware, 1, 6) = 02:42:c6:f6:d9:00;
}

class "pool2" {
    match if substring(hardware, 1, 6) = 02:42:c3:a7:7e:00
          or substring(hardware, 1, 6) = 02:42:d1:aa:fb:00;  
}

subnet 192.213.2.0 netmask 255.255.255.0 {
    option routers 192.213.2.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.213.2.255;

    # Pool 1 untuk itadori & fushiguro (Rentang: .10 - .35)
    pool {
        allow members of "pool1";
        range 192.213.2.10 192.213.2.35;
    }

    # Pool 2 untuk zenin & okkotsu (Rentang: .70 - .95)
    pool {
        allow members of "pool2";
        range 192.213.2.70 192.213.2.95;
    }
}

# --- NETWORK 3 (DIVISI B) — Short Lease, Long Lease, & Fixed Address ---
subnet 192.213.3.0 netmask 255.255.255.0 {
    option routers 192.213.3.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.213.3.255;

    # Short Lease (30 menit = 1800 detik) untuk ino & kusakabe (Rentang: .10 - .89)
    pool {
        range 192.213.3.10 192.213.3.89;
        default-lease-time 1800;
        max-lease-time 1800;
    }

    # Long Lease (12 jam = 43200 detik) untuk miwa (Rentang: .100 - .199)
    pool {
        range 192.213.3.100 192.213.3.199;
        default-lease-time 43200;
        max-lease-time 43200;
    }

    # Fixed Address untuk kugisaki (.99)
    host kugisaki {
        hardware ethernet 02:42:02:1e:9b:00; 
        fixed-address 192.213.3.99;
    }
}
EOF

# Validasi konfigurasi dan restart layanan DHCP
dhcpd -t -cf /etc/dhcp/dhcpd.conf && service isc-dhcp-server restart

# ==== script untuk itdori, fushiguro, zenin, okkotsu ====

ip addr flush dev eth0
udhcpc -i eth0 -n -q
ip -br a