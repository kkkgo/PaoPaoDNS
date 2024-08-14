#!/bin/sh
load_mark_data() {
    echo load_mark_data
    if [ -f /data/global_mark.dat ]; then
        datfile="/data/global_mark.dat"
        datsize=$(wc -c <"$datfile")
        if [ "$datsize" -gt "10000" ]; then
            echo "dat size pass."
            mkdir -p /tmp/global_mark
            sp_dat="/tmp/global_mark/global_mark.dat.xz"
            sp_sha="/tmp/global_mark/global_mark.dat.sha"
            /usr/sbin/mosdns eat cut
            sp_dat_hash=$(sha512sum "$sp_dat" | grep -Eo "[0-9A-Za-z]{128}" | head -1)
            sp_sha_hash=$(grep -Eo "[0-9A-Za-z]{128}" $sp_sha | head -1)
            if [ "$sp_dat_hash" = "$sp_sha_hash" ]; then
                echo global_mark hash: OK.
                cd /tmp/global_mark || exit
                xz -df $sp_dat
                if [ -f /tmp/global_mark/global_mark.dat ]; then
                    /usr/sbin/mosdns eat spilt
                fi
                cd - || exit
            else
                echo global_mark hash: Bad.
            fi
            rm -rf /tmp/global_mark/
        else
            echo "bad dat size."
        fi
    fi
    if [ ! -f /tmp/global_mark.dat ]; then
        touch /tmp/global_mark.dat
    fi
    if [ -f /data/custom_cn_mark.txt ]; then
        sed 's/\r$//' /data/custom_cn_mark.txt | grep -E "^[a-zA-Z0-9]" >/tmp/custom_cn_mark.txt
    else
        touch /data/custom_cn_mark.txt
        touch /tmp/custom_cn_mark.txt
    fi
}

if [ "$1" = "load_mark_data" ]; then
    load_mark_data
    exit
fi

load_ttl_rules() {
    touch /tmp/force_ttl_rules.txt
    touch /tmp/force_ttl_rules.toml
    touch /tmp/force_ttl_rules_cloaking.toml
    if [ ! -f /data/force_ttl_rules.txt ]; then
        touch /data/force_ttl_rules.txt
        return 1
    fi
    force_ttl_rules_new=$(md5sum /data/force_ttl_rules.txt | grep -Eo "[a-z0-9]{32}" | head -1)
    if [ -f /tmp/force_ttl_rules.txt.sum ]; then
        force_ttl_rules_old=$(md5sum /tmp/force_ttl_rules.txt.sum | grep -Eo "[a-z0-9]{32}" | head -1)
        if [ "$force_ttl_rules_new" = "$force_ttl_rules_old" ]; then
            return 1
        fi
    else
        echo "$force_ttl_rules_new" >/tmp/force_ttl_rules.txt.sum
    fi
    /usr/sbin/mosdns eat ttl_rules
    return 0
}

if [ "$1" = "load_ttl_rules" ]; then
    load_ttl_rules
    exit
fi

load_trackerslist() {
    if [ ! -f /data/trackerslist.txt ]; then
        /usr/sbin/data_update.sh comp_trackerslist
    fi
    /usr/sbin/mosdns eat trackerslist
    echo "Apply trackerslist..."
}

if [ "$1" = "load_trackerslist" ]; then
    load_trackerslist
    exit
fi

gen_hash() {
    if [ -f "$1" ]; then
        md5sum "$1" | cut -d" " -f1
    else
        echo -n "empty_file"
    fi
}

reload_dns() {
    force_reload_flag=$1
    if [ "$force_reload_flag" = "force" ]; then
        export reload_mosdns=1
    else
        export reload_mosdns=0
    fi
    if [ "$CNAUTO" != "no" ]; then
        export reload_mosdns=0
        if [ -f /data/force_recurse_list.txt ]; then
            sed 's/\r$//' /data/force_recurse_list.txt | grep -E "^[a-zA-Z0-9]" >/tmp/force_recurse_list.txt
            if [ -f /data/force_cn_list.txt ]; then
                sed 's/\r$//' /data/force_cn_list.txt | grep -E "^[a-zA-Z0-9]" >>/tmp/force_recurse_list.txt
            fi
            sort -u /tmp/force_recurse_list.txt -o /tmp/force_recurse_list.txt
        fi
        if [ -f /data/force_dnscrypt_list.txt ]; then
            sed 's/\r$//' /data/force_dnscrypt_list.txt | grep -E "^[a-zA-Z0-9]" >/tmp/force_dnscrypt_list.txt
            if [ -f /data/force_nocn_list.txt ]; then
                echo "" >>/tmp/force_dnscrypt_list.txt
                sed 's/\r$//' /data/force_nocn_list.txt | grep -E "^[a-zA-Z0-9]" >>/tmp/force_dnscrypt_list.txt
            fi
            sort -u /tmp/force_dnscrypt_list.txt -o /tmp/force_dnscrypt_list.txt
        fi
        if [ -f /data/force_forward_list.txt ]; then
            sed 's/\r$//' /data/force_forward_list.txt | grep -E "^[a-zA-Z0-9]" >/tmp/force_forward_list.txt
        fi
        if [ ! -f /data/Country-only-cn-private.mmdb ]; then
            /usr/sbin/data_update.sh ex_mmdb
        fi
        if [ "$(gen_hash /data/force_recurse_list.txt)" != "$force_recurse_list" ]; then
            export reload_mosdns=1
        fi
        if [ "$(gen_hash /data/force_cn_list.txt)" != "$force_cn_list" ]; then
            export reload_mosdns=1
        fi
        if [ "$(gen_hash /data/force_dnscrypt_list.txt)" != "$force_dnscrypt_list" ]; then
            export reload_mosdns=1
        fi
        if [ "$(gen_hash /data/force_nocn_list.txt)" != "$force_nocn_list" ]; then
            export reload_mosdns=1
        fi
        if [ "$(gen_hash /data/force_forward_list.txt)" != "$force_forward_list" ]; then
            export reload_mosdns=1
        fi
        if [ "$(gen_hash /data/custom_env.ini)" != "$custom_env" ]; then
            export reload_mosdns=1
        fi
        if [ "$CN_TRACKER" = "yes" ]; then
            if [ "$(gen_hash /data/trackerslist.txt)" != "$trackerslist" ]; then
                load_trackerslist
                export reload_mosdns=1
            fi
        fi
        if [ "$USE_MARK_DATA" = "yes" ]; then
            if [ -f /tmp/global_mark.flag ]; then
                if grep -q "ok" /tmp/global_mark.flag; then
                    load_mark_data
                    echo "" >/tmp/global_mark.flag
                    export reload_mosdns=1
                fi
            fi
            if [ "$(gen_hash /data/custom_cn_mark.txt)" != "$custom_cn_mark" ]; then
                sed 's/\r$//' /data/custom_cn_mark.txt | grep -E "^[a-zA-Z0-9]" >/tmp/custom_cn_mark.txt
                export reload_mosdns=1
            fi
        fi
        RULES_TTL=$(echo "$RULES_TTL" | grep -Eo "[0-9]+|head -1")
        if [ -z "$RULES_TTL" ]; then
            RULES_TTL=0
        fi
        if [ "$RULES_TTL" -gt 0 ]; then
            if [ "$(gen_hash /data/force_ttl_rules.txt)" != "$force_ttl_rules" ]; then
                load_ttl_rules
                if [ "$?" = "0" ]; then
                    if ps | grep dnscrypt-proxy | grep -q dnscrypt.toml; then
                        dnscrypt_id=$(ps | grep -v "grep" | grep dnscrypt-proxy | grep dnscrypt.toml | grep -Eo "[0-9]+" | head -1)
                        kill "$dnscrypt_id"
                    fi
                    echo "dnscrypt reload rules..."
                    dnscrypt-proxy -config /data/dnscrypt-resolvers/dnscrypt.toml >/dev/null 2>&1 &
                fi
                export reload_mosdns=1
            fi
        fi
        if [ "$(gen_hash /data/Country-only-cn-private.mmdb)" != "$Country" ]; then
            cat /data/Country-only-cn-private.mmdb >/tmp/Country.mmdb
            export reload_mosdns=1
        fi
        if [ $reload_mosdns = "1" ]; then
            while ps | grep -v grep | grep -q "mosdns.yaml"; do
                mosdns_id=$(ps | grep -v "grep" | grep "mosdns.yaml" | grep -Eo "[0-9]+" | head -1)
                kill "$mosdns_id" 2>/dev/null
            done
            echo "mosdns reload..."
            touch /data/custom_env.ini
            grep -Eo "^[_a-zA-Z0-9]+=\".+\"" /data/custom_env.ini >/tmp/custom_env.ini
            if [ -f "/tmp/custom_env.ini" ]; then
                while IFS= read -r line; do
                    line=$(echo "$line" | sed 's/"//g' | sed "s/'//g")
                    export "$line"
                done <"/tmp/custom_env.ini"
            fi
            /usr/sbin/mosdns start -d /data -c /tmp/mosdns.yaml &
            sleep 1
            ps -ef | grep -v "grep" | grep "mosdns"
        fi
    fi
    if [ "$force_reload_flag" = "force" ]; then
        return
    fi
    if [ "$(gen_hash /etc/unbound/named.cache)" != "$named" ]; then
        while ps | grep -v grep | grep -q unbound_raw; do
            unbound_id=$(ps | grep -v "grep" | grep "unbound_raw" | grep -Eo "[0-9]+" | head -1)
            kill "$unbound_id" 2>/dev/null
        done
        echo "unbound reload..."
        /usr/sbin/unbound -c /tmp/unbound_raw.conf >/dev/null 2>&1 &
        sleep 1
        ps | grep -v grep | grep unbound_raw
    fi
}
if [ "$1" = "reload_dns" ]; then
    reload_dns force
    exit
fi
while true; do
    file_list="/etc/unbound/named.cache"
    if [ "$CNAUTO" != "no" ]; then
        if [ ! -f /data/force_dnscrypt_list.txt ]; then
            cp /usr/sbin/force_dnscrypt_list.txt /data/
        fi
        if [ ! -f /data/force_recurse_list.txt ]; then
            cp /usr/sbin/force_recurse_list.txt /data/
        fi
        if [ ! -f /data/Country-only-cn-private.mmdb ]; then
            /usr/sbin/data_update.sh ex_mmdb
        fi
        file_list=$file_list" /data/Country-only-cn-private.mmdb /data/force_recurse_list.txt /data/force_dnscrypt_list.txt /data/custom_env.ini"
        if [ -f /data/force_cn_list.txt ]; then
            file_list=$file_list" /data/force_cn_list.txt"
        fi
        if [ -f /data/force_nocn_list.txt ]; then
            file_list=$file_list" /data/force_nocn_list.txt"
        fi
        if [ "$USE_MARK_DATA" = "yes" ]; then
            if [ ! -f /data/global_mark.dat ]; then
                if [ -f /usr/sbin/global_mark.dat ]; then
                    cp /usr/sbin/global_mark.dat /data/
                else
                    touch /data/global_mark.dat
                fi
            fi
            if [ ! -f /data/custom_cn_mark.txt ]; then
                touch /data/custom_cn_mark.txt
            fi
            file_list=$file_list" /data/global_mark.dat /data/custom_cn_mark.txt"
        fi
        if [ "$CN_TRACKER" = "yes" ]; then
            if [ ! -f /data/trackerslist.txt ]; then
                /usr/sbin/data_update.sh comp_trackerslist
            fi
            file_list=$file_list" /data/trackerslist.txt"
        fi
        if echo "$CUSTOM_FORWARD" | grep -Eoq ":[0-9]+"; then
            file_list=$file_list" /data/force_forward_list.txt"
            if [ ! -f /data/force_forward_list.txt ]; then
                cp /usr/sbin/force_forward_list.txt /data/
            fi
        fi
        RULES_TTL=$(echo "$RULES_TTL" | grep -Eo "[0-9]+|head -1")
        if [ -z "$RULES_TTL" ]; then
            RULES_TTL=0
        fi
        if [ "$RULES_TTL" -gt 0 ]; then
            file_list=$file_list" /data/force_ttl_rules.txt"
            if [ ! -f /data/force_ttl_rules.txt ]; then
                touch /data/force_ttl_rules.txt
            fi
        fi
        force_dnscrypt_list=$(gen_hash /data/force_dnscrypt_list.txt)
        export force_dnscrypt_list
        force_nocn_list=$(gen_hash /data/force_nocn_list.txt)
        export force_nocn_list
        force_recurse_list=$(gen_hash /data/force_recurse_list.txt)
        export force_recurse_list
        force_cn_list=$(gen_hash /data/force_cn_list.txt)
        export force_cn_list
        force_forward_list=$(gen_hash /data/force_forward_list.txt)
        export force_forward_list
        force_ttl_rules=$(gen_hash /data/force_ttl_rules.txt)
        export force_ttl_rules
        trackerslist=$(gen_hash /data/trackerslist.txt)
        export trackerslist
        custom_cn_mark=$(gen_hash /data/custom_cn_mark.txt)
        export custom_cn_mark
        Country=$(gen_hash /data/Country-only-cn-private.mmdb)
        export Country
        custom_env=$(gen_hash /data/custom_env.ini)
        export custom_env
    fi
    named=$(gen_hash /etc/unbound/named.cache)
    export named
    inotifywait -e modify,delete $file_list && sleep 1 && reload_dns check
done
