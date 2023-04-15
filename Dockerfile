FROM redis:alpine AS builder
COPY src/ /src/
RUN sh /src/build.sh
FROM redis:alpine
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