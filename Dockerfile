FROM redis:alpine AS builder
COPY src/ /src/
RUN sh /src/build.sh
# JUST CHECK
RUN cp /src/Country-only-cn-private.mmdb /tmp/
RUN cp /src/data_update.sh /tmp/
RUN cp /src/dnscrypt-resolvers/public-resolvers.md /tmp/
RUN cp /src/dnscrypt-resolvers/public-resolvers.md.minisig /tmp/
RUN cp /src/dnscrypt-resolvers/relays.md /tmp/
RUN cp /src/dnscrypt-resolvers/relays.md.minisig /tmp/
RUN cp /src/dnscrypt.toml /tmp/
RUN cp /src/force_cn_list.txt /tmp/
RUN cp /src/force_nocn_list.txt /tmp/
RUN cp /src/init.sh /tmp/
RUN cp /src/mosdns /tmp/
RUN cp /src/mosdns.yaml /tmp/
RUN cp /src/named.cache /tmp/
RUN cp /src/redis.conf /tmp/
RUN cp /src/repositories /tmp/
RUN cp /src/unbound /tmp/
RUN cp /src/unbound-checkconf /tmp/
RUN cp /src/unbound.conf /tmp/
RUN cp /src/watch_list.sh /tmp/
RUN cp /src/redis-server /tmp/

FROM alpine:latest
COPY --from=builder /src/ /usr/sbin/
RUN apk add --no-cache dcron tzdata hiredis libevent curl dnscrypt-proxy inotify-tools bind-tools && \
    apk upgrade --no-cache &&\
    mkdir -p /etc/unbound && \
    mv /usr/sbin/named.cache /etc/unbound/named.cache && \
    adduser -D -H unbound &&\
    mv /usr/sbin/repositories /etc/apk/repositories
ENV TZ=Asia/Shanghai \
    UPDATE=weekly \
    DNS_SERVERNAME=PaoPaoDNS,blog.03k.org \
    DNSPORT=53 \
    SOCKS5=no \
    CNAUTO=yes \
    IPV6=no \
    CNFALL=yes
VOLUME /data
EXPOSE 53/udp 5301/udp 5302/udp 5303/udp 5304/udp
CMD /usr/sbin/init.sh