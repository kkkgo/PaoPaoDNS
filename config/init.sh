#!/bin/sh
mkdir -p /data
rm /tmp/*.conf
rm /tmp/*.toml
if [ ! -f /data/unbound.conf ]; then
    cp /unbound.conf /data/
fi
if [ ! -f /data/redis.conf ]; then
    cp /redis.conf /data/
fi
if [ "$UPDATE" != "no" ]; then
    crond
    if [ ! -f /etc/periodic/"$UPDATE" ]; then
        rm -rf /etc/periodic/*
        mkdir -p /etc/periodic/"$UPDATE"
        cp /data_update.sh /etc/periodic/"$UPDATE"
    fi
fi
CORES=$(grep -c ^processor /proc/cpuinfo)
POWCORES=2
if [ "$CORES" -gt 4 ]; then
    POWCORES=4
fi
if [ "$CORES" -gt 6 ]; then
    POWCORES=8
fi
if [ "$CORES" -gt 12 ]; then
    POWCORES=16
fi
if [ "$CORES" -gt 24 ]; then
    POWCORES=32
fi
if [ "$CORES" -gt 48 ]; then
    POWCORES=64
fi
if [ "$CORES" -gt 96 ]; then
    POWCORES=128
fi
MEMSIZE=$(free -m | grep Mem | grep -Eo "[0-9]+" | tail -1)
# min:200m suggest:16G
MEM1=25m
MEM2=50m
MEM3=500000
MEM4=200mb
if [ "$MEMSIZE" -gt 500 ]; then
    MEM1=200m
    MEM2=400m
    MEM4=400mb
fi
if [ "$MEMSIZE" -gt 2000 ]; then
    MEM1=200m
    MEM2=400m
    MEM4=1500mb
fi
if [ "$MEMSIZE" -gt 2500 ]; then
    MEM1=300m
    MEM2=600m
    MEM4=2300mb
fi
if [ "$MEMSIZE" -gt 4000 ]; then
    MEM1=500m
    MEM2=1000m
    MEM4=3800mb
fi
if [ "$MEMSIZE" -gt 8000 ]; then
    MEM1=1000m
    MEM2=2000m
    MEM3=1000000
    MEM4=7500mb
fi
if [ "$MEMSIZE" -gt 16000 ]; then
    MEM1=2000m
    MEM2=4000m
    MEM3=10000000
    MEM4=15000mb
fi
if [ "$MEMSIZE" -gt 32000 ]; then
    MEM1=4000m
    MEM2=8000m
    MEM4=30000mb
fi
if [ "$MEMSIZE" -gt 64000 ]; then
    MEM1=8000m
    MEM2=16000m
    MEM4=24000mb
fi
IPREX4='([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])'
ETHIP=$(ip -o -4 route get 1.0.0.1 | grep -Eo "$IPREX4" | tail -1)
if [ -z "$ETHIP" ]; then
    ETHIP="127.0.0.2"
fi
sed "s/{CORES}/$CORES/g" /data/unbound.conf | sed "s/{POWCORES}/$POWCORES/g" | sed "s/{MEM1}/$MEM1/g" | sed "s/{MEM2}/$MEM2/g" | sed "s/{MEM3}/$MEM3/g" | sed "s/{ETHIP}/$ETHIP/g" | sed "s/{DNS_SERVERNAME}/$DNS_SERVERNAME/g" >/tmp/unbound.conf
if [ -z "$DNS_SERVERNAME" ]; then
    DNS_SERVERNAME="PaoPaoDNS,blog.03k.org"
fi
if [ -z "$DNSPORT" ]; then
    DNSPORT="53"
fi
if [ "$CNAUTO" != "no" ]; then
    DNSPORT="5301"
    if [ ! -f /data/mosdns.yaml ]; then
        cp /mosdns.yaml /data/
    fi
    if [ ! -f /data/dnscrypt.toml ]; then
        cp /dnscrypt.toml /data/
    fi
    if [ ! -f /data/dnscrypt-resolvers/public-resolvers.md ]; then
        mkdir -p /data/dnscrypt-resolvers/
        cp /dnscrypt-resolvers/* /data/dnscrypt-resolvers/
    fi
    if [ ! -f /data/Country-only-cn-private.mmdb ]; then
        cp /Country-only-cn-private.mmdb /data/Country-only-cn-private.mmdb
    fi
    if [ ! -f /data/force_nocn_list.txt ]; then
        cp /force_nocn_list.txt /data/
    fi
    if [ ! -f /data/force_cn_list.txt ]; then
        cp /force_cn_list.txt /data/
    fi
    if echo "$SOCKS5" | grep -Eoq ":[0-9]+"; then
        sed "s/#socksok//g" /data/dnscrypt.toml | sed "s/{SOCKS5}/$SOCKS5/g" | sed -r "s/listen_addresses.+/listen_addresses = ['0.0.0.0:5303']/g" >/data/dnscrypt-resolvers/dnscrypt_socks.yaml
        dnscrypt-proxy -config /data/dnscrypt-resolvers/dnscrypt_socks.yaml >/dev/null 2>&1 &
        sed "s/{DNSPORT}/5304/g" /tmp/unbound.conf | sed "s/#CNAUTO//g" | sed "s/#socksok//g" >/tmp/unbound_forward.conf
        sleep 5
    else
        sed "s/{DNSPORT}/5304/g" /tmp/unbound.conf | sed "s/#CNAUTO//g" | sed "s/#nosocks//g" >/tmp/unbound_forward.conf
    fi
    if [ "$IPV6" = "yes" ]; then
        sed "s/#ipv6ok//g" /data/mosdns.yaml >/tmp/mosdns.yaml
    else
        cat /data/mosdns.yaml >/tmp/mosdns.yaml
    fi
    cp /data/dnscrypt.toml /data/dnscrypt-resolvers/dnscrypt.toml
    dnscrypt-proxy -config /data/dnscrypt-resolvers/dnscrypt.toml >/dev/null 2>&1 &
    mosdns start -d /tmp -c mosdns.yaml >/dev/null 2>&1 &
    unbound -c /tmp/unbound_forward.conf >/dev/null 2>&1 &
fi
sed "s/{DNSPORT}/$DNSPORT/g" /tmp/unbound.conf >/tmp/unbound_raw.conf
unbound -c /tmp/unbound_raw.conf >/dev/null 2>&1 &

echo "nameserver 127.0.0.1" >/etc/resolv.conf
echo "nameserver 223.5.5.5" >>/etc/resolv.conf
echo "nameserver 1.0.0.1" >>/etc/resolv.conf
/watch_list.sh &
/data_update.sh &
sed "s/{MEM4}/$MEM4/g" /data/redis.conf >/tmp/redis.conf
ps
redis-server /tmp/redis.conf
