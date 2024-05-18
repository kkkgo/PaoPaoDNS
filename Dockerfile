FROM alpine:edge AS builder
#actions COPY build_test_ok /
COPY --from=sliamb/prebuild-paopaodns /src/ /src/
COPY src/ /src/
RUN sh /src/build.sh
# build file check
RUN cp /src/Country-only-cn-private.mmdb.xz /tmp/ &&\
    cp /src/global_mark.dat /tmp/ &&\
    cp /src/data_update.sh /tmp/ &&\
    cp /src/dnscrypt-resolvers/public-resolvers.md /tmp/ &&\
    cp /src/dnscrypt-resolvers/public-resolvers.md.minisig /tmp/ &&\
    cp /src/dnscrypt-resolvers/relays.md /tmp/ &&\
    cp /src/dnscrypt-resolvers/relays.md.minisig /tmp/ &&\
    cp /src/dnscrypt.toml /tmp/ &&\
    cp /src/force_recurse_list.txt /tmp/ &&\
    cp /src/force_dnscrypt_list.txt /tmp/ &&\
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
    cp /src/custom_mod.yaml /tmp/ &&\
    cp /src/custom_env.ini /tmp/ &&\
    cp /src/trackerslist.txt.xz /tmp/ &&\
    cp /src/watch_list.sh /tmp/ &&\
    cp /src/redis-server /tmp/
# build binary check
RUN apk add --no-cache hiredis libevent libgcc && apk upgrade --no-cache
RUN if /src/mosdns version|grep kkkgo;then echo mosdns_check > /mosdns_check;else cp /mosdns_check /tmp/;fi
RUN if /src/unbound -V|grep libhiredis;then echo unbound_check > /unbound_check;else cp /unbound_check /tmp/;fi
RUN if /src/redis-server -v|grep build;then echo redis_check > /redis_check;else cp /redis_check /tmp/;fi

FROM alpine:edge
COPY --from=builder /src/ /usr/sbin/
RUN apk add --no-cache ca-certificates dcron tzdata hiredis libevent dnscrypt-proxy inotify-tools bind-tools libgcc xz && \
    apk upgrade --no-cache &&\
    mkdir -p /etc/unbound && \
    mv /usr/sbin/named.cache /etc/unbound/named.cache &&           \
    adduser -D -H unbound &&\
    mv /usr/sbin/repositories /etc/apk/repositories
# ARG DEVLOG_SW
ENV TZ=Asia/Shanghai \
    # DEVLOG=$DEVLOG_SW \
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
    CUSTOM_FORWARD_TTL=0 \
    AUTO_FORWARD=no \
    AUTO_FORWARD_CHECK=yes \
    USE_MARK_DATA=no \
    RULES_TTL=0 \
    HTTP_FILE=no \
    QUERY_TIME=2000ms \
    ADDINFO=no \
    SHUFFLE=no
VOLUME /data
WORKDIR /data
EXPOSE 53/udp 53/tcp 5304/udp 5304/tcp 7889/tcp
CMD /usr/sbin/init.sh