#!/usr/bin/env bash
# Reproduce the Bitcoin examples in the README. Offline; uses only synthetic data.
set -euo pipefail; cd "$(dirname "$0")"; B=../bin; W=$(mktemp -d); trap 'rm -rf $W' EXIT
python3 gen_bitcoind_log.py > $W/debug.log; python3 gen_ln_payments.py > $W/payments.csv
row(){ printf '%-44s %10s B -> %8s B\n' "$1" "$(wc -c < "$2")" "$(wc -c < "$3")"; }
$B/squeeze -n 40 < $W/debug.log > $W/o1;  row "squeeze -n 40 < debug.log" $W/debug.log $W/o1
$B/logdiff $W/debug.log > $W/o2;          row "logdiff debug.log" $W/debug.log $W/o2
grep ERROR $W/debug.log > $W/o3 || true;  row "grep ERROR debug.log (plain baseline)" $W/debug.log $W/o3
$B/csvq $W/payments.csv status=FAILED -c creation_date,value_sat,failure_reason -n 20 > $W/o4; row "csvq: 20 failed payments, 3 columns" $W/payments.csv $W/o4
$B/csvq $W/payments.csv status=FAILED --count > $W/o5; row "csvq: count failed payments" $W/payments.csv $W/o5
$B/csvq $W/payments.csv --schema > $W/o6; row "csvq --schema" $W/payments.csv $W/o6
echo; echo "--- logdiff output ---"; cat $W/o2
