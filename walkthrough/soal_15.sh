# ==== SCRIPT untuk geto (Weighted Round Robin 3:1) ====

cat <<'EOF' > /etc/nginx/sites-available/geto
upstream api_cluster {
    zone api_cluster 64k;
    server 192.213.4.41 weight=3;   # nanami (porsi 3)
    server 192.213.4.42 weight=1;   # todo   (porsi 1)
}

server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    }
}
EOF
nginx -t && nginx -s reload

# ==== SCRIPT untuk yaga (Uji distribusi dari Data Center) ====

for i in $(seq 1 20); do curl -s http://192.213.4.20/ | grep -o '"worker":"[a-z]*"'; done
for i in $(seq 1 20); do curl -s http://192.213.4.20/ | grep -o '"worker":"[a-z]*"'; done | sort | uniq -c
