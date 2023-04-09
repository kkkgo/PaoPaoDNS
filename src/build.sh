#!/bin/sh
# build unbound
apk update
apk add curl musl-dev hiredis-dev gcc make python3-dev swig libevent-dev openssl-dev expat-dev
mkdir -p /unbound
cd /unbound || exit
curl -sLo unbound-latest.tar.gz https://nlnetlabs.nl/downloads/unbound/unbound-latest.tar.gz
unboud_hash=$(curl -s https://nlnetlabs.nl/downloads/unbound/unbound-1.17.1.tar.gz.sha256 | grep -Eo "[a-zA-Z0-9]{64}" | head -1)
unboud_down_hash=$(sha256sum unbound-latest.tar.gz | grep -Eo "[a-zA-Z0-9]{64}" | head -1)
if [ "$unboud_down_hash" != "$unboud_hash" ]; then
    cp /unboud_down_hash_error .
    exit
fi
curl -sLo /src/named.cache https://www.internic.net/domain/named.cache
named_hash=$(curl -s https://www.internic.net/domain/named.cache.md5 | grep -Eo "[a-zA-Z0-9]{32}" | head -1)
named_down_hash=$(md5sum /src/named.cache | grep -Eo "[a-zA-Z0-9]{32}" | head -1)
if [ "$named_down_hash" != "$named_hash" ]; then
    cp /named_down_hash_error .
    exit
fi
tar -xf unbound-latest.tar.gz
rm unbound-latest.tar.gz
cd unbound* || exit
export CFLAGS="-O2"
./configure --enable-subnet --with-libevent --with-pthreads --with-ssl --disable-static --enable-tfo-client \
    --enable-tfo-server --with-libhiredis --enable-cachedb --disable-rpath --without-pythonmodule --disable-documentation \
    --disable-flto --disable-maintainer-mode --disable-option-checking --disable-rpath --disable-silent-rules \
    --prefix=/usr --sysconfdir=/etc --mandir=/usr/share/man --localstatedir=/var --with-username=unbound
make -j2
make install
mv /usr/sbin/unbound /src/
mv /usr/sbin/unbound-checkconf /src/
mv /usr/sbin/unbound-control-setup /src/
mv /usr/sbin/unbound-host /src/

# build mosdns
apk add go git
mkdir -p /mosdns-build
git clone https://github.com/kkkgo/mosdns --depth 1 /mosdns-build
cd /mosdns-build || exit
go build -ldflags "-s -w" -trimpath -o /src/mosdns
curl -sLo /src/Country-only-cn-private.mmdb https://raw.githubusercontent.com/Loyalsoldier/geoip/release/Country-only-cn-private.mmdb
mmdb_hash=$(sha256sum /src/Country-only-cn-private.mmdb | grep -Eo "[a-zA-Z0-9]{64}" | head -1)
mmdb_down_hash=$(curl -s https://raw.githubusercontent.com/Loyalsoldier/geoip/release/Country-only-cn-private.mmdb.sha256sum | grep -Eo "[a-zA-Z0-9]{64}" | head -1)
if [ "$mmdb_down_hash" != "$mmdb_hash" ]; then
    cp /mmdb_down_hash_error .
    exit
fi

# config dnscrypt
#gen dns toml
apk add dnscrypt-proxy
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
dnscrypt-proxy -config /src/dnscrypt.toml &
#wait config download
sleep 5
mkdir -p /src/dnscrypt-resolvers
mv /src/relays.m* /src/dnscrypt-resolvers/
mv /src/public-resolvers.m* /src/dnscrypt-resolvers/

# apk mirrors
mkdir -p /src/
cp /etc/apk/repositories /src/repositories
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

#clean
rm /src/build.sh