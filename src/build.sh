#!/bin/sh

# add tools
apk update
apk add curl redis git

# redis
rm -rf /usr/bin/redis-benchmark
mv /usr/bin/redis* /src/

# named
curl -sLo /src/named.cache https://www.internic.net/domain/named.cache
named_hash=$(curl -s https://www.internic.net/domain/named.cache.md5 | grep -Eo "[a-zA-Z0-9]{32}" | head -1)
named_down_hash=$(md5sum /src/named.cache | grep -Eo "[a-zA-Z0-9]{32}" | head -1)
if [ "$named_down_hash" != "$named_hash" ]; then
    cp /named_down_hash_error .
    exit
fi

# mmdb
curl -sLo /src/Country-only-cn-private.mmdb https://raw.githubusercontent.com/Loyalsoldier/geoip/release/Country-only-cn-private.mmdb
mmdb_hash=$(sha256sum /src/Country-only-cn-private.mmdb | grep -Eo "[a-zA-Z0-9]{64}" | head -1)
mmdb_down_hash=$(curl -s https://raw.githubusercontent.com/Loyalsoldier/geoip/release/Country-only-cn-private.mmdb.sha256sum | grep -Eo "[a-zA-Z0-9]{64}" | head -1)
if [ "$mmdb_down_hash" != "$mmdb_hash" ]; then
    cp /mmdb_down_hash_error .
    exit
fi

# config dnscrypt
#gen dns toml
curl -s https://raw.githubusercontent.com/DNSCrypt/dnscrypt-proxy/master/dnscrypt-proxy/example-dnscrypt-proxy.toml | grep -v "#" | grep . >/tmp/dnsex.toml
sed -i -r 's/log_level.+/log_level = 6/g' /tmp/dnsex.toml
sed -i -r 's/force_tcp.+/force_tcp = true/g' /tmp/dnsex.toml
sed -i -r 's/require_nolog.+/require_nolog = false/g' /tmp/dnsex.toml
sed -i -r 's/odoh_servers.+/odoh_servers = true/g' /tmp/dnsex.toml
sed -i -r "s/netprobe_address.+/netprobe_address = '223.5.5.5:53'/g" /tmp/dnsex.toml
sed -i -r "s/bootstrap_resolvers.+/bootstrap_resolvers = ['1.0.0.1:53','223.5.5.5:53','8.8.8.8:53','114.114.114.114:53']/g" /tmp/dnsex.toml
sed -i -r "s/listen_addresses.+/listen_addresses = ['0.0.0.0:5302']/g" /tmp/dnsex.toml
echo "#socksokproxy = 'socks5://{SOCKS5}'" >/src/dnscrypt.toml
cat /tmp/dnsex.toml >>/src/dnscrypt.toml
git clone https://github.com/DNSCrypt/dnscrypt-resolvers.git --depth 1 /dnscrypt
mkdir -p /src/dnscrypt-resolvers
mv /dnscrypt/v3/relays.m* /src/dnscrypt-resolvers/
mv /dnscrypt/v3/public-resolvers.m* /src/dnscrypt-resolvers/

# trackerlist
curl -s https://raw.githubusercontent.com/XIU2/TrackersListCollection/master/all.txt >/tmp/trackerslist.txt
echo "" >>/tmp/trackerslist.txt
curl -s https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt >>/tmp/trackerslist.txt
echo "" >>/tmp/trackerslist.txt
sort -u /tmp/trackerslist.txt >/src/trackerslist.txt

# apk mirrors
mkdir -p /src/
touch /src/repositories
add_repo() {
    sed "s/dl-cdn.alpinelinux.org/$1/g" /etc/apk/repositories >>/src/repositories
}
add_repo mirrors.ustc.edu.cn
add_repo mirrors.nju.edu.cn
add_repo mirrors.aliyun.com
add_repo mirror.lzu.edu.cn
add_repo mirrors.tuna.tsinghua.edu.cn
add_repo mirrors.zju.edu.cn
add_repo mirrors.sjtug.sjtu.edu.cn
add_repo dl-cdn.alpinelinux.org

# build time
bt=$(date +"%Y-%m-%d %H:%M:%S %Z")
sed -i "s/{bulidtime}/$bt/g" /src/init.sh
sed -i "s/{bulidtime}/$bt/g" /src/debug.sh

#clean
chmod +x /src/*.sh
rm /src/build.sh
