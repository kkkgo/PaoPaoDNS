#!/bin/sh
while ps | grep -v grep | grep inotifywait; do
    killall inotifywait
done
reload_watch() {
    echo "Reload watchlist..."
    pid_list=$(pgrep watch_list)
    /usr/sbin/watch_list.sh &
    kill $pid_list
}

reload_mosdns() {
    if [ "$CN_TRACKER" = "yes" ]; then
        sed 's/\r$//' /data/trackerslist.txt | sed -r "s/.+\/\///g" | sed -r "s/:.+//g" | sed -r "s/\/.+//g" | grep -E "^[-_.A-Za-z0-9]+$" | grep -E "[a-z]" | grep "." | sort -u >/tmp/cn_tracker_list.txt
    fi
    if [ -f /data/force_nocn_list.txt ]; then
        sed 's/\r$//' /data/force_nocn_list.txt | grep -E "^[a-zA-Z0-9]" >/tmp/force_nocn_list.txt
    fi
    if [ -f /data/force_cn_list.txt ]; then
        sed 's/\r$//' /data/force_cn_list.txt | grep -E "^[a-zA-Z0-9]" >/tmp/force_cn_list.txt
    fi
    if [ -f /data/force_forward_list.txt ]; then
        sed 's/\r$//' /data/force_forward_list.txt | grep -E "^[a-zA-Z0-9]" >/tmp/force_forward_list.txt
    fi
    if [ ! -f /data/Country-only-cn-private.mmdb ]; then
        cp /usr/sbin/Country-only-cn-private.mmdb /data/Country-only-cn-private.mmdb
    fi
    while ps | grep -v grep | grep mosdns; do
        killall mosdns
    done
    echo "mosdns reload..."
    killall mosdns
    sleep 1
    mosdns start -d /tmp -c mosdns.yaml >/dev/null 2>&1 &
    sleep 1
    ps -ef | grep -v "grep" | grep "mosdns"
    reload_watch
}

reload_unbound() {
    while ps | grep -v grep | grep unbound; do
        killall unbound
    done
    echo "unbound reload..."
    killall unbound
    unbound -c /tmp/unbound_raw.conf >/dev/null 2>&1 &
    if [ -f /tmp/unbound_forward.conf ]; then
        unbound -c /tmp/unbound_forward.conf >/dev/null 2>&1 &
    fi
    sleep 1
    ps -ef | grep -v "grep" | grep "unbound"
    reload_watch
}

watch_mosdns() {
    if [ ! -f /data/force_nocn_list.txt ]; then
        cp /usr/sbin/force_nocn_list.txt /data/
    fi
    if [ ! -f /data/force_cn_list.txt ]; then
        cp /usr/sbin/force_cn_list.txt /data/
    fi
    if [ ! -f /data/Country-only-cn-private.mmdb ]; then
        cp /usr/sbin/Country-only-cn-private.mmdb /data/Country-only-cn-private.mmdb
    fi
    file_list="/data/Country-only-cn-private.mmdb /data/force_cn_list.txt /data/force_nocn_list.txt"
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
    inotifywait -e modify,delete $file_list && reload_mosdns
}

watch_unbound() {
    if [ ! -f /etc/unbound/named.cache ]; then
        touch /etc/unbound/named.cache
    fi
    inotifywait -e modify,delete /etc/unbound/named.cache && reload_unbound
}
echo "Watchlist Run!"
if [ "$CNAUTO" != "no" ]; then
    watch_mosdns &
fi
watch_unbound &
