#!/bin/sh
. /etc/profile
if [ -f /data/custom_env.ini ]; then
    grep -Eo "^[_a-zA-Z0-9]+=\".+\"" /data/custom_env.ini >/tmp/custom_env.ini
    if [ -f "/tmp/custom_env.ini" ]; then
        while IFS= read -r line; do
            line=$(echo "$line" | sed 's/"//g' | sed "s/'//g")
            export "$line"
        done <"/tmp/custom_env.ini"
    fi
fi
/usr/sbin/mosdns version
/usr/sbin/mosdns AddMod
if [ -f /tmp/mosdns_mod.yaml ]; then
    cat /tmp/mosdns_mod.yaml >/tmp/mosdns.yaml
    sed -i '/^#/d' /tmp/mosdns.yaml
fi
/usr/sbin/watch_list.sh reload_dns
