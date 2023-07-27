#!/bin/sh

# add tools
apk update
apk add build-base flex byacc musl-dev gcc make git python3-dev swig libevent-dev openssl-dev expat-dev hiredis-dev go grep bind-tools

# build dnscrypt server list
go install github.com/ameshkov/dnslookup@latest
mv /root/go/bin/dnslookup /usr/bin/
git clone https://github.com/DNSCrypt/dnscrypt-resolvers.git --depth 1 /dnscrypt-resolvers
export dnstest_bad="'baddnslist'"
testrec=$(nslookup local.03k.org)
if echo "$testrec" | grep -q "10.9.8.7"; then
    echo "Ready to test..."
    grep -E "##|sdns://" /dnscrypt-resolvers/v3/public-resolvers.md >/dnscrypt-resolvers/dnstest_alldns.txt
    grep -E "sdns://" /dnscrypt-resolvers/dnstest_alldns.txt >/dnscrypt-resolvers/dnstest_sdns.txt
    echo "" >>/dnscrypt-resolvers/dnstest_sdns.txt
    echo "" >>/dnscrypt-resolvers/dnstest_sdns.txt
    while read sdns; do
        name=$(grep -B 20 "$sdns" /dnscrypt-resolvers/dnstest_alldns.txt | grep -oP '(?<=## ).*' | tail -1)
        test=$(dnslookup local.03k.org $sdns)
        if [ "$?" = "0" ]; then
            if echo "$test" | grep -q "10.9.8.7"; then
                echo "$name"": OK."
            else
                export dnstest_bad="$dnstest_bad"", '$name'"
                echo "$name"": LOCAL BAD."
            fi
        else
            export dnstest_bad="$dnstest_bad"", '$name'"
            echo "$name"": CONNECT BAD."
        fi
    done </dnscrypt-resolvers/dnstest_sdns.txt
    echo "$dnstest_bad"
else
    echo "Test record failed.""$testrec"
fi
echo -n "$dnstest_bad" >/src/dnstest_bad.txt

# build unbound
git clone https://github.com/NLnetLabs/unbound.git --depth 1 /unbound
cd /unbound || exit
export CFLAGS="-O2"
./configure --with-libevent --with-pthreads --with-libhiredis --enable-cachedb \
    --disable-rpath --without-pythonmodule --disable-documentation \
    --disable-flto --disable-maintainer-mode --disable-option-checking --disable-rpath \
    --with-pidfile=/tmp/unbound.pid \
    --prefix=/usr --sysconfdir=/etc --localstatedir=/tmp --with-username=root
make
make install
mv /usr/sbin/unbound /src/
mv /usr/sbin/unbound-checkconf /src/

# build mosdns
mkdir -p /mosdns-build
git clone https://github.com/kkkgo/mosdns --depth 1 /mosdns-build
cd /mosdns-build || exit
go build -ldflags "-s -w" -trimpath -o /src/mosdns

#clean
rm /src/build.sh
