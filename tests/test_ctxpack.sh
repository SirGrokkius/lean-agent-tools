#!/usr/bin/env bash
cd "$(dirname "$0")"; . ./lib.sh; T=${TOOLS:-../bin}/ctxpack; W=$(mktemp -d); trap 'rm -rf $W' EXIT
mkdir -p $W/src
printf 'def tier1_cap():\n    """enforce the daily cap"""\n    return 15\n\ndef other():\n    pass\n' > $W/src/limits.py
for i in $(seq 1 30); do echo "filler line $i about nothing" ; done > $W/src/noise.txt
echo "tier1 mention once" >> $W/src/noise.txt
echo "API_KEY=sk-abcdefghijklmnopqrstuvwxyz123 tier1 cap" > $W/src/.env
echo "tier1 cap daily in backup" > $W/src/limits.py.bak
echo "tier1 daily cap leaked token=abcdef123456 here" > $W/src/notes.md
ok "--help" "$T --help"
ok "list ranks limits.py first" "$T 'where is the tier1 daily cap' $W --list | sed -n 2p | grep -q limits.py"
O=$($T 'where is the tier1 daily cap' $W --cap 500)
ok "snippet has path:line" "grep -q 'limits.py:1-' <<<\"\$O\""
ok ".env never read" "! grep -q 'sk-abc' <<<\"\$O\" && ! grep -q '\.env' <<<\"\$O\""
ok ".bak skipped" "! grep -q 'limits.py.bak' <<<\"\$O\""
ok "secret value redacted" "grep -q REDACTED <<<\"\$O\" && ! grep -q abcdef123456 <<<\"\$O\""
ok "footer with token estimate" "grep -q '# ctxpack:' <<<\"\$O\""
python3 -c "
for i in range(400): print(f'tier1 cap line {i} ' + 'y'*60)" > $W/src/big.txt
ok "respects cap" "[ \$($T 'tier1 cap' $W --cap 300 | wc -c) -lt 1700 ]"
ok "no hits rc1" "[ \$($T 'zzqqxx' $W >/dev/null 2>&1; echo \$?) -eq 1 ]"
ok "missing dir rc2" "[ \$($T 'x' /nonexistent >/dev/null 2>&1; echo \$?) -eq 2 ]"
ok "--terms override" "$T --terms other $W --list | grep -q limits.py"
ok "query with shell metachar is literal" "$T '\$(touch $W/pwned) ; rm -rf' $W >/dev/null 2>&1; [ ! -e $W/pwned ]"
done_
