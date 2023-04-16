#!/bin/sh

# add tools
apk update
apk add curl musl-dev gcc make git python3-dev swig libgcc libevent-dev openssl-dev expat-dev hiredis-dev go
# build unbound
git clone https://github.com/NLnetLabs/unbound.git --depth 1 /unbound
cd /unbound || exit
export CFLAGS="-O2"
./configure --with-libevent --with-pthreads --with-libhiredis --enable-cachedb \
    --disable-rpath --without-pythonmodule --disable-documentation \
    --disable-flto --disable-maintainer-mode --disable-option-checking --disable-rpath \
    --with-pidfile=/tmp/unbound.pid \
    --prefix=/usr --sysconfdir=/etc --localstatedir=/tmp --with-username=unbound
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
