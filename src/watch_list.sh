#!/bin/sh
reload_mosdns() {
    if [ "$CN_TRACKER" = "yes" ]; then
        sed -r "s/.+\/\///g" /data/trackerslist.txt | sed -r "s/:.+//g" | sed -r "s/\/.+//g" | grep -E "^[-_.A-Za-z0-9]+$" | grep -E "[a-z]" | grep "." | sort -u >/tmp/cn_tracker_list.txt
    fi
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
        if [ "$AUTO_FORWARD" = "no" ]; then
            if [ ! -f /data/force_nocn_list.txt ]; then
                cp /usr/sbin/force_nocn_list.txt /data/
            fi
        fi
        if [ ! -f /data/force_cn_list.txt ]; then
            cp /usr/sbin/force_cn_list.txt /data/
        fi
        if [ ! -f /data/Country-only-cn-private.mmdb ]; then
            cp /usr/sbin/Country-only-cn-private.mmdb /data/Country-only-cn-private.mmdb
        fi
        file_list="/data/Country-only-cn-private.mmdb /data/force_cn_list.txt"
        if [ "$CN_TRACKER" = "yes" ]; then
            if [ ! -f /data/trackerslist.txt ]; then
                cp /usr/sbin/trackerslist.txt /data/
            fi
            file_list=$file_list" /data/trackerslist.txt"
        fi
        if echo "$CUSTOM_FORWARD" | grep -Eoq ":[0-9]+"; then
            file_list=$file_list" /data/force_forward_list.txt"
            if [ ! -f /data/force_forward_list.txt ]; then
                cp /usr/sbin/force_forward_list.txt /data/
            fi
        fi
        if [ "$AUTO_FORWARD" = "no" ]; then
            file_list=$file_list" /data/force_nocn_list.txt"
        fi
        inotifywait -e modify $file_list && reload_mosdns
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
if [ "$CNAUTO" != "no" ]; then
    watch_mosdns &
fi
watch_unbound &
