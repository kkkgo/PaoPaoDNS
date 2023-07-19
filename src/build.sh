#!/bin/sh

# add tools
apk update
apk add curl redis git

# redis
rm -rf /usr/bin/redis-benchmark
mv /usr/bin/redis* /src/

# named
curl -sLo /src/named.cache https://www.internic.net/domain/named.cache
named_hash=$(curl -4Ls https://www.internic.net/domain/named.cache.md5 | grep -Eo "[a-zA-Z0-9]{32}" | head -1)
named_down_hash=$(md5sum /src/named.cache | grep -Eo "[a-zA-Z0-9]{32}" | head -1)
if [ "$named_down_hash" != "$named_hash" ]; then
    cp /named_down_hash_error .
    exit
fi

# mmdb
git clone https://github.com/kkkgo/Country-only-cn-private.mmdb --depth 1 /Country-only-cn-private
mmdb_hash=$(sha256sum /Country-only-cn-private/Country-only-cn-private.mmdb.xz | grep -Eo "[a-zA-Z0-9]{64}" | head -1)
mmdb_down_hash=$(grep -Eo "[a-zA-Z0-9]{64}" /Country-only-cn-private/Country-only-cn-private.mmdb.xz.sha256sum | head -1)
if [ "$mmdb_down_hash" != "$mmdb_hash" ]; then
    cp /mmdb_down_hash_error .
    exit
else
    cp /Country-only-cn-private/Country-only-cn-private.mmdb.xz /src/Country-only-cn-private.mmdb.xz
fi

# mark_data
git clone https://github.com/kkkgo/PaoPao-Pref --depth 1 /PaoPao-Pref
global_mark_hash=$(sha256sum /PaoPao-Pref/global_mark.dat | grep -Eo "[a-zA-Z0-9]{64}" | head -1)
global_mark_down_hash=$(grep -Eo "[a-zA-Z0-9]{64}" /PaoPao-Pref/global_mark.dat.sha256sum | head -1)
if [ "$global_mark_down_hash" != "$global_mark_hash" ]; then
    cp /global_mark_down_hash_error .
    exit
else
    cp /PaoPao-Pref/global_mark.dat /src/global_mark.dat
fi

# config dnscrypt
#gen dns toml
git clone https://github.com//DNSCrypt/dnscrypt-proxy --depth 1 /dnscrypt-proxy
grep -v "#" /dnscrypt-proxy/dnscrypt-proxy/example-dnscrypt-proxy.toml | grep . >/dnscrypt-proxy/dnsex.toml
sed -i -r 's/log_level.+/log_level = 6/g' /dnscrypt-proxy/dnsex.toml
sed -i -r 's/require_dnssec.+/require_dnssec = true/g' /dnscrypt-proxy/dnsex.toml
sed -i -r 's/cache_min_ttl .+/cache_min_ttl  = 1/g' /dnscrypt-proxy/dnsex.toml
sed -i -r 's/cache_neg_min_ttl .+/cache_neg_min_ttl  = 1/g' /dnscrypt-proxy/dnsex.toml
sed -i -r 's/reject_ttl.+/reject_ttl = 1/g' /dnscrypt-proxy/dnsex.toml
sed -i -r 's/cache_max_ttl .+/cache_max_ttl  = 600/g' /dnscrypt-proxy/dnsex.toml
sed -i -r 's/cache_neg_max_ttl .+/cache_neg_max_ttl  = 600/g' /dnscrypt-proxy/dnsex.toml
sed -i -r 's/require_nolog.+/require_nolog = false/g' /dnscrypt-proxy/dnsex.toml
sed -i -r 's/odoh_servers.+/odoh_servers = true/g' /dnscrypt-proxy/dnsex.toml
sed -i -r "s/netprobe_address.+/netprobe_address = '223.5.5.5:53'/g" /dnscrypt-proxy/dnsex.toml
sed -i -r "s/bootstrap_resolvers.+/bootstrap_resolvers = ['127.0.0.1:5301','1.0.0.1:53','8.8.8.8:53','223.5.5.5:53']/g" /dnscrypt-proxy/dnsex.toml
sed -i -r "s/listen_addresses.+/listen_addresses = ['0.0.0.0:5302']/g" /dnscrypt-proxy/dnsex.toml
sed -i "s|'https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md',|'https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md', 'https://cdn.jsdelivr.net/gh/DNSCrypt/dnscrypt-resolvers/v3/public-resolvers.md','https://cdn.staticaly.com/gh/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md', 'https://dnsr.evilvibes.com/v3/public-resolvers.md',|g" /dnscrypt-proxy/dnsex.toml
sed -i "s|'https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/relays.md',|'https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/relays.md', 'https://cdn.jsdelivr.net/gh/DNSCrypt/dnscrypt-resolvers/v3/relays.md','https://cdn.staticaly.com/gh/DNSCrypt/dnscrypt-resolvers/master/v3/relays.md', 'https://dnsr.evilvibes.com/v3/relays.md',|g" /dnscrypt-proxy/dnsex.toml

dnstest_bad=$(cat /src/dnstest_bad.txt)
echo "dnscrypt ban list: ""$dnstest_bad"
if [ -z "$dnstest_bad" ]; then
    dnstest_bad="'baddnslist'"
fi
sed -i "s/^disabled_server_names.*/disabled_server_names = [ $dnstest_bad ]/" /dnscrypt-proxy/dnsex.toml
rm /src/dnstest_bad.txt

echo "#socksokproxy = 'socks5://{SOCKS5}'" >/src/dnscrypt.toml
echo "#ttl_rule_okforwarding_rules = '/tmp/force_ttl_rules.toml'" >>/src/dnscrypt.toml
echo "#ttl_socks5_rule_okforwarding_rules = '/tmp/force_ttl_rules_socks5.toml'" >>/src/dnscrypt.toml
echo "#ttl_rule_okcloaking_rules = '/tmp/force_ttl_rules_cloaking.toml'" >>/src/dnscrypt.toml
cat /dnscrypt-proxy/dnsex.toml >>/src/dnscrypt.toml
git clone https://github.com/DNSCrypt/dnscrypt-resolvers.git --depth 1 /dnscrypt
mkdir -p /src/dnscrypt-resolvers
mv /dnscrypt/v3/relays.m* /src/dnscrypt-resolvers/
mv /dnscrypt/v3/public-resolvers.m* /src/dnscrypt-resolvers/

# trackerlist
git clone https://github.com/kkkgo/all-tracker-list.git --depth 1 /all-tracker-list
tracker_hash=$(sha256sum /all-tracker-list/trackerslist.txt.xz | grep -Eo "[a-zA-Z0-9]{64}" | head -1)
tracker_down_hash=$(grep -Eo "[a-zA-Z0-9]{64}" /all-tracker-list/trackerslist.txt.xz.sha256sum | head -1)
if [ "$tracker_hash" != "$tracker_down_hash" ]; then
    cp /tracker_down_hash_error .
    exit
else
    cp /all-tracker-list/trackerslist.txt.xz /src/trackerslist.txt.xz
fi

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
