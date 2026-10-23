#!/usr/bin/env bash
cd "$(dirname "$0")"; . ./lib.sh; T=${TOOLS:-../bin}/tokcount; W=$(mktemp -d); trap 'rm -rf $W' EXIT
python3 -c "print('word ' * 800)" > $W/a.md          # 4000 chars prose
python3 -c "print('x = f(a, b); ' * 300)" > $W/b.py  # code
python3 -c "import json; print(json.dumps([{'id': i, 'name': 'n%d' % i} for i in range(300)]))" > $W/c.json
for i in $(seq 1 300); do echo "same log line"; done > $W/d.log
printf 'bin\x00ary' > $W/e.bin; mkdir -p $W/node_modules; python3 -c "print('z'*99999)" > $W/node_modules/big.js
ok "--help" "$T --help"
ok "prose estimate ~ chars/3.4" "$T $W/a.md --json | python3 -c 'import json,sys; t=json.load(sys.stdin)[\"total_tokens\"]; assert 1100<t<1300, t'"
ok "binary skipped" "! $T $W | grep -q e.bin"
ok "node_modules skipped" "! $T $W | grep -q node_modules"
ok "stdin" "echo hello world | $T - | grep -q TOTAL"
ok "under budget rc0" "$T $W/a.md --budget 999999"
ok "over budget rc1 + message" "O=\$($T $W --budget 100); [ \$? -eq 1 ] && grep -q 'OVER BUDGET' <<<\"\$O\""
ok "suggests jsonslim for json" "$T $W --budget 100 | grep -q jsonslim"
ok "flags duplicate-line log" "$T $W --budget 100 | grep -q 'duplicate lines'"
ok "json mode valid + over_by" "$T $W --budget 100 --json | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d[\"over_by\"]>0'"
ok "--ext filter" "$T $W --ext py | grep -q b.py && ! $T $W --ext py | grep -q a.md"
ok "unknown arg rc2" "[ \$($T --zzz >/dev/null 2>&1; echo \$?) -eq 2 ]"
done_
