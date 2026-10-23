#!/usr/bin/env bash
# offline: uses a fake backend script instead of a real AI
cd "$(dirname "$0")"; . ./lib.sh; T=${TOOLS:-../bin}/batchask; W=$(mktemp -d); trap 'rm -rf $W' EXIT
cat > $W/fake <<'F'
#!/usr/bin/env python3
import sys, re
p = sys.argv[-1]; echo $W >/dev/null 2>&1
qs = re.findall(r"^Q(\d+): (.*)$", p, re.M)
open(sys.argv[1], "a").write("call\n")
for n, q in qs:
    if "SKIP" in q: continue
    print(f"### A{n}\nanswer to {q}\n")
F
sed -i 's/; echo \$W >\/dev\/null 2>&1//' $W/fake; chmod +x $W/fake
printf 'q one\nq two\n# comment\n\nq three\n' > $W/q.txt
ok "--help" "$T --help"
ok "3 answers, 1 call" "O=\$($T $W/q.txt --backend '$W/fake $W/calls'); grep -q 'A3: answer to q three' <<<\"\$O\" && [ \$(wc -l < $W/calls) -eq 1 ]"
ok "json output" "$T $W/q.txt --json --backend '$W/fake $W/c2' | python3 -c 'import json,sys; d=json.load(sys.stdin); assert len(d)==3 and d[1][\"a\"]==\"answer to q two\"'"
printf 'good\nSKIP me\n' > $W/q2.txt
ok "missing reported, rc1" "O=\$($T $W/q2.txt --backend '$W/fake $W/c3'); [ \$? -eq 1 ] && grep -q 'A2: MISSING' <<<\"\$O\""
ok "chunks by --max-q" "rm -f $W/c4; seq 1 7 | sed 's/^/q/' | $T - --max-q 3 --backend '$W/fake $W/c4' >/dev/null; [ \$(wc -l < $W/c4) -eq 3 ]"
ok "secret refused before any call" "rm -f $W/c5; echo 'my key sk-abcdefghijklmnopqrstuv' | $T - --backend '$W/fake $W/c5'; [ \$? -eq 2 ] && [ ! -e $W/c5 ]"
ok "dry-run makes no call" "rm -f $W/c6; $T $W/q.txt --dry-run --backend '$W/fake $W/c6' | grep -q 'Q3: q three' && [ ! -e $W/c6 ]"
ok "multi-line blocks with ---" "printf 'line a\nline b\n---\nsecond\n' | $T - --dry-run 2>/dev/null | grep -q 'Q2: second'"
ok "question text not shell-evaluated" "echo '\$(touch $W/pwned)' | $T - --backend '$W/fake $W/c7' >/dev/null; [ ! -e $W/pwned ]"
ok "missing backend rc2" "[ \$(echo q | $T - --backend 'no-such-bin-xyz' >/dev/null 2>&1; echo \$?) -eq 2 ]"
done_
