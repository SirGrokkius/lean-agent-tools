#!/usr/bin/env bash
# extra hardening tests added during review (path matching, secrets, state safety)
cd "$(dirname "$0")"; . ./lib.sh; B=$(cd "${TOOLS:-../bin}" && pwd); W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
python3 - "$W/j.json" <<'X'
import json,sys
d={"data":{"user":{"id":1,"name":"a","token":"abc123xyz","bio":"x"*500},"items":[{"id":i,"name":f"n{i}","meta":{"a":None}} for i in range(20)]},"usage":{"total_tokens":123},"debug":{"trace":"t"}}
json.dump(d,open(sys.argv[1],"w"))
X
ok "jsonslim keep items[].name" "$B/jsonslim $W/j.json -k 'data.items[].name' --compact 2>/dev/null | grep -q '\"name\":\"n0\"' && ! $B/jsonslim $W/j.json -k 'data.items[].name' --compact 2>/dev/null | grep -q '\"id\"'"
ok "jsonslim wildcard data.*.id" "[ \"\$($B/jsonslim $W/j.json -k 'data.*.id' --compact 2>/dev/null)\" = '{\"data\":{\"user\":{\"id\":1}}}' ]"
ok "jsonslim ** drop" "! $B/jsonslim $W/j.json -x '**.meta' 2>/dev/null | grep -q meta"
ok "jsonslim token redacted" "$B/jsonslim $W/j.json 2>/dev/null | grep -q '\"token\": \"\[REDACTED\]\"'"
ok "jsonslim numeric token counters kept" "$B/jsonslim $W/j.json 2>/dev/null | grep -q '\"total_tokens\": 123'"
ok "jsonslim schema hides secret example" "! $B/jsonslim $W/j.json --schema 2>/dev/null | grep -q abc123xyz"
ok "jsonslim refuses loopback url" "! $B/jsonslim http://127.0.0.1:9/x 2>/dev/null"
ok "jsonslim refuses file url" "! $B/jsonslim file:///etc/passwd 2>/dev/null"
export WATCHDIFF_DIR=$W/wd HOME=$W
ok "watchdiff rejects path-like --name" "$B/watchdiff $W/j.json --name ../../x --reset 2>/dev/null; [ \$? -eq 2 ]"
printf '<html><body><nav>menu</nav><p>Price: 10</p><p>Stock: 5</p></body></html>' > $W/p.html
$B/watchdiff $W/p.html >/dev/null 2>&1; sed -i 's/Price: 10/Price: 12/' $W/p.html
ok "watchdiff html block-level diff" "$B/watchdiff $W/p.html | grep -qx '+ Price: 12'"
ok "watchdiff state mode 600" "[ \"\$(stat -c %a $W/wd/*.json)\" = 600 ]"
ok "watchdiff refuses loopback" "$B/watchdiff http://127.0.0.1:9/ 2>/dev/null; [ \$? -eq 2 ]"
done_
