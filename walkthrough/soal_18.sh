# ==== SCRIPT untuk geto (Backup + Passive Health Check) ====

cat <<'EOF' > /etc/nginx/sites-available/geto
map $http_x_forwarded_for $xff_chain {
    ""      $realip_remote_addr;
    default "$http_x_forwarded_for, $realip_remote_addr";
}

upstream api_cluster {
    zone api_cluster 64k;
    server 192.213.4.41 weight=3 max_fails=2 fail_timeout=5s;   # nanami (utama)
    server 192.213.4.42 weight=1 max_fails=2 fail_timeout=5s;   # todo   (utama)
    server 192.213.4.43 backup;                                 # kirara (cadangan)
}

server {
    listen 80 default_server;
    server_name _;

    set_real_ip_from 192.213.1.4;
    real_ip_header   X-Real-IP;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $xff_chain;
        proxy_next_upstream error timeout http_502 http_503 http_504;
    }
}
EOF
nginx -t && nginx -s reload

# ==== SCRIPT untuk itadori (Kondisi normal) ====

for i in $(seq 1 8); do curl -s -w "  HTTP %{http_code}\n" http://jujutsu.k04.com/api | grep -o '"worker":"[a-z]*"\|HTTP [0-9]*' | paste -sd' '; done

# ==== SCRIPT untuk nanami dan todo (Simulasi gangguan) ====

service nginx stop

# ==== SCRIPT untuk itadori (Saat gangguan -> kirara) ====

for i in $(seq 1 8); do curl -s -w "  HTTP %{http_code}\n" http://jujutsu.k04.com/api | grep -o '"worker":"[a-z]*"\|HTTP [0-9]*' | paste -sd' '; done
curl -s http://jujutsu.k04.com/api

# ==== SCRIPT untuk nanami dan todo (Pemulihan) ====

service nginx start

# ==== SCRIPT untuk itadori (Setelah pulih) ====

sleep 6
for i in $(seq 1 8); do curl -s -w "  HTTP %{http_code}\n" http://jujutsu.k04.com/api | grep -o '"worker":"[a-z]*"\|HTTP [0-9]*' | paste -sd' '; done
