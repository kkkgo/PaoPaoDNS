#!/bin/sh
mkdir -p /data
rm /tmp/*.conf >/dev/null 2>&1
rm /tmp/*.toml >/dev/null 2>&1
if [ ! -f /new.lock ]; then
    echo New version install ! Try clean...
    rm -rf /data/*.conf >/dev/null 2>&1
    rm -rf /data/*.yaml >/dev/null 2>&1
    rm -rf /data/*.toml >/dev/null 2>&1
    rm -rf /data/*.txt >/dev/null 2>&1
    rm -rf /data/*.mmdb >/dev/null 2>&1
    rm -rf /data/dnscrypt-resolvers >/dev/null 2>&1
    touch /new.lock
fi

if [ ! -f /data/unbound.conf ]; then
    cp /usr/sbin/unbound.conf /data/
fi
if [ ! -f /data/redis.conf ]; then
    cp /usr/sbin/redis.conf /data/
fi
if [ "$UPDATE" != "no" ]; then
    crond
    if [ ! -f /etc/periodic/"$UPDATE" ]; then
        rm -rf /etc/periodic/*
        mkdir -p /etc/periodic/"$UPDATE"
        cp /usr/sbin/data_update.sh /etc/periodic/"$UPDATE"
    fi
fi
CORES=$(grep -c ^processor /proc/cpuinfo)
POWCORES=2
if [ "$CORES" -gt 3 ]; then
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
free -m
free -h
MEMSIZE=$(free -m | grep Mem | grep -Eo "[0-9]+" | tail -1)
echo MEMSIZE:"$MEMSIZE"
# min:50m suggest:16G
MEM1=100k
MEM2=200k
MEM3=200
MEM4=16mb
safemem=yes
if [ "$MEMSIZE" -gt 500 ]; then
    MEM1=50m
    MEM2=100m
    MEM4=100mb
fi
if [ "$MEMSIZE" -gt 2000 ]; then
    safemem=no
    MEM1=200m
    MEM2=400m
    MEM4=450mb
fi
if [ "$MEMSIZE" -gt 2500 ]; then
    MEM1=220m
    MEM2=450m
    MEM3=500000
    MEM4=750mb
fi
if [ "$MEMSIZE" -gt 4000 ]; then
    MEM1=400m
    MEM2=800m
    MEM4=900mb
fi
if [ "$MEMSIZE" -gt 6000 ]; then
    MEM1=500m
    MEM2=1000m
    MEM4=1500mb
fi
if [ "$MEMSIZE" -gt 8000 ]; then
    MEM1=800m
    MEM2=1600m
    MEM3=1000000
    MEM4=1800mb
fi
if [ "$MEMSIZE" -gt 12000 ]; then
    MEM1=1000m
    MEM2=2000m
    MEM3=1000000
    MEM4=3000mb
fi
if [ "$MEMSIZE" -gt 16000 ]; then
    MEM1=1500m
    MEM2=3000m
    MEM3=10000000
    MEM4=4500mb
fi
if [ "$MEM1" = "100k" ]; then
    echo "[Warning] LOW MEMORY!"
    CORES=1
    POWCORES=1
fi
IPREX4='([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])'
ETHIP=$(ip -o -4 route get 1.0.0.1 | grep -Eo "$IPREX4" | tail -1)
if [ -z "$ETHIP" ]; then
    ETHIP="127.0.0.2"
fi
if [ -z "$DNS_SERVERNAME" ]; then
    DNS_SERVERNAME="PaoPaoDNS,blog.03k.org"
fi
if [ -z "$DNSPORT" ]; then
    DNSPORT="53"
fi

echo ====ENV TEST==== >/tmp/env.conf
echo MEM:"$MEM1" "$MEM2" "$MEM3" "$MEM4" >>/tmp/env.conf
echo CORES:"$CORES" >>/tmp/env.conf
echo POWCORES:"$POWCORES" >>/tmp/env.conf
echo TZ:"$TZ" >>/tmp/env.conf
echo UPDATE:"$UPDATE" >>/tmp/env.conf
echo DNS_SERVERNAME:"$DNS_SERVERNAME" >>/tmp/env.conf
echo ETHIP:"$ETHIP" >>/tmp/env.conf
echo DNSPORT:"$DNSPORT" >>/tmp/env.conf
echo SOCKS5:"$SOCKS5" >>/tmp/env.conf
echo CNAUTO:"$CNAUTO" >>/tmp/env.conf
echo IPV6:"$IPV6" >>/tmp/env.conf
echo ====ENV TEST==== >>/tmp/env.conf
cat /tmp/env.conf

sed "s/{CORES}/$CORES/g" /data/unbound.conf | sed "s/{POWCORES}/$POWCORES/g" | sed "s/{MEM1}/$MEM1/g" | sed "s/{MEM2}/$MEM2/g" | sed "s/{MEM3}/$MEM3/g" | sed "s/{ETHIP}/$ETHIP/g" | sed "s/{DNS_SERVERNAME}/$DNS_SERVERNAME/g" >/tmp/unbound.conf
if [ "$safemem" = "no" ]; then
    sed -i "s/#safemem//g" /tmp/unbound.conf
else
    sed -i "s/#lowrmem//g" /tmp/unbound.conf
fi
if [ "$CNAUTO" != "no" ]; then
    DNSPORT="5301"
    if [ ! -f /data/mosdns.yaml ]; then
        cp /usr/sbin/mosdns.yaml /data/
    fi
    if [ ! -f /data/dnscrypt.toml ]; then
        cp /usr/sbin/dnscrypt.toml /data/
    fi
    if [ ! -f /data/dnscrypt-resolvers/public-resolvers.md ]; then
        mkdir -p /data/dnscrypt-resolvers/
        cp /usr/sbin/dnscrypt-resolvers/* /data/dnscrypt-resolvers/
    fi
    if [ ! -f /data/Country-only-cn-private.mmdb ]; then
        cp /usr/sbin/Country-only-cn-private.mmdb /data/Country-only-cn-private.mmdb
    fi
    if [ ! -f /data/force_nocn_list.txt ]; then
        cp /usr/sbin/force_nocn_list.txt /data/
    fi
    if [ ! -f /data/force_cn_list.txt ]; then
        cp /usr/sbin/force_cn_list.txt /data/
    fi
    if echo "$SOCKS5" | grep -Eoq ":[0-9]+"; then
        sed "s/#socksok//g" /data/dnscrypt.toml | sed "s/{SOCKS5}/$SOCKS5/g" | sed -r "s/listen_addresses.+/listen_addresses = ['0.0.0.0:5303']/g" >/data/dnscrypt-resolvers/dnscrypt_socks.yaml
        dnscrypt-proxy -config /data/dnscrypt-resolvers/dnscrypt_socks.yaml >/dev/null 2>&1 &
        sed "s/{DNSPORT}/5304/g" /tmp/unbound.conf | sed "s/#CNAUTO//g" | sed "s/#socksok//g" >/tmp/unbound_forward.conf
        sed "s/#socksok//g" /data/mosdns.yaml >/tmp/mosdns.yaml
        sleep 5
    else
        sed "s/{DNSPORT}/5304/g" /tmp/unbound.conf | sed "s/#CNAUTO//g" | sed "s/#nosocks//g" >/tmp/unbound_forward.conf
        sed "s/#nosocks//g" /data/mosdns.yaml >/tmp/mosdns.yaml
    fi
    if [ "$IPV6" = "yes" ]; then
        sed -i "s/#ipv6ok//g" /tmp/mosdns.yaml
    fi
    if [ "$CNFALL" = "yes" ]; then
        sed -i "s/#cnfall//g" /tmp/mosdns.yaml
    else
        sed -i "s/#nofall//g" /tmp/mosdns.yaml
    fi
    cp /data/dnscrypt.toml /data/dnscrypt-resolvers/dnscrypt.toml
    dnscrypt-proxy -config /data/dnscrypt-resolvers/dnscrypt.toml >/dev/null 2>&1 &
    mosdns start -d /tmp -c mosdns.yaml >/dev/null 2>&1 &
    unbound -c /tmp/unbound_forward.conf -p >/dev/null 2>&1 &
fi
sed "s/{DNSPORT}/$DNSPORT/g" /tmp/unbound.conf >/tmp/unbound_raw.conf
unbound -c /tmp/unbound_raw.conf -p >/dev/null 2>&1 &
#Unexpected fallback while updating data
echo "nameserver 127.0.0.1" >/etc/resolv.conf
echo "nameserver 223.5.5.5" >>/etc/resolv.conf
echo "nameserver 1.0.0.1" >>/etc/resolv.conf
/usr/sbin/watch_list.sh &
/usr/sbin/data_update.sh &
sed "s/{MEM4}/$MEM4/g" /data/redis.conf >/tmp/redis.conf
ps
redis-server /tmp/redis.conf
