#!/bin/sh
comp_trackerslist() {
    mkdir -p /tmp/trackerslist
    cp /usr/sbin/trackerslist.txt.xz /tmp/trackerslist/
    cd /tmp/trackerslist/ || exit
    xz -df trackerslist.txt.xz
    if [ -f /data/trackerslist.txt ]; then
        echo "" >>/tmp/trackerslist/trackerslist.txt
        cat /data/trackerslist.txt >>/tmp/trackerslist/trackerslist.txt
        update_file_wait="/data/trackerslist.txt"
        wait_apply
    fi
    sort -u /tmp/trackerslist/trackerslist.txt | grep "." >/tmp/trackerslist/trackerslist.txt.gen
    cat /tmp/trackerslist/trackerslist.txt.gen >/data/trackerslist.txt
    rm -rf /tmp/trackerslist/
    return 0
}

ex_mmdb() {
    mkdir -p /tmp/mmdb
    cp /usr/sbin/Country-only-cn-private.mmdb.xz /tmp/mmdb/
    cd /tmp/mmdb/ || exit
    xz -df Country-only-cn-private.mmdb.xz
    cat /tmp/mmdb/Country-only-cn-private.mmdb >/data/Country-only-cn-private.mmdb
    rm -rf /tmp/mmdb/
    return 0
}

wait_apply() {
    while ! ps -ef | grep inotifywait | grep -q $update_file_wait; do
        sleep 1
        echo "$update_file_wait"": Waiting to apply the update..."
    done
}

if [ "$1" = "comp_trackerslist" ]; then
    comp_trackerslist
    exit
fi

if [ "$1" = "ex_mmdb" ]; then
    ex_mmdb
    exit
fi

sleep $((1 + $RANDOM % 300))
file_update() {
    date +"%Y-%m-%d %H:%M:%S %Z"
    touch $update_file
    oldsum=$($hashcmd $update_file | grep -Eo "$update_reg")
    newsum=$(curl -4L --connect-timeout 10 -s $(if [ -n "$SOCKS5ON" ]; then echo "--socks5-hostname "$SOCKS5""; fi) "$newsum_url" | grep -Eo "$update_reg" | head -1)
    if echo "$newsum" | grep -qvE "$update_reg"; then
        echo "Network error: ""$SOCKS5ON" "$newsum_url"
        return 1
    fi
    if [ "$newsum" = "$oldsum" ]; then
        echo "$update_file" "Same hash, skip update."
        return 2
    fi
    echo $update_file "diff sha256sum, update..."
    echo newsum:"$newsum"
    echo oldsum:"$oldsum"
    curl -4L --connect-timeout 10 $(if [ -n "$SOCKS5ON" ]; then echo "--socks5-hostname "$SOCKS5""; fi) "$down_url" -o $update_file_down
    downsum=$($hashcmd "$update_file_down" | grep -Eo "$update_reg")
    if [ "$newsum" = "$downsum" ]; then
        echo "$update_file_down" "Download OK."
        wait_apply
        echo "ok" >"/tmp/""$update_flag"
        cat "$update_file_down" >"$update_file"
        rm "$update_file_down"
        echo "$update_file" "Update OK."
        sleep 5
        return 0
    else
        echo "$update_file_down" "Download error."
        rm "$update_file_down"
    fi
    return 1
}

file_update_try() {
    if [ "$1" = "failed" ]; then
        echo "Download failed. Attempting to change the download link..."
        echo $newsum_url
    fi
    if echo "$SOCKS5" | grep -Eoq ":[0-9]+"; then
        SOCKS5ON="$SOCKS5"
        SOCKS5=$(echo "$SOCKS5" | sed 's/"//g')
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

update-ca-certificates
apk update
apk add --upgrade curl ca-certificates

update_file="/etc/unbound/named.cache"
update_file_down="/tmp/named.cache"
update_flag="named.flag"
update_file_wait=$update_file
update_reg="[0-9A-Za-z]{32}"
hashcmd="md5sum"
newsum_url=https://www.internic.net/domain/named.cache.md5
down_url=https://www.internic.net/domain/named.cache
file_update_try
redis-cli -s /tmp/redis.sock info | grep used_memory_human

if [ "$CNAUTO" != "no" ]; then
    update_file="/usr/sbin/Country-only-cn-private.mmdb.xz"
    update_file_down="/tmp/Country-only-cn-private.mmdb"
    update_flag="Country-only-cn-private.flag"
    update_file_wait=$update_file
    update_reg="[0-9A-Za-z]{64}"
    hashcmd="sha256sum"
    newsum_url=https://raw.githubusercontent.com/kkkgo/Country-only-cn-private.mmdb/main/Country-only-cn-private.mmdb.xz.sha256sum
    down_url=https://raw.githubusercontent.com/kkkgo/Country-only-cn-private.mmdb/main/Country-only-cn-private.mmdb.xz
    file_update_try
    if [ "$?" = "1" ]; then
        newsum_url=https://cdn.jsdelivr.net/gh/kkkgo/Country-only-cn-private.mmdb/Country-only-cn-private.mmdb.xz.sha256sum
        down_url=https://cdn.jsdelivr.net/gh/kkkgo/Country-only-cn-private.mmdb/Country-only-cn-private.mmdb.xz
        file_update_try failed
        if [ "$?" = "1" ]; then
            newsum_url=https://cdn.staticaly.com/gh/kkkgo/Country-only-cn-private.mmdb/main/Country-only-cn-private.mmdb.xz.sha256sum
            down_url=https://cdn.staticaly.com/gh/kkkgo/Country-only-cn-private.mmdb/main/Country-only-cn-private.mmdb.xz
            file_update_try failed
        fi
    fi
    if [ -f /tmp/Country-only-cn-private.flag ]; then
        update_file_wait="/data/Country-only-cn-private.mmdb"
        wait_apply
        ex_mmdb
        rm /tmp/Country-only-cn-private.flag
    fi
fi

# Update trackerlist data
if [ "$CNAUTO" != "no" ]; then
    if [ "$CN_TRACKER" = "yes" ]; then
        update_file="/usr/sbin/trackerslist.txt.xz"
        update_file_down="/tmp/trackerslist.txt.xz.download"
        update_flag="trackerslist.flag"
        update_file_wait="/data/trackerslist.txt"
        update_reg="[0-9A-Za-z]{64}"
        hashcmd="sha256sum"
        newsum_url=https://raw.githubusercontent.com/kkkgo/all-tracker-list/main/trackerslist.txt.xz.sha256sum
        down_url=https://raw.githubusercontent.com/kkkgo/all-tracker-list/main/trackerslist.txt.xz
        file_update_try
        if [ "$?" = "1" ]; then
            newsum_url=https://cdn.jsdelivr.net/gh/kkkgo/all-tracker-list/trackerslist.txt.xz.sha256sum
            down_url=https://cdn.jsdelivr.net/gh/kkkgo/all-tracker-list/trackerslist.txt.xz
            file_update_try failed
            if [ "$?" = "1" ]; then
                newsum_url=https://cdn.staticaly.com/gh/kkkgo/all-tracker-list/main/trackerslist.txt.xz.sha256sum
                down_url=https://cdn.staticaly.com/gh/kkkgo/all-tracker-list/main/trackerslist.txt.xz
                file_update_try failed
            fi
        fi
        if [ -f /tmp/trackerslist.flag ]; then
            comp_trackerslist
            rm /tmp/trackerslist.flag
        fi
    fi
fi

# Update global mark data
if [ "$CNAUTO" != "no" ]; then
    if [ "$USE_MARK_DATA" = "yes" ]; then
        update_file="/data/global_mark.dat"
        update_file_down="/tmp/global_mark.dat.download"
        update_flag="global_mark.flag"
        update_file_wait=$update_file
        update_reg="[0-9A-Za-z]{64}"
        hashcmd="sha256sum"
        newsum_url=https://raw.githubusercontent.com/kkkgo/PaoPao-Pref/main/global_mark.dat.sha256sum
        down_url=https://raw.githubusercontent.com/kkkgo/PaoPao-Pref/main/global_mark.dat
        file_update_try
        if [ "$?" = "1" ]; then
            newsum_url=https://cdn.jsdelivr.net/gh/kkkgo/PaoPao-Pref/global_mark.dat.sha256sum
            down_url=https://cdn.jsdelivr.net/gh/kkkgo/PaoPao-Pref/global_mark.dat
            file_update_try failed
            if [ "$?" = "1" ]; then
                newsum_url=https://cdn.staticaly.com/gh/kkkgo/PaoPao-Pref/main/global_mark.dat.sha256sum
                down_url=https://cdn.staticaly.com/gh/kkkgo/PaoPao-Pref/main/global_mark.dat
                file_update_try failed
            fi
        fi
    fi
fi
