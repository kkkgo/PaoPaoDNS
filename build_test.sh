#!/bin/sh
IPREX4='([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])'

# build
docker build -t ppdns .

v4check() {
    if echo "$1" | grep -v "timed out" | grep -v "127.0.0.1" | grep -E "$IPREX4"; then
        echo "$2" pass.
    else
        echo "$2" failed:"$1"
        exit
    fi
}

docker run -d --name test1 \
    -e HTTP_FILE=yes \
    -e USE_HOSTS=yes \
    -e RULES_TTL=1 \
    --add-host host.paopaodns:111.111.111.111 \
    ppdns

sleep 5
docker exec test1 sh -c "echo "force_ttl_rules.paopaodns@@1.2.3.4" > /data/force_ttl_rules.txt"
# base test
t1=$(docker exec test1 dig www.taobao.com @127.0.0.1 -p53 A +short)
v4check "$t1" CN-53
t2=$(docker exec test1 dig www.taobao.com @127.0.0.1 -p5301 A +short)
v4check "$t2" CN-5301
t3=$(docker exec test1 dig www.taobao.com @127.0.0.1 -p5302 A +short)
v4check "$t3" CN-5302
t4=$(docker exec test1 dig www.taobao.com @127.0.0.1 -p5304 A +short)
v4check "$t4" CN-5304
t5=$(docker exec test1 dig www.google.com @127.0.0.1 -p53 A +short)
v4check "$t5" NOCN-53
t6=$(docker exec test1 dig www.google.com @127.0.0.1 -p5301 A +short)
v4check "$t6" NOCN-5301
t7=$(docker exec test1 dig www.google.com @127.0.0.1 -p5302 A +short)
v4check "$t7" NOCN-5302
t8=$(docker exec test1 dig www.google.com @127.0.0.1 -p5304 A +short)
v4check "$t8" NOCN-5304
t9=$(docker exec test1 dig host.paopaodns @127.0.0.1 -p53 A +short)
v4check "$t9" USE_HOSTS
t10=$(docker exec test1 dig force_ttl_rules.paopaodns @127.0.0.1 -p53 A +short)
v4check "$t10" force_ttl_rules
if docker exec test1 mosdns curl http://127.0.0.1:7889 | grep -q Country-only-cn-private.mmdb; then
    echo HTTP_FILE pass.
else
    exit
fi
docker rm -f test1
docker run --name test2 \
    -e USE_MARK_DATA=yes \
    -e AUTO_FORWARD=yes \
    -e CUSTOM_FORWARD=8.8.8.8:53 \
    ppdns &
sleep 15
t11=$(docker exec test2 dig www.youtube.com @127.0.0.1 -p53 A +short)
v4check "$t11" AUTO_FORWARD_OK
docker rm -f test2
docker run --name test3 \
    -e USE_MARK_DATA=yes \
    -e AUTO_FORWARD=yes \
    -e CUSTOM_FORWARD=9.8.7.6:53 \
    ppdns &
sleep 15
t12=$(docker exec test3 dig www.youtube.com @127.0.0.1 -p53 A)
if echo "$t12" | grep REFUSED; then
    echo CUSTOM_FORWARD_BAD pass.
else
    echo CUSTOM_FORWARD_BAD failed:"$t12"
    exit
fi
docker rm -f test3

# pass check
echo ALL TEST PASSED.
touch build_test_ok