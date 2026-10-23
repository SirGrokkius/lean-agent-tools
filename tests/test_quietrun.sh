#!/usr/bin/env bash
cd "$(dirname "$0")"; . ./lib.sh; T=${TOOLS:-../bin}/quietrun; W=$(mktemp -d); trap 'rm -rf $W' EXIT
export QUIETRUN_DIR=$W/state
echo "status ok" > $W/s
ok "--help" "$T --help"
ok "first run prints baseline" "$T --name j -- cat $W/s | grep -q 'baseline'"
ok "unchanged prints nothing" "[ -z \"\$($T --name j -- cat $W/s)\" ]"
ok "volatile timestamp ignored" "$T --name v -- echo 'at 2026-10-23 10:00:01 took 3.2s ok' >/dev/null; [ -z \"\$($T --name v -- echo 'at 2026-10-23 11:59:59 took 9.9s ok')\" ]"
echo "status DOWN" > $W/s
ok "change printed" "$T --name j -- cat $W/s | grep -q DOWN"
echo "status UP" > $W/s
ok "--diff shows +/-" "$T --name j --diff -- cat $W/s | grep -q '^+status UP'"
ok "error always printed + rc" "O=\$($T --name j -- sh -c 'echo boom; exit 4'); [ \$? -eq 4 ] && grep -q 'exit 4' <<<\"\$O\""
ok "--ignore regex" "$T --name i --ignore '^run' -- echo 'run 1' >/dev/null; [ -z \"\$($T --name i --ignore '^run' -- echo 'run 2')\" ]"
ok "secret redacted" "$T --name s -- echo 'token=supersecretvalue123' | grep -q REDACTED"
ok "secret not stored" "! grep -q supersecretvalue123 $W/state/s.json"
ok "heartbeat" "$T --name h -- echo a >/dev/null; sleep 1.1; $T --name h --heartbeat 1 -- echo a | grep -q unchanged"
ok "bad name refused" "[ \$($T --name ../x -- true >/dev/null 2>&1; echo \$?) -eq 2 ]"
ok "reset" "$T --reset --name j >/dev/null; [ ! -e $W/state/j.json ]"
ok "state mode 600" "[ \$(stat -c %a $W/state/h.json) = 600 ]"
done_
