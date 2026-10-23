#!/usr/bin/env bash
set -uo pipefail

TEST_DIR=$(mktemp -d)
export HOME="$TEST_DIR"
TOOL="$(cd "$(dirname "$0")" && cd "${TOOLS:-../bin}" && pwd)/watchdiff"
chmod +x "$TOOL"

PASSED=0
FAILED=0

assert_eq() {
    local desc="$1"
    local expected="$2"
    local actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "PASS: $desc"
        PASSED=$((PASSED + 1))
    else
        echo "FAIL: $desc (expected '$expected', got '$actual')"
        FAILED=$((FAILED + 1))
    fi
}

assert_contains() {
    local desc="$1"
    local haystack="$2"
    local needle="$3"
    if echo "$haystack" | grep -Fq "$needle"; then
        echo "PASS: $desc"
        PASSED=$((PASSED + 1))
    else
        echo "FAIL: $desc (expected to find '$needle' in '$haystack')"
        FAILED=$((FAILED + 1))
    fi
}

assert_not_contains() {
    local desc="$1"
    local haystack="$2"
    local needle="$3"
    if ! echo "$haystack" | grep -Fq "$needle"; then
        echo "PASS: $desc"
        PASSED=$((PASSED + 1))
    else
        echo "FAIL: $desc (expected NOT to find '$needle' in '$haystack')"
        FAILED=$((FAILED + 1))
    fi
}

# Test 1: --help
output=$("$TOOL" --help 2>&1)
code=$?
assert_eq "Help exit code" "0" "$code"
assert_contains "Help contains usage" "$output" "Usage:"
assert_contains "Help contains examples" "$output" "Examples:"

# Test 2: Unknown argument
"$TOOL" --unknown-flag >/dev/null 2>&1
code=$?
assert_eq "Unknown arg exit code" "2" "$code"

# Test 3: Missing target
"$TOOL" >/dev/null 2>&1
code=$?
assert_eq "Missing target exit code" "2" "$code"

# Test 4: First run on local file (baseline)
TARGET_FILE="$TEST_DIR/test1.txt"
echo "Hello world" > "$TARGET_FILE"
output=$("$TOOL" "$TARGET_FILE" 2>&1)
code=$?
assert_eq "Baseline exit code" "0" "$code"
assert_contains "Baseline saved message" "$output" "baseline saved"

# Test 5: Unchanged file run
output=$("$TOOL" "$TARGET_FILE" 2>&1)
code=$?
assert_eq "Unchanged exit code" "0" "$code"
assert_contains "No change message" "$output" "no change since"

# Test 6: Changed file run
echo "Hello world updated" >> "$TARGET_FILE"
output=$("$TOOL" "$TARGET_FILE" 2>&1)
code=$?
assert_eq "Changed exit code" "3" "$code"
assert_contains "Diff output added" "$output" "+ Hello world updated"
assert_contains "Diff summary" "$output" "+1 -0 lines"

# Test 7: --reset
output=$("$TOOL" "$TARGET_FILE" --reset 2>&1)
code=$?
assert_eq "Reset exit code" "0" "$code"
assert_contains "Reset message" "$output" "state reset"

# Test 8: --ignore option
TARGET_FILE2="$TEST_DIR/test2.txt"
echo -e "Keep this\nIgnore this secret line" > "$TARGET_FILE2"
output=$("$TOOL" "$TARGET_FILE2" --ignore "Ignore" 2>&1)
code=$?
assert_eq "Ignore baseline exit code" "0" "$code"
echo -e "Keep this\nIgnore this secret line updated\nNew kept line" > "$TARGET_FILE2"
output=$("$TOOL" "$TARGET_FILE2" --ignore "Ignore" 2>&1)
code=$?
assert_eq "Ignore changed exit code" "3" "$code"
assert_contains "Ignore diff includes new kept line" "$output" "+ New kept line"

# Test 9: Secret redaction
TARGET_FILE3="$TEST_DIR/test3.txt"
SECRET_VAL="sk-abcdefghijklmnopqrstuvwxyz123456"
echo "My secret token is $SECRET_VAL and status is active" > "$TARGET_FILE3"
output=$("$TOOL" "$TARGET_FILE3" 2>&1)
code=$?
assert_eq "Secret baseline exit code" "0" "$code"

echo "My secret token is $SECRET_VAL and status is inactive" > "$TARGET_FILE3"
output=$("$TOOL" "$TARGET_FILE3" 2>&1)
code=$?
assert_eq "Secret changed exit code" "3" "$code"
assert_contains "Secrets are redacted in diff" "$output" "[REDACTED]"
assert_not_contains "Secret not leaked in diff" "$output" "$SECRET_VAL"

# Test 10: file:// URL rejection
"$TOOL" "file:///etc/passwd" >/dev/null 2>&1
code=$?
assert_eq "file:// URL rejection code" "2" "$code"

# Cleanup temp dir
rm -rf "$TEST_DIR"

echo "--------------------------------------------------------"
TOTAL=$((PASSED + FAILED))
echo "$PASSED/$TOTAL passed"
if [ "$FAILED" -gt 0 ]; then
    exit 1
else
    exit 0
fi
