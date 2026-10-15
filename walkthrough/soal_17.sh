# ==== SCRIPT untuk geto (Percaya IP klien hanya dari gojo) ====

cat <<'EOF' > /etc/nginx/sites-available/geto
# Rantai X-Forwarded-For yang rapi: "IP klien, IP gojo"
map $http_x_forwarded_for $xff_chain {
    ""      $realip_remote_addr;
    default "$http_x_forwarded_for, $realip_remote_addr";
}

upstream api_cluster {
    zone api_cluster 64k;
    server 192.213.4.41 weight=3;   # nanami
    server 192.213.4.42 weight=1;   # todo
}

server {
    listen 80 default_server;
    server_name _;

    # Hanya percaya header IP klien dari gojo (proxy terpercaya)
    set_real_ip_from 192.213.1.4;
    real_ip_header   X-Real-IP;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $xff_chain;
    }
}
EOF
nginx -t && nginx -s reload

# ==== SCRIPT untuk itadori (Client Network 2) ====

for i in 1 2 3; do curl -s http://jujutsu.k04.com/api; done
# Uji pemalsuan header langsung ke geto (harus diabaikan)
curl -s -H "X-Real-IP: 6.6.6.6" http://192.213.4.20/api

# ==== SCRIPT untuk ino (Client Network 3) ====

for i in 1 2 3; do curl -s http://jujutsu.k04.com/api; done

# ==== SCRIPT untuk yaga (Cek client_ip di database) ====

mariadb -u root -e "SELECT id, worker, client_ip, forwarded_for, path FROM db_shibuya_k04.request_logs ORDER BY id DESC LIMIT 8;"
