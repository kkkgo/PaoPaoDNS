#!/bin/sh

# add tools
apk update
apk upgrade
apk add build-base flex byacc musl-dev gcc make git python3-dev swig libevent-dev openssl-dev expat-dev hiredis-dev go grep bind-tools

# build unbound
git clone https://github.com/NLnetLabs/unbound.git --depth 1 /unbound -b release-1.19.3
cd /unbound || exit
export CFLAGS="-O3"
./configure --with-libevent --with-pthreads --with-libhiredis --enable-cachedb \
    --disable-rpath --without-pythonmodule --disable-documentation \
    --disable-flto --disable-maintainer-mode --disable-option-checking --disable-rpath \
    --with-pidfile=/tmp/unbound.pid \
    --prefix=/usr --sysconfdir=/etc --localstatedir=/tmp --with-username=root
make
make install
mv /usr/sbin/unbound /src/
mv /usr/sbin/unbound-checkconf /src/
mv /usr/sbin/unbound-host /src

# build mosdns
mkdir -p /mosdns-build
git clone https://github.com/kkkgo/mosdns --depth 1 /mosdns-build
cd /mosdns-build || exit
go build -ldflags "-s -w" -trimpath -o /src/mosdns

#clean
rm /src/build.sh
