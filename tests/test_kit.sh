#!/usr/bin/env bash
# squeeze / aicache / csvq: offline, no network, no AI calls
cd "$(dirname "$0")"; . ./lib.sh; B=$(cd "${TOOLS:-../bin}" && pwd); W=$(mktemp -d); trap 'rm -rf $W' EXIT
export HOME=$W AICACHE_DB=$W/c.db
out=$( { seq 1 250; echo "ERROR boom"; seq 251 500; echo "key sk-abcdefghijklmnopqrstuvwx"; } | $B/squeeze -n 20)
ok "squeeze: <=25 lines" '[ $(printf "%s\n" "$out" | wc -l) -le 25 ]'
ok "squeeze: keeps error line" 'printf "%s" "$out" | grep -q "ERROR boom"'
ok "squeeze: redacts secret" 'printf "%s" "$out" | grep -q REDACTED && ! printf "%s" "$out" | grep -q sk-abcdef'
a=$($B/aicache --ttl 1h -- date +%N); b=$($B/aicache --ttl 1h -- date +%N)
ok "aicache: second call is a cache hit" '[ -n "$a" ] && [ "$a" = "$b" ]'
ok "aicache: --stats" '$B/aicache --stats'
printf 'id,name,score\n1,ada,90\n2,bob,40\n3,cy,75\n' > $W/f.csv
ok "csvq: --count" '$B/csvq $W/f.csv --count | grep -q 3'
ok "csvq: filter score>50" '[ "$($B/csvq $W/f.csv "score>50" --count | grep -o "[0-9]\+" | tail -1)" = 2 ]'
ok "csvq: --schema" '$B/csvq $W/f.csv --schema'
done_
