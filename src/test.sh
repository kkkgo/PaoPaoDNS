#!/bin/sh
blank() {
    echo "*********************************************************************************"
    echo
}
export no_proxy=""
export http_proxy=""
ping whoami.03k.org -c1 -W 1 -w 1 -i 1 -4 >/dev/null
IPREX4='([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])'
v4check() {
    if echo "$1" | grep -v "timed out" | grep -v "127.0.0.1" | grep -qE "$IPREX4"; then
        echo y
    else
        echo "$2" failed:"$1"
        exit
    fi
}
if ps -ef | grep -v grep | grep -q mosdns.yaml; then
    blank
    echo "-> test start \`$(date +%s)\`"
    echo "\`\`\`rust"
    if [ -w /data ]; then
        t1=y
    else
        t1="[ERROR]DATA_not_writeable"
    fi

    if [ -r /data ]; then
        t2=y
    else
        t2="[ERROR]DATA_not_readable"
    fi
    if dig +short whether.114dns.com @114.114.114.114 | grep -q "127.0.0.1"; then
        t3="[DNS hijack]"
    else
        t3=y
    fi
    if dig +short whoami.ds.akahelp.net @9.8.7.6 txt -p53 +retry=0 +timeout=1 | grep -q timed; then
        t4=y
    else
        t4="[DNS hijack]"
    fi
    t5t=$(dig www.taobao.com @127.0.0.1 -p53 A +short)
    t5=$(v4check "$t5t" CN-53)
    t6t=$(dig www.taobao.com @127.0.0.1 -p5301 A +short)
    t6=$(v4check "$t6t" CN-5301)
    t7t=$(dig www.taobao.com @127.0.0.1 -p5302 A +short)
    t7=$(v4check "$t7t" CN-5302)
    t8t=$(dig www.taobao.com @127.0.0.1 -p5304 A +short)
    t8=$(v4check "$t8t" CN-5304)
    t9t=$(dig www.google.com @127.0.0.1 -p53 A +short)
    t9=$(v4check "$t9t" NOCN-53)
    t10t=$(dig www.google.com @127.0.0.1 -p5301 A +short)
    t10=$(v4check "$t10t" NOCN-5301)
    t11t=$(dig www.google.com @127.0.0.1 -p5302 A +short)
    t11=$(v4check "$t11t" NOCN-5302)
    t12t=$(dig www.google.com @127.0.0.1 -p5304 A +short)
    t12=$(v4check "$t12t" NOCN-5304)

    result=$t1$t2$t3$t4$t5$t6$t7$t8$t9$t10$t11$t12
    if echo $result | grep -q "yyyyyyyyyyyy"; then
        echo "[INFO]" ALL TEST PASS.
    else
            echo $result
        echo "[INFO]" TEST FAIL.
    fi
    echo "\`\`\`"
    echo "-> test end \`$(date +%s)\`"
    echo
else
    echo "DNS NOT READY."
fi
blank
