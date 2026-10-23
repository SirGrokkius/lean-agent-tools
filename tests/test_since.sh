#!/usr/bin/env bash
cd "$(dirname "$0")"; . ./lib.sh; S=$(cd "${TOOLS:-../bin}" && pwd)/since; W=$(mktemp -d); trap 'rm -rf $W' EXIT
export SINCE_STATE=$W/state; printf 'line one\nline two\n' > $W/a.log
$S --name t $W/a.log >/dev/null
echo "line three token=abcdefabcdef" >> $W/a.log; out=$($S --name t $W/a.log)
ok "since: shows only the new line" 'printf "%s" "$out" | grep -q "line three" && ! printf "%s" "$out" | grep -q "line one"'
ok "since: redacts token" 'printf "%s" "$out" | grep -q REDACTED'
out2=$($S --name t $W/a.log); ok "since: unchanged prints no old lines" '! printf "%s" "$out2" | grep -q "line three"'
done_
