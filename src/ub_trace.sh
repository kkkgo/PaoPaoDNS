#!/bin/sh
echo images build time : {bulidtime}
echo "-> test start \`$(date +%s)\`"
echo "\`\`\`rust"
echo "[TEST]Run unbound trace test..."
echo kill unbound and reload to debug mode...
unbound_id=$(ps | grep -v "grep" | grep "unbound_raw" | grep -Eo "[0-9]+" | head -1)
kill "$unbound_id"
sed -i "s/verbosity:.*/verbosity: 4/g" /tmp/unbound_raw.conf
unbound -c /tmp/unbound_raw.conf -p -d -v &
dig www.jd.com @127.0.0.1 -p5301
dig www.taobao.com @127.0.0.1 -p5301
echo unbound trace finish.
echo "\`\`\`"
echo "-> test end \`$(date +%s)\`"
echo
unbound_id=$(ps | grep -v "grep" | grep "unbound_raw" | grep -Eo "[0-9]+" | head -1)
kill "$unbound_id"
sed -i "s/verbosity:.*/verbosity: 0/g" /tmp/unbound_raw.conf
unbound -c /tmp/unbound_raw.conf -p