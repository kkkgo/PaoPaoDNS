#!/bin/sh
# ulimit
start_dns() {
    killname=$1
    if [ "$killname" = "unbound" ]; then
        unbound -c /tmp/unbound_raw.conf >/dev/null 2>&1 &
        if [ -f /tmp/unbound_forward.conf ]; then
            unbound -c /tmp/unbound_forward.conf >/dev/null 2>&1 &
        fi
    fi
    if [ "$killname" = "mosdns" ]; then
        mosdns start -d /tmp -c mosdns.yaml
    fi
}
file_update() {
    date +"%Y-%m-%d %H:%M:%S %Z"
    oldsum=$($hashcmd $update_file | grep -Eo "$update_reg")
    newsum=$(curl -s $(if [ -n "$SOCKS5ON" ]; then echo "--socks5-hostname "$SOCKS5""; fi) "$newsum_url" | grep -Eo "$update_reg" | head -1)
    if echo "$newsum" | grep -qvE "$update_reg"; then
        echo "Network error."
        return 1
    fi
    if [ "$newsum" = "$oldsum" ]; then
        echo "$update_file" "Same hash, skip update."
        return 2
    fi
    echo $update_file "diff sha256sum, update..."
    echo newsum:"$newsum"
    echo oldsum:"$oldsum"
    curl $(if [ -n "$SOCKS5ON" ]; then echo "--socks5-hostname "$SOCKS5""; fi) "$down_url" -o $update_file_down
    downsum=$($hashcmd "$update_file_down" | grep -Eo "$update_reg")
    if [ "$newsum" = "$downsum" ]; then
        echo "$update_file_down" "Download OK."
        rm "$update_file"
        mv "$update_file_down" "$update_file"
        echo "$update_file" "Update OK."
        killall "$killname"
        start_dns "$killname"
        sleep 1
        ps -ef | grep -v "grep" | grep "$killname"
        return 0
    else
        echo "$update_file_down" "Download error."
        rm "$update_file_down"
    fi
    return 1
}

file_update_try() {
    if [ -n "$SOCKS5" ]; then
        SOCKS5ON="yes"
    fi
    file_update
    if [ "$?" = "1" ]; then
        SOCKS5ON=""
        file_update
        return $?
    else
        return 0
    fi
}

sleep 3
update-ca-certificates
apk update
apk add --upgrade curl ca-certificates

update_file="/etc/unbound/named.cache"
update_file_down="/tmp/named.cache"
update_reg="[0-9A-Za-z]{32}"
hashcmd="md5sum"
newsum_url=https://www.internic.net/domain/named.cache.md5
down_url=https://www.internic.net/domain/named.cache
killname="unbound"
file_update_try
redis-cli info | grep used_memory_human

if [ "$CNAUTO" != "no" ]; then
    update_file="/data/Country-only-cn-private.mmdb"
    update_file_down="/tmp/Country-only-cn-private.mmdb"
    update_reg="[0-9A-Za-z]{64}"
    hashcmd="sha256sum"
    newsum_url=https://raw.githubusercontent.com/Loyalsoldier/geoip/release/Country-only-cn-private.mmdb.sha256sum
    down_url=https://raw.githubusercontent.com/Loyalsoldier/geoip/release/Country-only-cn-private.mmdb
    killname="mosdns"
    file_update_try
    if [ "$?" = "1" ]; then
        newsum_url=https://cdn.jsdelivr.net/gh/Loyalsoldier/geoip@release/Country-only-cn-private.mmdb.sha256sum
        down_url=https://cdn.jsdelivr.net/gh/Loyalsoldier/geoip@release/Country-only-cn-private.mmdb
        file_update_try
    fi
fi
