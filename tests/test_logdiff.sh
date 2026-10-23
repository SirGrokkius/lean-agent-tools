#!/usr/bin/env bash
cd "$(dirname "$0")"; . ./lib.sh; T=${TOOLS:-../bin}/logdiff; W=$(mktemp -d); trap 'rm -rf $W' EXIT
{ for i in $(seq 1 50); do echo "2026-10-23 10:0$((i%10)):1$((i%10)) INFO fetched item $i from 10.0.0.$i in ${i}ms"; done
  for r in 1 2 3; do cat <<'P'
Traceback (most recent call last):
  File "app.py", line 10, in <module>
    main()
  File "app.py", line 5, in main
    raise ValueError("bad 42")
ValueError: bad 42
P
  done
  cat <<'J'
java.lang.IllegalStateException: boom
    at com.x.A.run(A.java:12)
    at com.x.B.go(B.java:7)
J
  echo "WARN disk at 91%"; echo "rare line once"; echo "token=abcdefghijklmnop1234 leaked"; } > $W/a.log
O=$($T $W/a.log)
ok "--help" "$T --help"
ok "50 info lines -> one x50 template" "grep -q '^x50 ' <<<\"\$O\""
ok "3 py tracebacks -> one x3 trace" "grep -q 'x3 *trace: ValueError: bad 42 (2 frames' <<<\"\$O\""
ok "java trace detected" "grep -q 'trace: java.lang.IllegalStateException: boom (2 frames' <<<\"\$O\""
ok "warn kept" "grep -q 'WARN disk' <<<\"\$O\""
ok "secret redacted" "grep -q REDACTED <<<\"\$O\" && ! grep -q abcdefghijklmnop1234 <<<\"\$O\""
ok "footer counts" "grep -q 'traces=4 (2 unique)' <<<\"\$O\""
ok "frame lines not leaked as normal lines" "! grep -qE '^x[0-9]+ +(File|at |raise|main)' <<<\"\$O\""
ok "--max keeps errors over normal" "$T $W/a.log --max 3 | grep -q 'WARN disk'"
ok "--top 1" "[ \$($T $W/a.log --top 1 | grep -vcE 'trace|WARN|REDACTED|logdiff:|omitted') -eq 1 ]"
ok "--only-new needs state" "[ \$($T $W/a.log --only-new >/dev/null 2>&1; echo \$?) -eq 2 ]"
$T $W/a.log --since-file $W/st.json >/dev/null
echo "brand new event kind" >> $W/a.log
ok "--only-new shows just the new template" "O2=\$($T $W/a.log --since-file $W/st.json --only-new); grep -q 'NEW x1 *brand new' <<<\"\$O2\" && [ \$(grep -c '^NEW' <<<\"\$O2\") -eq 1 ]"
ok "state mode 600" "[ \$(stat -c %a $W/st.json) = 600 ]"
ok "ansi + CR progress stripped" "printf '\033[31mred\033[0m\n10%%\r50%%\r100%%\n' | $T | grep -q '^x1 *100%' "
ok "stdin" "echo hi | $T | grep -q 'x1 *hi'"
ok "missing file rc1" "[ \$($T /nonexistent >/dev/null 2>&1; echo \$?) -eq 1 ]"
ok "unknown arg rc2" "[ \$($T --zz >/dev/null 2>&1; echo \$?) -eq 2 ]"
ok "long paths are not redacted" "echo '/home/user/projects/some/very/long/path/to/a/file/name.py ok' | $T | grep -q name.py"
done_
