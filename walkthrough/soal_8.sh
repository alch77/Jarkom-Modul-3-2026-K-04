# ==== script untuk tengen ====

tcpdump -i eth0 -n -vvv 'udp port 67 or udp port 68' -w /root/dora.pcap

# ==== script untuk itadori ====

ip addr flush dev eth0
udhcpc -i eth0 -n -q

# ==== script untuk tengen ====

apt update && apt install tshark -y
tshark -r /root/dora.pcap