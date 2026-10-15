# ==== SCRIPT untuk kusakabe (Persiapan) ====

ip addr flush dev eth0
udhcpc -i eth0 -n -q
apk add apache2-utils curl

# ==== SCRIPT untuk gojo (Script analisis access log) ====

cat > /root/analisis_log.sh <<'SCRIPT'
L=/var/log/nginx/gojo_access.log
echo "===== ANALISIS ACCESS LOG GOJO ====="
echo "Total request tercatat : $(wc -l < $L)"
echo "--- Jumlah per status HTTP ---"
grep -o ' status=[0-9]*' $L | sort | uniq -c
echo "--- Klasifikasi ---"
echo "Sukses (200)                               : $(grep -c ' status=200 ' $L)"
echo "Dilayani dari cache (HIT)                  : $(grep -c 'cache=HIT' $L)"
echo "Ditolak rate limit (429, upstream=-)       : $(grep -c ' status=429 upstream=-' $L)"
echo "Gagal koneksi ke upstream (502/504)        : $(grep -cE ' status=50[24] ' $L)"
echo "Gagal aplikasi (upstream membalas 500/503) : $(grep -cE 'upstream_status=50[03]' $L)"
SCRIPT
chmod +x /root/analisis_log.sh

# ==== Uji 1: Web utama (gojo: reset log -> kusakabe: ab -> gojo: analisis) ====

: > /var/log/nginx/gojo_access.log                                   # gojo
ab -n 600 -c 30 -l http://jujutsu.k04.com/                            # kusakabe
bash /root/analisis_log.sh                                            # gojo

# ==== Uji 2: /api baseline (rate limit dimatikan sementara) ====

sed -i 's/^\(\s*\)limit_req zone=api_limit;/\1# limit_req zone=api_limit;/' /etc/nginx/sites-available/gojo && nginx -t && nginx -s reload   # gojo
: > /var/log/nginx/gojo_access.log                                   # gojo
ab -n 600 -c 30 -l http://jujutsu.k04.com/api                         # kusakabe
bash /root/analisis_log.sh                                            # gojo

# ==== Uji 3: /api dengan rate limit aktif ====

sed -i 's/# limit_req zone=api_limit;/limit_req zone=api_limit;/' /etc/nginx/sites-available/gojo && nginx -t && nginx -s reload             # gojo
: > /var/log/nginx/gojo_access.log                                   # gojo
ab -n 600 -c 30 -l http://jujutsu.k04.com/api                         # kusakabe
bash /root/analisis_log.sh                                            # gojo

# ==== Uji 4: Simulasi kegagalan koneksi (geto dimatikan) ====

: > /var/log/nginx/gojo_access.log                                   # gojo
service nginx stop                                                    # geto
for i in 1 2 3; do curl -s -o /dev/null -w "%{http_code}\n" http://jujutsu.k04.com/api; sleep 0.3; done   # kusakabe
service nginx start                                                   # geto
bash /root/analisis_log.sh; tail -n 3 /var/log/nginx/error.log        # gojo
