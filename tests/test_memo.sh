#!/usr/bin/env bash
cd "$(dirname "$0")"; . ./lib.sh; T=${TOOLS:-../bin}/memo; W=$(mktemp -d); trap 'rm -rf $W' EXIT
export MEMO_DIR=$W/cache
echo one > $W/in.txt
ok "--help" "$T --help"
ok "first run prints output" "$T -- cat $W/in.txt | grep -q one"
ok "second run is a hit" "$T -- cat $W/in.txt 2>&1 | grep -q 'memo hit'"
echo two > $W/in.txt; touch -d '+2 sec' $W/in.txt
ok "input change invalidates" "$T -- cat $W/in.txt 2>&1 | grep -q two && ! $T -- cat $W/in.txt 2>&1 | grep -q one"
ok "--dep file invalidates" "$T --dep $W/in.txt -- echo x >/dev/null; echo three > $W/in.txt; touch -d '+4 sec' $W/in.txt; ! $T --dep $W/in.txt -- echo x 2>&1 | grep -q 'memo hit'"
ok "failures not cached" "$T -- false; $T -- false 2>&1 | grep -q 'not cached'"
ok "exit code passed through" "[ \$($T -- sh -c 'exit 3' >/dev/null 2>&1; echo \$?) -eq 3 ]"
ok "secret output not cached" "$T -- echo 'api_key=sk-abcdefghijklmnopqrstu' 2>&1 | grep -q 'not cached'"
ok "ttl expiry" "$T --ttl 1 -- echo ttl >/dev/null; sleep 1.2; ! $T --ttl 1 -- echo ttl 2>&1 | grep -q 'memo hit'"
ok "cache files are 600" "[ \$(stat -c %a \$(ls $W/cache/*.json | head -1)) = 600 ]"
ok "no shell: metachar literal" "$T -- echo '\$(touch $W/pwned)' >/dev/null; [ ! -e $W/pwned ]"
touch $W/keep.txt
ok "purge only touches cache dir" "$T --purge >/dev/null; [ -e $W/keep.txt ] && [ -z \"\$(ls $W/cache)\" ]"
ok "stats" "$T --stats | grep -q entries"
ok "unknown arg rc2" "[ \$($T --nope >/dev/null 2>&1; echo \$?) -eq 2 ]"
done_
