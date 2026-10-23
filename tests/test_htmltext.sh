#!/usr/bin/env bash
# offline tests for htmltext (no network: only refusals are tested for URLs)
cd "$(dirname "$0")"; . ./lib.sh; T=${TOOLS:-../bin}/htmltext; W=$(mktemp -d); trap 'rm -rf $W' EXIT
cat > $W/a.html <<'H'
<html class="menu-open"><head><title>My Post</title><script>var secret=1</script><style>p{}</style></head><body>
<nav class="navbar"><a href="/">Home</a> NAVTEXT</nav><div id="cookie-banner">We use cookies</div>
<article><h1>Hello world</h1><p>This is the main <b>content</b>.</p><p>Key: sk-abcdefghijklmnopqrstuvwx</p><p>See <a href="https://ex.com/x">link</a>.</p></article>
<aside>SIDEBAR</aside><footer>COPYRIGHT</footer></body></html>
H
O=$($T $W/a.html --links)
ok "--help exits 0" "$T --help"
ok "title kept" "grep -q 'TITLE: My Post' <<<\"\$O\""
ok "article text kept" "grep -q 'main content' <<<\"\$O\""
ok "nav dropped" "! grep -q NAVTEXT <<<\"\$O\""
ok "cookie/aside/footer dropped" "! grep -qE 'cookies|SIDEBAR|COPYRIGHT' <<<\"\$O\""
ok "script dropped" "! grep -q 'var secret' <<<\"\$O\""
ok "secret redacted" "grep -q REDACTED <<<\"\$O\" && ! grep -q sk-abc <<<\"\$O\""
ok "links listed" "grep -q 'https://ex.com/x' <<<\"\$O\""
ok "html class with 'menu' doesn't drop page" "grep -q Hello <<<\"\$O\""
ok "stdin works" "$T - < $W/a.html | grep -q Hello"
python3 -c "print('<html><body><main>' + ''.join('<p>para %d '%i + 'x'*80 + '</p>' for i in range(200)) + '</main></body></html>')" > $W/big.html
ok "budget caps output" "[ \$($T $W/big.html --budget 1000 | wc -c) -lt 1200 ]"
ok "budget note printed" "$T $W/big.html --budget 1000 | grep -q 'cut at 1000'"
ok "file:// refused rc2" "! $T file:///etc/passwd; [ \$? -eq 0 ] && [ \$($T file:///etc/passwd >/dev/null 2>&1; echo \$?) -eq 2 ]"
ok "loopback refused" "[ \$(GROKKIUS_ALLOW_NETS= $T http://127.0.0.1:9/ >/dev/null 2>&1; echo \$?) -eq 2 ]"
ok "metadata IP refused" "$T http://169.254.169.254/ 2>&1 | grep -q refused"
ok "private 10.x refused" "$T http://10.0.0.1/ 2>&1 | grep -q refused"
ok "ftp refused" "$T ftp://example.com/ 2>&1 | grep -q 'refused scheme'"
ok "empty page rc1" "echo '<html><body><script>x</script></body></html>' | $T -; [ \$? -eq 1 ] || [ \$(echo '<html><body></body></html>' | $T - >/dev/null 2>&1; echo \$?) -eq 1 ]"
ok "unknown arg rc2" "[ \$($T --bogus >/dev/null 2>&1; echo \$?) -eq 2 ]"
done_
