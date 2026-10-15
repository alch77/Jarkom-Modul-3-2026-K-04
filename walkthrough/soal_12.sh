# ==== SCRIPT untuk utahime (DNS Master) ====

# 1. Aktifkan forwarder ke DNS internet (gateway NAT GNS3)
cat <<'EOF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    forwarders { 192.168.122.1; };
    dnssec-validation no;
    allow-query { any; };
    allow-recursion { any; };
    listen-on { any; };
    listen-on-v6 { any; };
};
EOF

# 2. Daftarkan zona utama + zona reverse
cat <<'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k04.com" {
    type master;
    file "/etc/bind/jujutsu/jujutsu.k04.com";
    allow-transfer { 192.213.1.3; };
    also-notify { 192.213.1.3; };
    notify yes;
};

zone "1.213.192.in-addr.arpa" {
    type master;
    file "/etc/bind/jujutsu/1.213.192.in-addr.arpa";
    allow-transfer { 192.213.1.3; };
    also-notify { 192.213.1.3; };
    notify yes;
};
EOF

# 3. Zona utama: A record ke gojo + CNAME www
mkdir -p /etc/bind/jujutsu
cat <<'EOF' > /etc/bind/jujutsu/jujutsu.k04.com
$TTL    604800
@       IN      SOA     ns1.jujutsu.k04.com. admin.jujutsu.k04.com. (
                        2026101503 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL
@       IN      NS      ns1.jujutsu.k04.com.
@       IN      NS      ns2.jujutsu.k04.com.
ns1     IN      A       192.213.1.2
ns2     IN      A       192.213.1.3
utahime IN      A       192.213.1.2
shoko   IN      A       192.213.1.3
@       IN      A       192.213.1.4
www     IN      CNAME   jujutsu.k04.com.
EOF

# 4. Zona reverse (PTR)
cat <<'EOF' > /etc/bind/jujutsu/1.213.192.in-addr.arpa
$TTL    604800
@       IN      SOA     ns1.jujutsu.k04.com. admin.jujutsu.k04.com. (
                        2026101503 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL
@       IN      NS      ns1.jujutsu.k04.com.
@       IN      NS      ns2.jujutsu.k04.com.
2       IN      PTR     ns1.jujutsu.k04.com.
3       IN      PTR     ns2.jujutsu.k04.com.
4       IN      PTR     jujutsu.k04.com.
EOF

# 5. Validasi lalu restart
named-checkconf && \
named-checkzone jujutsu.k04.com /etc/bind/jujutsu/jujutsu.k04.com && \
named-checkzone 1.213.192.in-addr.arpa /etc/bind/jujutsu/1.213.192.in-addr.arpa && \
service named restart

# ==== SCRIPT untuk shoko (DNS Slave) ====

# 1. Forwarder ke DNS internet
cat <<'EOF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    forwarders { 192.168.122.1; };
    dnssec-validation no;
    allow-query { any; };
    allow-recursion { any; };
    listen-on { any; };
    listen-on-v6 { any; };
};
EOF

# 2. Zona utama + reverse sebagai slave
cat <<'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k04.com" {
    type slave;
    masters { 192.213.1.2; };
    file "/var/lib/bind/jujutsu.k04.com";
};

zone "1.213.192.in-addr.arpa" {
    type slave;
    masters { 192.213.1.2; };
    file "/var/lib/bind/1.213.192.in-addr.arpa";
};
EOF

# 3. Validasi, restart, cek hasil salinan
named-checkconf && service named restart
sleep 3
ls -l /var/lib/bind/

# ==== SCRIPT untuk itadori (Client) ====

# 1. A record dan CNAME
dig jujutsu.k04.com +short
dig www.jujutsu.k04.com | grep -A3 "ANSWER SECTION"

# 2. Reverse DNS (PTR)
dig -x 192.213.1.4 +short

# 3. Forwarder: resolusi domain internet
cat /etc/resolv.conf
ping -c 3 google.com
