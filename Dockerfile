FROM redis:alpine AS builder
COPY *.sh /
RUN chmod +x /*.sh && sh /build.sh
FROM redis:alpine
RUN apk update && \
    apk add bind-tools dcron tzdata hiredis libevent make curl dnscrypt-proxy inotify-tools && \
    apk upgrade
COPY --from=builder /src /src
COPY config/* /
RUN cd /src/unbound* && make install && chmod +x /*.sh &&\
    cp /src/named.cache /etc/unbound/named.cache && \
    cp /src/mosdns /usr/bin/mosdns && chmod +x /usr/bin/mosdns &&\
    cp /src/Country-only-cn-private.mmdb /Country-only-cn-private.mmdb &&\
    cp /src/dnscrypt.toml /dnscrypt.toml &&\
    cp -r /src/dnscrypt-resolvers /dnscrypt-resolvers &&\
    cp /src/repositories /etc/apk/repositories &&\
    rm -rf /src && apk del make && adduser -D unbound
ENV TZ Asia/Shanghai
ENV UPDATE weekly
ENV DNS_SERVERNAME PaoPaoDNS,blog.03k.org
ENV DNSPORT 53
ENV SOCKS5 "no"
ENV CNAUTO yes
ENV IPV6 "no"
VOLUME /data
EXPOSE 53/udp 5301/udp 5302/udp 5303/udp
CMD /init.sh
