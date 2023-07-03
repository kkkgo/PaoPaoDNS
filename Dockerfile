FROM alpine:edge AS builder
COPY --from=sliamb/prebuild-paopaodns /src/ /src/
COPY src/ /src/
RUN apk add --no-cache curl bind-tools go grep &&\
    go install github.com/ameshkov/dnslookup@latest &&\
    /root/go/bin/dnslookup -h && mv /root/go/bin/dnslookup /usr/bin/ &&\
    sh /src/build.sh
# JUST CHECK
RUN cp /src/Country-only-cn-private.mmdb /tmp/ &&\
    cp /src/global_mark.dat /tmp/ &&\
    cp /src/data_update.sh /tmp/ &&\
    cp /src/dnscrypt-resolvers/public-resolvers.md /tmp/ &&\
    cp /src/dnscrypt-resolvers/public-resolvers.md.minisig /tmp/ &&\
    cp /src/dnscrypt-resolvers/relays.md /tmp/ &&\
    cp /src/dnscrypt-resolvers/relays.md.minisig /tmp/ &&\
    cp /src/dnscrypt.toml /tmp/ &&\
    cp /src/force_cn_list.txt /tmp/ &&\
    cp /src/force_nocn_list.txt /tmp/ &&\
    cp /src/init.sh /tmp/ &&\
    cp /src/mosdns /tmp/ &&\
    cp /src/mosdns.yaml /tmp/ &&\
    cp /src/named.cache /tmp/ &&\
    cp /src/redis.conf /tmp/ &&\
    cp /src/repositories /tmp/ &&\
    cp /src/unbound /tmp/ &&\
    cp /src/unbound-checkconf /tmp/ &&\
    cp /src/unbound.conf /tmp/ &&\
    cp /src/unbound_custom.conf /tmp/ &&\
    cp /src/watch_list.sh /tmp/ &&\
    cp /src/redis-server /tmp/

FROM alpine:edge
COPY --from=builder /src/ /usr/sbin/
RUN apk add --no-cache dcron tzdata hiredis libevent curl dnscrypt-proxy inotify-tools bind-tools libgcc xz && \
    apk upgrade --no-cache &&\
    mkdir -p /etc/unbound && \
    mv /usr/sbin/named.cache /etc/unbound/named.cache &&           \
    adduser -D -H unbound &&\
    mv /usr/sbin/repositories /etc/apk/repositories
ENV TZ=Asia/Shanghai \
    UPDATE=weekly \
    DNS_SERVERNAME=PaoPaoDNS,blog.03k.org \
    DNSPORT=53 \
    CNAUTO=yes \
    CNFALL=yes \
    CN_TRACKER=yes \
    USE_HOSTS=no \
    IPV6=no \
    SOCKS5=IP:PORT \
    SERVER_IP=none \
    CUSTOM_FORWARD=IP:PORT \
    AUTO_FORWARD=no \
    AUTO_FORWARD_CHECK=yes \
    USE_MARK_DATA=no \
    RULES_TTL=0 \
    QUERY_TIME=2000ms \
    HTTP_FILE=no
VOLUME /data
WORKDIR /data
EXPOSE 53/udp 53/tcp 5304/udp 5304/tcp 7889/tcp
CMD /usr/sbin/init.sh