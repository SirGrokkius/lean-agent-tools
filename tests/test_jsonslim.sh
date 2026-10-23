#!/usr/bin/env bash
cd "$(dirname "$0")"; JS=$(cd "${TOOLS:-../bin}" && pwd)/jsonslim
set -uo pipefail

PASSED=0
FAILED=0
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

pass() {
    echo "PASS: $1"
    PASSED=$((PASSED + 1))
}

fail() {
    echo "FAIL: $1"
    FAILED=$((FAILED + 1))
}

# 1. Help test
if "$JS" --help >/dev/null 2>&1; then
    pass "Help command succeeds"
else
    fail "Help command failed"
fi

# 2. Unknown arg test (should exit non-zero, specifically exit 2)
"$JS" --unknown-arg-xyz >/dev/null 2>&1
code=$?
if [ $code -eq 2 ]; then
    pass "Unknown arg exits with 2"
else
    fail "Unknown arg exited with $code (expected 2)"
fi

# 3. Basic JSON slimming and dropping empty/null
cat << 'EOF' > "$TMPDIR/input1.json"
{
  "name": "test",
  "null_val": null,
  "empty_str": "",
  "empty_list": [],
  "empty_dict": {},
  "valid": 123
}
EOF

output=$("$JS" "$TMPDIR/input1.json" 2>/dev/null)
if echo "$output" | grep -q '"name": "test"' && echo "$output" | grep -q '"valid": 123' && ! echo "$output" | grep -q 'null_val'; then
    pass "Basic slimming drops null/empty fields"
else
    fail "Basic slimming failed to drop null/empty fields"
fi

# 4. Max array truncation
cat << 'EOF' > "$TMPDIR/array.json"
{
  "items": [1, 2, 3, 4, 5, 6, 7, 8]
}
EOF

output=$("$JS" "$TMPDIR/array.json" --max-array 3 2>/dev/null)
if echo "$output" | grep -q 'more items'; then
    pass "Array truncation works"
else
    fail "Array truncation failed"
fi

# 5. Max string truncation
cat << 'EOF' > "$TMPDIR/string.json"
{
  "long_text": "abcdefghijklmnopqrstuvwxyz"
}
EOF

output=$("$JS" "$TMPDIR/string.json" --max-str 5 2>/dev/null)
if echo "$output" | grep -q '...(+21 chars)'; then
    pass "String truncation works"
else
    fail "String truncation failed"
fi

# 6. Keep (-k) and Drop (-x)
cat << 'EOF' > "$TMPDIR/filter.json"
{
  "a": 1,
  "b": 2,
  "user": {
    "id": 42,
    "secret_token": "secret123"
  }
}
EOF

output=$("$JS" "$TMPDIR/filter.json" -k user.id 2>/dev/null)
if echo "$output" | grep -q '"id": 42' && ! echo "$output" | grep -q '"a": 1'; then
    pass "Keep (-k) works"
else
    fail "Keep (-k) failed"
fi

# 7. Schema option
output=$("$JS" "$TMPDIR/filter.json" --schema 2>/dev/null)
if echo "$output" | grep -q 'user.id: integer'; then
    pass "Schema generation works"
else
    fail "Schema generation failed"
fi

# 8. JSON Lines
cat << 'EOF' > "$TMPDIR/lines.jsonl"
{"id": 1}
{"id": 2}
EOF

output=$("$JS" "$TMPDIR/lines.jsonl" 2>/dev/null)
if echo "$output" | grep -q '"id": 2'; then
    pass "JSON Lines parsing works"
else
    fail "JSON Lines parsing failed"
fi

# 9. Compact output
output=$("$JS" "$TMPDIR/input1.json" --compact 2>/dev/null)
if [ $(echo "$output" | wc -l) -eq 1 ]; then
    pass "Compact output works"
else
    fail "Compact output failed"
fi

# 10. Secret redaction
cat << 'EOF' > "$TMPDIR/secrets.json"
{
  "api_key": "my-secret-key-123",
  "openai": "sk-proj-abcdefghijklmnopqrstuvwxyz123456"
}
EOF

output=$("$JS" "$TMPDIR/secrets.json" 2>/dev/null)
if echo "$output" | grep -q '\[REDACTED\]'; then
    pass "Secret redaction works"
else
    fail "Secret redaction failed"
fi

# 11. URL security (refuse loopback/private without allow-local)
"$JS" "http://127.0.0.1/test.json" >/dev/null 2>&1
code=$?
if [ $code -ne 0 ]; then
    pass "URL security blocks local/private IPs by default"
else
    fail "URL security allowed local/private IP without --allow-local"
fi

TOTAL=$((PASSED + FAILED))
echo ""
echo "$PASSED/$TOTAL passed"

if [ $FAILED -gt 0 ]; then
    exit 1
else
    exit 0
fi
