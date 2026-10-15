# ==== SCRIPT untuk gojo (Path-Based Routing) ====

cat <<'EOF' > /etc/nginx/sites-available/gojo
upstream web_frontend {
    zone web_frontend 64k;
    server 192.213.4.31;   # maki
    server 192.213.4.32;   # panda
}

server {
    listen 80 default_server;
    server_name jujutsu.k04.com www.jujutsu.k04.com;

    # Path "/" -> worker frontend (Round Robin)
    location / {
        proxy_pass http://web_frontend;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    }

    # Path "/api" -> load balancer internal geto
    location /api {
        proxy_pass http://192.213.4.20;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    }
}
EOF
nginx -t && nginx -s reload

# ==== SCRIPT untuk itadori (Client Divisi A) ====

for i in 1 2 3 4; do curl -s http://jujutsu.k04.com/; done
for i in 1 2 3 4; do curl -s http://www.jujutsu.k04.com/api; done

# ==== SCRIPT untuk ino (Client Divisi B) ====

ip addr flush dev eth0
udhcpc -i eth0 -n -q
apk add curl
for i in 1 2 3 4; do curl -s http://jujutsu.k04.com/; done
for i in 1 2 3 4; do curl -s http://jujutsu.k04.com/api; done
