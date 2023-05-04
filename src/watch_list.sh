#!/bin/sh
reload_mosdns() {
    killall mosdns
    echo "mosdns reload..."
    mosdns start -d /tmp -c mosdns.yaml >/dev/null 2>&1 &
    sleep 5
    ps -ef | grep -v "grep" | grep "mosdns"
}

reload_unbound() {
    killall unbound
    echo "unbound reload..."
    unbound -c /tmp/unbound_raw.conf >/dev/null 2>&1 &
    if [ -f /tmp/unbound_forward.conf ]; then
        unbound -c /tmp/unbound_forward.conf >/dev/null 2>&1 &
    fi
    sleep 5
    ps -ef | grep -v "grep" | grep "unbound"
}

watch_mosdns() {
    while true; do
        if [ ! -f /data/force_nocn_list.txt ]; then
            cp /usr/sbin/force_nocn_list.txt /data/
        fi
        if [ ! -f /data/force_cn_list.txt ]; then
            cp /usr/sbin/force_cn_list.txt /data/
        fi
        if [ ! -f /data/Country-only-cn-private.mmdb ]; then
            cp /usr/sbin/Country-only-cn-private.mmdb /data/Country-only-cn-private.mmdb
        fi
        if echo "$CUSTOM_FORWARD" | grep -Eoq ":[0-9]+"; then
            if [ ! -f /data/force_forward_list.txt ]; then
                cp /usr/sbin/force_forward_list.txt /data/
            fi
            inotifywait -e modify /data/force_cn_list.txt /data/force_nocn_list.txt /data/force_forward_list.txt /data/Country-only-cn-private.mmdb && reload_mosdns
        else
            inotifywait -e modify /data/force_cn_list.txt /data/force_nocn_list.txt /data/Country-only-cn-private.mmdb && reload_mosdns
        fi
    done
}

watch_unbound() {
    if [ ! -f /etc/unbound/named.cache ]; then
        touch /etc/unbound/named.cache
    fi
    while true; do
        inotifywait -e modify /etc/unbound/named.cache && reload_unbound
    done
}
watch_mosdns &
watch_unbound &
