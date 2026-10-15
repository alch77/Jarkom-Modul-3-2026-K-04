# ==== SCRIPT untuk utahime (DNS Master) ====

# 1. Install BIND9
echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt update
apt install bind9 dnsutils -y

# 2. Konfigurasi options
cat <<'EOF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    dnssec-validation no;
    allow-query { any; };
    listen-on { any; };
    listen-on-v6 { any; };
};
EOF

# 3. Deklarasi zona master + izin transfer ke shoko
cat <<'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k04.com" {
    type master;
    file "/etc/bind/jujutsu/jujutsu.k04.com";
    allow-transfer { 192.213.1.3; };
    also-notify { 192.213.1.3; };
    notify yes;
};
EOF

# 4. File zona (SOA + NS untuk kedua server)
mkdir -p /etc/bind/jujutsu
cat <<'EOF' > /etc/bind/jujutsu/jujutsu.k04.com
$TTL    604800
@       IN      SOA     ns1.jujutsu.k04.com. admin.jujutsu.k04.com. (
                        2026101501 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL
@       IN      NS      ns1.jujutsu.k04.com.
@       IN      NS      ns2.jujutsu.k04.com.
ns1     IN      A       192.213.1.2
ns2     IN      A       192.213.1.3
EOF

# 5. Validasi dan restart
named-checkconf && named-checkzone jujutsu.k04.com /etc/bind/jujutsu/jujutsu.k04.com
service named restart

# ==== SCRIPT untuk shoko (DNS Slave) ====

# 1. Install BIND9
echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt update
apt install bind9 dnsutils -y

# 2. Konfigurasi options
cat <<'EOF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    dnssec-validation no;
    allow-query { any; };
    listen-on { any; };
    listen-on-v6 { any; };
};
EOF

# 3. Deklarasi zona slave (menyalin dari utahime)
cat <<'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k04.com" {
    type slave;
    masters { 192.213.1.2; };
    file "/var/lib/bind/jujutsu.k04.com";
};
EOF

# 4. Validasi, restart, dan cek hasil salinan zona
named-checkconf
service named restart
sleep 3
ls -l /var/lib/bind/

# ==== SCRIPT untuk itadori (Client) ====

# 1. Install dig (pinjam DNS NAT sementara)
cp /etc/resolv.conf /root/resolv.asli
echo "nameserver 192.168.122.1" > /etc/resolv.conf
apk add bind-tools curl
cp /root/resolv.asli /etc/resolv.conf

# 2. Query ke master dan slave (serial harus sama)
dig @192.213.1.2 jujutsu.k04.com SOA +short
dig @192.213.1.3 jujutsu.k04.com SOA +short
dig @192.213.1.3 jujutsu.k04.com NS +short

# ==== SCRIPT untuk utahime (Uji sinkronisasi: naikkan serial) ====

sed -i 's/2026101501/2026101502/' /etc/bind/jujutsu/jujutsu.k04.com
cat >> /etc/bind/jujutsu/jujutsu.k04.com <<'EOF'
utahime IN      A       192.213.1.2
shoko   IN      A       192.213.1.3
EOF
named-checkzone jujutsu.k04.com /etc/bind/jujutsu/jujutsu.k04.com && service named restart

# ==== SCRIPT untuk itadori (Verifikasi slave ikut ter-update) ====

dig @192.213.1.3 jujutsu.k04.com SOA +short
dig @192.213.1.3 utahime.jujutsu.k04.com +short
dig @192.213.1.3 shoko.jujutsu.k04.com +short
