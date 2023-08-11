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
dnstest_bad="'adfilter-adl', 'adfilter-adl-ipv6', 'adfilter-per', 'adfilter-per-ipv6', 'adfilter-syd', 'adfilter-syd-ipv6', 'adguard-dns-family-ipv6', 'adguard-dns-ipv6', 'adguard-dns-unfiltered-ipv6', 'ahadns-doh-la', 'ahadns-doh-nl', 'ams-ads-doh-nl', 'ams-dnscrypt-nl', 'ams-dnscrypt-nl-ipv6', 'ams-doh-nl', 'ams-doh-nl-ipv6', 'att', 'bortzmeyer-ipv6', 'brahma-world', 'brahma-world-ipv6', 'circl-doh-ipv6', 'cisco-familyshield-ipv6', 'cisco-ipv6', 'cisco-ipv6-doh', 'cleanbrowsing-security', 'cloudflare-family-ipv6', 'cloudflare-family-ipv6', 'cloudflare-ipv6', 'cloudflare-ipv6', 'cloudflare-security-ipv6', 'cloudflare-security-ipv6', 'comodo-02', 'dct-at1', 'dct-nl1', 'dct-ru1', 'decloudus-nogoogle-tstipv6', 'dns.digitale-gesellschaft.ch-ipv6', 'dns.digitale-gesellschaft.ch-ipv6', 'dns.digitalsize.net-ipv6', 'dns.sb', 'dnscrypt-de-blahdns-ipv6', 'dnscrypt.ca-1-doh-ipv6', 'dnscrypt.ca-1-ipv6', 'dnscrypt.ca-2-doh-ipv6', 'dnscrypt.ca-2-ipv6', 'dnscrypt.uk-ipv6', 'dnsforfamily-v6', 'dnswarden-uncensor-dc', 'doh-crypto-sx-ipv6', 'doh-crypto-sx-ipv6', 'doh-ibksturm', 'doh.ffmuc.net-v6', 'doh.ffmuc.net-v6-2', 'doh.tiar.app', 'doh.tiar.app-doh', 'doh.tiar.app-doh-ipv6', 'doh.tiar.app-ipv6', 'doh.tiarap.org', 'doh.tiarap.org-ipv6', 'faelix-uk-ipv6', 'faelix-uk-ipv6', 'ffmuc.net', 'ffmuc.net-v6', 'google-ipv6', 'ibksturm', 'jp.tiar.app', 'jp.tiar.app-doh', 'jp.tiar.app-doh-ipv6', 'jp.tiar.app-ipv6', 'jp.tiarap.org', 'jp.tiarap.org-ipv6', 'meganerd-doh-ipv6', 'meganerd-ipv6', 'nextdns-ipv6', 'oszx', 'plan9dns-fl-doh-ipv6', 'plan9dns-mx-doh-ipv6', 'plan9dns-nj-doh-ipv6', 'publicarray-au2-doh', 'quad9-doh-ip6-port443-filter-ecs-pri', 'quad9-doh-ip6-port443-filter-ecs-pri', 'quad9-doh-ip6-port443-filter-pri', 'quad9-doh-ip6-port443-filter-pri', 'quad9-doh-ip6-port443-filter-pri', 'quad9-doh-ip6-port443-nofilter-ecs-pri', 'quad9-doh-ip6-port443-nofilter-ecs-pri', 'quad9-doh-ip6-port443-nofilter-pri', 'quad9-doh-ip6-port443-nofilter-pri', 'quad9-doh-ip6-port5053-filter-ecs-pri', 'quad9-doh-ip6-port5053-filter-ecs-pri', 'quad9-doh-ip6-port5053-filter-pri', 'quad9-doh-ip6-port5053-filter-pri', 'quad9-doh-ip6-port5053-filter-pri', 'quad9-doh-ip6-port5053-nofilter-ecs-pri', 'quad9-doh-ip6-port5053-nofilter-ecs-pri', 'quad9-doh-ip6-port5053-nofilter-pri', 'quad9-doh-ip6-port5053-nofilter-pri', 'sby-doh-limotelu', 'sby-limotelu', 'scaleway-ams-ipv6', 'scaleway-fr-ipv6', 'sth-ads-doh-se', 'sth-dnscrypt-se', 'sth-dnscrypt-se-ipv6', 'sth-doh-se', 'uncensoreddns-dk-ipv6', 'uncensoreddns-ipv6', 'userspace-australia-ipv6', 'userspace-australia-ipv6', 'v.dnscrypt.uk-ipv6', 'yandex', 'yandex'"

echo "dnscrypt ban list: ""$dnstest_bad"
if [ -z "$dnstest_bad" ]; then
    dnstest_bad="'baddnslist'"
fi
sed -i "s/^disabled_server_names.*/disabled_server_names = [ $dnstest_bad ]/" /dnscrypt-proxy/dnsex.toml
rm /src/dnstest_bad.txt

echo "#socksokproxy = 'socks5://{SOCKS5}'" >/src/dnscrypt.toml
echo "#ttl_rule_okforwarding_rules = '/tmp/force_ttl_rules.toml'" >>/src/dnscrypt.toml
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
