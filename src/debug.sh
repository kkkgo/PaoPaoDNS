#!/bin/sh
echo =====PaoPaoDNS docker debug=====
echo images build time : {bulidtime}
IPREX4='([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])'
cat /tmp/env.conf
ps -ef
grep whoami /data/force_cn_list.txt
echo CNIP URL test:
curl -sk4 http://test.ipw.cn | grep -Eo "$IPREX4" | tail -1
curl -sk4 http://ipsu.03k.org | grep -Eo "$IPREX4" | tail -1
echo ------------------
echo NOCN IP URL test:
curl -sk4 https://www.cloudflare.com/cdn-cgi/trace | grep -Eo "$IPREX4" | tail -1
curl -sk4 https://1.0.0.1/cdn-cgi/trace | grep -Eo "$IPREX4" | tail -1
curl -sk4 https://1.1.1.1/cdn-cgi/trace | grep -Eo "$IPREX4" | tail -1
curl -sk4 http://checkip.synology.com/ | grep -Eo "$IPREX4" | tail -1
curl -sk4 https://v4.ident.me/ | grep -Eo "$IPREX4" | tail -1
echo ------------------
echo IP INFO:
curl -d "" http://ip.03k.org
echo
echo ------------------
echo The DNS hijacking test, you will see timed out message.
nslookup www.qq.com 6.7.8.9
echo ----------whoami test----------
echo ------------------
echo mosdns whoami dig:
dig +short whoami.ds.akahelp.net @127.0.0.1 txt -p53
echo ------------------
echo local unbound whoami dig:
dig +short whoami.ds.akahelp.net @127.0.0.1 txt -p5301
echo ------------------
echo dnscrypt raw whoami dig:
dig +short whoami.ds.akahelp.net @127.0.0.1 txt -p5302
echo ------------------
echo dnscrypt with socks5 whoami dig:
dig +short whoami.ds.akahelp.net @127.0.0.1 txt -p5303
echo ------------------
echo dnscrypt unbound whoami dig:
dig +short whoami.ds.akahelp.net @127.0.0.1 txt -p5304
echo ------------------
echo ----------CN test----------
echo mosdns CN dig:
dig +short www.taobao.com @127.0.0.1 -p53
echo ------------------
echo local unbound CN dig:
dig +short www.taobao.com @127.0.0.1 -p5301
echo ------------------
echo dnscrypt raw CN dig:
dig +short www.taobao.com @127.0.0.1 -p5302
echo ------------------
echo dnscrypt with socks5 CN dig:
dig +short www.taobao.com @127.0.0.1 -p5303
echo ------------------
echo dnscrypt unbound CN dig:
dig +short www.taobao.com @127.0.0.1 -p5304
echo ------------------
echo ----------NOCN test----------
echo mosdns NOCN dig:
dig +short www.youtube.com @127.0.0.1 -p53
echo ------------------
echo local unbound NOCN dig:
dig +short www.youtube.com @127.0.0.1 -p5301
echo ------------------
echo dnscrypt raw NOCN dig:
dig +short www.youtube.com @127.0.0.1 -p5302
echo ------------------
echo dnscrypt with socks5 NOCN dig:
dig +short www.youtube.com @127.0.0.1 -p5303
echo ------------------
echo dnscrypt unbound NOCN dig:
dig +short www.youtube.com @127.0.0.1 -p5304
echo ------------------
echo ----------IPV6 test----------
echo dual CN domain IPV6:
dig +short www.taobao.com @127.0.0.1 aaaa -p53
dig +short www.qq.com @127.0.0.1 aaaa -p53
echo dual NOCN domain IPV6:
dig +short www.youtube.com @127.0.0.1 aaaa -p53
echo IPV6 only domain :
dig +short ip6.03k.org @127.0.0.1 aaaa -p53
dig +short checkipv6.synology.com @127.0.0.1 aaaa -p53
