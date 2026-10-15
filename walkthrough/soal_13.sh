# ==== SCRIPT untuk yaga (DB Master) ====

# 1. Install MariaDB
echo "nameserver 192.168.122.1" > /etc/resolv.conf
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y mariadb-server mariadb-client

# 2. Konfigurasi master: akses jaringan + binary log
cat <<'EOF' > /etc/mysql/mariadb.conf.d/60-replikasi.cnf
[mysqld]
bind-address = 0.0.0.0
server-id    = 1
log_bin      = mysql-bin
skip-name-resolve = 1
EOF
service mariadb restart || service mariadb start
sleep 3

# 3. User replikasi, database, user aplikasi (Network 4), dan tabel
mariadb -u root <<'EOF'
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY 'repl123';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';

CREATE DATABASE IF NOT EXISTS db_shibuya_k04;
CREATE USER IF NOT EXISTS 'jujutsu'@'192.213.4.%' IDENTIFIED BY 'jujutsu123';
GRANT ALL PRIVILEGES ON db_shibuya_k04.* TO 'jujutsu'@'192.213.4.%';
FLUSH PRIVILEGES;

USE db_shibuya_k04;
CREATE TABLE IF NOT EXISTS request_logs (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    worker        VARCHAR(50),
    client_ip     VARCHAR(45),
    forwarded_for VARCHAR(255),
    path          VARCHAR(255),
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# 4. Verifikasi master
mariadb -u root -e "SHOW MASTER STATUS; SHOW BINARY LOGS;"
mariadb -u root -e "SHOW DATABASES; SELECT user, host FROM mysql.user WHERE user IN ('repl','jujutsu'); DESCRIBE db_shibuya_k04.request_logs;"

# ==== SCRIPT untuk inumaki (DB Slave) ====

# 1. Install MariaDB
echo "nameserver 192.168.122.1" > /etc/resolv.conf
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y mariadb-server mariadb-client

# 2. Konfigurasi slave
cat <<'EOF' > /etc/mysql/mariadb.conf.d/60-replikasi.cnf
[mysqld]
bind-address = 0.0.0.0
server-id    = 2
relay_log    = relay-bin
read_only    = 1
EOF
service mariadb restart || service mariadb start
sleep 3

# 3. Hubungkan ke master (baca binlog dari awal)
mariadb -u root <<'EOF'
STOP SLAVE;
CHANGE MASTER TO
    MASTER_HOST='192.213.4.51',
    MASTER_USER='repl',
    MASTER_PASSWORD='repl123',
    MASTER_LOG_FILE='mysql-bin.000001',
    MASTER_LOG_POS=4,
    MASTER_SSL=0;
START SLAVE;
EOF
sleep 8

# 4. Verifikasi status replikasi
mariadb -u root -e "SHOW SLAVE STATUS\G" | grep -E "Master_Host|Slave_IO_Running|Slave_SQL_Running:|Last_IO_Error|Last_SQL_Error"
mariadb -u root -e "SHOW DATABASES; SHOW TABLES FROM db_shibuya_k04;"

# ==== SCRIPT untuk yaga (Uji replikasi: insert di master) ====

mariadb -u root -e "INSERT INTO db_shibuya_k04.request_logs (worker, client_ip, path) VALUES ('yaga-test', '192.213.4.51', '/uji-replikasi'); SELECT * FROM db_shibuya_k04.request_logs;"

# ==== SCRIPT untuk inumaki (Cek data di slave + akses remote Network 4) ====

mariadb -u root -e "SELECT * FROM db_shibuya_k04.request_logs;"
mariadb -h 192.213.4.51 -u jujutsu -pjujutsu123 --skip-ssl -e "SELECT CURRENT_USER() AS login_sebagai; SHOW DATABASES;"
