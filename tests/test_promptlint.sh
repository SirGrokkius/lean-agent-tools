#!/usr/bin/env bash
# offline tests for promptlint
cd "$(dirname "$0")"; . ./lib.sh; T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
PL=${TOOLS:-../bin}/promptlint
ok "--help exits 0" "$PL --help | grep -q usage"
ok "unknown arg exits 2" "$PL --bogus </dev/null >/dev/null 2>&1; [ \$? -eq 2 ]"
printf 'Summarize the attached report in five bullet points for the board.\n\nKeep the tone neutral.\n' > $T/clean.md
ok "clean prompt exit 0, 0 findings" "$PL $T/clean.md | grep -q ', 0 findings'"
cat > $T/bloat.md <<'X'
Please make sure to answer in JSON format with keys a and b.
It is very important that you basically keep it short.
Please make sure to answer in JSON format with keys a and b.
Answer in JSON format with the keys a and b, nothing else!
I want you to be concise in order to save time.

Rules paragraph one line one here.
Rules paragraph line two goes here ok.

Rules paragraph one line one here.
Rules paragraph line two goes here ok.
X
O=$($PL $T/bloat.md); echo "$O" >$T/o
ok "dup-line found" "grep -q dup-line $T/o"
ok "dup-para found" "grep -q dup-para $T/o"
ok "filler found" "grep -q 'filler \"please make sure to\" x2' $T/o"
ok "no HIGH -> exit 0" "$PL $T/bloat.md >/dev/null"
printf 'use key sk-abcdefghijklmnopqrstuvwxyz123456 now\napi_key=ZZZsecretvalue99\n' > $T/sec.md
ok "secret -> exit 1" "! $PL $T/sec.md >/dev/null"
ok "secret never printed" "! $PL $T/sec.md --json | grep -qE 'abcdefghijklmnop|ZZZsecret'"
python3 -c "print('data: ' + 'QUJD'*80)" > $T/blob.md
ok "blob HIGH" "$PL $T/blob.md | grep -q 'HIGH.*blob'"
python3 -c "print('word ' * 5000)" > $T/big.md
ok "over budget exit 1" "! $PL $T/big.md --budget 1000 >/dev/null"
{ echo '```python'; for i in $(seq 1 100); do echo "x_$i = compute($i)  # step"; done; echo '```'; } > $T/code.md
ok "big fenced block flagged" "$PL $T/code.md | grep -q big-block"
ok "--fix shrinks" "$PL $T/bloat.md --fix $T/fixed.md 2>&1 | grep -q 'fixed copy'"
ok "--fix removed dup line" "[ \$(grep -c 'JSON format with keys a and b' $T/fixed.md) -eq 1 ]"
ok "--fix removed filler" "! grep -qi 'please make sure' $T/fixed.md"
ok "--fix refuses overwrite" "! $PL $T/bloat.md --fix $T/fixed.md >/dev/null 2>&1"
ok "--fix redacts secrets" "$PL $T/sec.md --fix $T/sfix.md >/dev/null 2>&1; grep -q REDACTED $T/sfix.md && ! grep -q abcdefghijklmnop $T/sfix.md"
ok "--fix keeps code blocks" "$PL $T/code.md --fix $T/cfix.md >/dev/null 2>&1; cmp -s $T/code.md $T/cfix.md"
ok "json valid" "$PL $T/bloat.md --json | python3 -m json.tool >/dev/null"
done_
