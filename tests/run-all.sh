#!/usr/bin/env bash
# run every offline test; TOOLS=/path/to/bin to test an installed copy
cd "$(dirname "$0")"; fail=0; chmod +x "${TOOLS:-../bin}"/* 2>/dev/null  # some unzip tools drop the exec bit
for t in test_*.sh; do r=$(bash "$t" 2>/dev/null | tail -1); printf '%-42s %s\n' "$t" "$r"; case "$r" in *passed) n=${r%%/*}; m=${r#*/}; m=${m%% *}; [ "$n" = "$m" ] || fail=1;; *) fail=1;; esac; done
[ $fail -eq 0 ] && echo "ALL PASS" || { echo "SOME FAILED"; exit 1; }
