# SAVINGS: real measurements (2026-10-23)

Tokens were counted with the `o200k_base` tokenizer (tiktoken, in a throwaway venv; the tools themselves do **not** need it).
"Before" is what an agent would read without the tool. "After" is the tool's stdout.
All inputs are real files and pages from the author's own working box (logs, API dumps, prompts), not synthetic samples.
Results on your data will differ. A summary is lossy by design, so check that it keeps what you need.

| Tool | Real input | Before (tokens) | After (tokens) | Saved | Notes |
|---|---|---|---|---|---|
| logdiff | service log, 16,798 lines / 1.4 MB | 537,343 | 3,896 | **-99.3%** | 52 templates; tracebacks grouped; errors kept |
| logdiff | browser console log, 1.6 MB | 457,629 | 3,948 | **-99.1%** | |
| logdiff | Android logcat, 5.8 MB | 2,022,781 | 3,767 | **-99.8%** | 1.4 s |
| jsonslim | Nostr event dump, 532 items (projection `-k [].kind -k [].created_at -k [].content --max-str 120`, all items kept) | 167,938 | 8,753 | **-94.8%** | |
| jsonslim | gig-board API dump, 139 items (projection of 4 fields, all items) | 73,181 | 6,591 | **-91.0%** | |
| jsonslim | same file, `--schema` | 73,181 | 865 | -98.8% | field list + types + examples |
| jsonslim | x402 bazaar API dump, `--schema` (id-keyed dicts collapsed to `{*}`) | 116,852 | 7,611 | -93.5% | before the fix the schema was larger than the input (-10%); fixed |
| jsonslim | default skim (first 5 items per array, 200-char strings) | 73k-424k | 0.6k-2.5k | -97% to -99.7% | a skim, not the same information |
| htmltext | en.wikipedia.org/wiki/Bitcoin | 287,477 raw HTML | 17,569 full text / 1,378 at default budget | -93.9% / -99.5% | |
| htmltext | github.com/nostr-protocol/nips | 230,482 | 3,425 / 1,849 | -98.5% / -99.2% | |
| htmltext | docs.python.org difflib page | 39,688 | 7,392 / 1,247 | -81.4% / -96.9% | |
| htmltext | news.ycombinator.com | 11,720 | 1,178 | -89.9% | |
| htmltext | RFC 9110 (huge) | 372,330 | 93,096 / 1,266 | -75.0% / -99.7% | |
| watchdiff | re-check of docs.python.org difflib page (unchanged) | 39,688 raw / 7,392 as text | 21 | **-99.7% vs text** | one line: "no change since ..." |
| watchdiff | re-check of news.ycombinator.com (unchanged within 20 s) | 11,720 / 1,178 | 21 | -98% vs text | when the page changes, only the +/- lines are printed |
| ctxpack | "how does ai-tier pick a model and count the tier1 daily cap" over 2 dirs (167 files hit) | 39,370 (top 8 ranked files read whole) | 3,580 | **-90.9%** | snippets plus file:line refs |
| promptlint `--fix` | 5 agent specs concatenated into one batch prompt (shared rules repeated 5x) | 2,972 | 1,786 | **-39.9%** | dup paragraphs and filler removed; code blocks untouched |
| promptlint | an already-tight 2.9k-token prompt | 2,860 | 2,860 | 0% | correctly reports 0 findings |
| batchask | 8 short factual questions | 8 LLM calls | 1 LLM call | **-7 calls (-87.5%)** | first live call parsed nothing; the auto-retry fixed it (so worst case is 2 calls) |
| memo | `ai-ask llm7 "<question>"` repeated within TTL | 1.24 s + 1 LLM call | 0.03 s, 0 calls | **100% of the repeat call** | non-zero exits and secret-looking output are never cached |
| memo | `tokcount` over a dir | 0.15 s | 0.03 s | -80% wall | auto-invalidates when argument files change (mtime+size) |
| quietrun | `ai-tier status` polled 3x | 3 x ~150 tokens | 1st run full, then 0 bytes | **-67% over 3 polls** (-100% per unchanged poll) | errors and exit codes always pass through |
| quietrun | a scoring/report script (`grade`) re-run with no data change | 5,753 | 0 | **-100% on the unchanged run** | |
| tokcount | 58 real text files (190 KB) | n/a | estimate 57,846 vs tokenizer 54,406 | **+6.3%** (overestimates) | an estimator, deliberately conservative; no tokenizer dependency |
| promptlint estimator | 3 real prompts | n/a | +1.8% to +12.1% vs tokenizer | conservative | |

## How to reproduce

```
tok(){ python3 -c 'import sys,tiktoken;print(len(tiktoken.get_encoding("o200k_base").encode(sys.stdin.read(),disallowed_special=())))'; }
tok < big.log;               logdiff big.log | tok
tok < dump.json;             jsonslim dump.json -k '[].name' --max-array 100000 | tok
curl -sL URL | tok;          htmltext URL | tok
```
