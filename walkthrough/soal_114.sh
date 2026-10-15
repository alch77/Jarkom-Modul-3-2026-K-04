# ==== SCRIPT untuk maki, panda, nanami, todo, kirara (script yang sama) ====

H=$(hostname)
echo "nameserver 192.168.122.1" > /etc/resolv.conf
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx php-fpm php-mysql curl

# Cari nama service PHP-FPM (misal php8.4-fpm)
PHPV=$(ls /etc/init.d | grep -E '^php[0-9.]+-fpm$' | sort -V | tail -n 1)

case "$H" in
  maki|panda)
    # Web frontend: hanya boleh diakses lewat gojo
    mkdir -p /var/www/web
    cat <<'EOF' > /var/www/web/index.php
<?php
echo "<h1>Frontend Jujutsu High dilayani oleh: " . gethostname() . "</h1>\n";
EOF
    cat <<'EOF' > /etc/nginx/sites-available/jujutsu
server {
    listen 80 default_server;
    server_name jujutsu.k04.com www.jujutsu.k04.com;
    root /var/www/web;
    index index.php;
