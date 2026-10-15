# ==== SCRIPT untuk gojo (Proxy Cache + Rate Limit + Log) ====

mkdir -p /var/cache/nginx
cat <<'EOF' > /etc/nginx/sites-available/gojo
log_format gojo_log '$remote_addr - [$time_local] "$request" status=$status '
                    'upstream=$upstream_addr upstream_status=$upstream_status '
                    'rt=$request_time cache=$upstream_cache_status';

proxy_cache_path /var/cache/nginx/web levels=1:2 keys_zone=webcache:10m max_size=100m inactive=10m use_temp_path=off;

limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

upstream web_frontend {
    zone web_frontend 64k;
    server 192.213.4.31;   # maki
    server 192.213.4.32;   # panda
}

server {
    listen 80 default_server;
    server_name jujutsu.k04.com www.jujutsu.k04.com;
    access_log /var/log/nginx/gojo_access.log gojo_log;

    location / {
        proxy_pass http://web_frontend;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;

        proxy_cache        webcache;
        proxy_cache_valid  200 10m;
        add_header X-Cache-Status $upstream_cache_status always;
    }

    location /api {
        limit_req zone=api_limit;
        limit_req_status 429;

        proxy_pass http://192.213.4.20;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    }
}
EOF
nginx -t && nginx -s reload

# ==== SCRIPT untuk itadori (Uji cache) ====

curl -s -i http://jujutsu.k04.com/ | grep -E "X-Cache-Status|dilayani"   # MISS
curl -s -i http://jujutsu.k04.com/ | grep -E "X-Cache-Status|dilayani"   # HIT
curl -s -i http://jujutsu.k04.com/ | grep -E "X-Cache-Status|dilayani"   # HIT

# ==== SCRIPT untuk itadori (Uji rate limit) ====

for i in $(seq 1 20); do curl -s -o /dev/null -w "%{http_code} " http://jujutsu.k04.com/api; done; echo
for i in $(seq 1 20); do curl -s -o /dev/null -w "%{http_code}\n" http://jujutsu.k04.com/api; done | sort | uniq -c
for i in $(seq 1 10); do curl -s -o /dev/null -w "%{http_code} " http://jujutsu.k04.com/api; sleep 0.2; done; echo

# ==== SCRIPT untuk gojo (Cek access log) ====

tail -n 8 /var/log/nginx/gojo_access.log
