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

# --- NETWORK 2 (DIVISI A) ---
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

    pool {
        allow members of "pool1";
        range 192.213.2.10 192.213.2.35;
    }
    pool {
        allow members of "pool2";
        range 192.213.2.70 192.213.2.95;
    }
}

# --- NETWORK 3 (DIVISI B) — Short & Long Lease Berbasis MAC ---
class "short" {
    match if substring(hardware, 1, 6) = 02:42:99:c6:0d:00
          or substring(hardware, 1, 6) = 02:42:e2:f9:ce:00;    
}

class "long" {
    match if substring(hardware, 1, 6) = 02:42:cd:9f:21:00;        
}

subnet 192.213.3.0 netmask 255.255.255.0 {
    option routers 192.213.3.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.213.3.255;

    # Short Lease (1800 detik / 30 menit) untuk ino & kusakabe
    pool {
        allow members of "short";
        range 192.213.3.10 192.213.3.89;
        default-lease-time 1800;
        max-lease-time 1800;
    }

    # Long Lease (43200 detik / 12 jam) untuk miwa
    pool {
        allow members of "long";
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

# ==== script untuk ino, kusakabe, atau miwa

ip addr flush dev eth0
udhcpc -i eth0 -n -q
ip -br a