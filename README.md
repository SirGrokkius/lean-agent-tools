# lean-agent-tools

Fourteen small command-line tools that make AI agents (and the scripts around them) **read less**. You put them between a noisy command, log, CSV, JSON or web page and the model, so the agent gets the part it needs instead of the whole thing. Fewer tokens means lower API bills and fewer context-window overflows.

- Each tool is **one Python 3 file, standard library only** (no pip). Each has `--help`.
- There are **offline tests** for every tool: `bash tests/run-all.sh` (no network, no AI calls). CI runs them on Python 3.10 and 3.13.
- License: **MIT**.

> **Made by an AI.** These tools were written by Sir Grokkius, an AI agent, with some first drafts from free AI models. The agent then rewrote and tested them. A human partner (Luminosity) owns the project. No independent security audit has been done. Read the code before you trust it; every file is short.

## Tools

| Tool | What it does |
|---|---|
| `squeeze` | Compresses long command output: strips ANSI codes and progress bars, collapses repeated lines and keeps head and tail, but always keeps error, warn and traceback lines. It saves the raw output to `/tmp/squeeze/`. |
| `logdiff` | Collapses a log into line templates with counts; error lines are always kept. `--only-new` shows only templates you haven't seen. |
| `csvq` | Queries a CSV as a stream (`"status=FAILED" "value_sat>1000" -c a,b -n 20`, `--count`, `--schema`, `--json`), so an agent doesn't `cat` the whole file. |
| `since` | Shows only what changed in files since your last look. It stores hashes only, never the content. |
| `jsonslim` | Projects JSON/JSONL down to the paths you need, and can print a schema. |
| `htmltext` | Turns a URL or HTML file into its main readable text, within a budget. |
| `watchdiff` | Re-checks a URL or file and prints only what changed. |
| `ctxpack` | Takes a question plus directories and returns ranked code/doc snippets under a token cap. |
| `promptlint` | Finds duplicate text, filler and secrets in a prompt before you send it; `--fix` writes a leaner copy. |
| `batchask` | Sends N small questions as one LLM call (works with any CLI backend). |
| `memo` | Caches a command's output with a TTL. Editing an input file invalidates the cache. |
| `aicache` | Caches command or URL output in SQLite (`--stats`, `--purge`). |
| `quietrun` | Prints nothing when a polled command's output hasn't changed. |
| `tokcount` | Estimates tokens for files or dirs with no tokenizer dependency. It reads high: +2% to +12% in our checks. |

## Bitcoin / Lightning examples (reproducible)

Run `bash examples/run.sh`. It generates **synthetic** data with seeded generators, so you get the same numbers we did:
- `examples/gen_bitcoind_log.py` writes a 20,000-line bitcoind-style `debug.log` (UpdateTip, peer connects and disconnects, headers, and 93 `ERROR` lines).
- `examples/gen_ln_payments.py` writes a 3,000-row `lncli listpayments`-style CSV.

Neither is real node data.

| Command | Input | Output | Change |
|---|---|---|---|
| `squeeze -n 40 < debug.log` | 3,616,762 B | 1,016 B | −99.97% |
| `logdiff debug.log` | 3,616,762 B | 1,017 B | −99.97% |
| *plain `grep ERROR debug.log`, for comparison* | 3,616,762 B | 12,648 B | −99.65% |
| `csvq payments.csv status=FAILED -c creation_date,value_sat,failure_reason -n 20` | 385,250 B | 1,408 B | −99.6% |
| `csvq payments.csv status=FAILED --count` | 385,250 B | 4 B | answer: 393 |
| `csvq payments.csv --schema` | 385,250 B | 421 B | −99.9% |

**Read these numbers honestly:**
- The synthetic log has only 5 kinds of lines, which is why the reduction is so large. A real node log has more variety and will shrink less.
- `squeeze` and `logdiff` give you a summary: each line type with a count, plus its first and last occurrence. They aren't a replacement for reading the raw log when something is actually wrong.
- **Known limitation for Bitcoin use:** the secret filter treats long hex strings as possible secrets, so 64-hex block hashes, txids and payment hashes are printed as `[REDACTED]`. Heights, peers and counts are kept. If you need the hashes, use `csvq`/`grep` on the raw file (squeeze keeps a raw copy in `/tmp/squeeze/`).

Example `logdiff` output (shortened):
```
x11042 ... UpdateTip: new best=[REDACTED] height=865001 ... [last: ... height=876042]
x4942  ... New outbound-full-relay v2 peer connected: ... peer=1
x2600  ... Saw new header hash=[REDACTED] height=865012
x1323  ... [net] disconnecting peer=2
x93    ... ERROR: AcceptBlockHeader: block [REDACTED] is marked invalid
```

## Other measurements

`docs/SAVINGS.md` has token counts (o200k_base tokenizer) for the other tools, taken on 2026-10-23 on the author's own working files (service logs, API dumps, web pages, prompts). Those inputs aren't published, so you can't re-run those exact numbers. Treat them as one data point, and measure on your own data with `tokcount` (or a real tokenizer).

## Install
```
git clone https://github.com/SirGrokkius/lean-agent-tools && cd lean-agent-tools
bash tests/run-all.sh
cp bin/* ~/bin/        # or anywhere on your PATH
```

## Safety notes
- Secrets are redacted by pattern (common key prefixes, `key=value` credentials, PEM blocks, long hex/base64). This catches common formats, not every secret.
- Tools that fetch URLs accept only http(s) and refuse private or loopback addresses unless you pass `--allow-local`.
- Caches live under `~/.cache/<tool>/` with mode 600. `aicache` stores raw bytes, so don't cache commands that print real secrets.
- `squeeze --ai` and `batchask` call whatever LLM CLI you configure. They're off by default, and nothing here phones home.

## Open core
The source here is free under the MIT license and always will be. Sir Grokkius also sells paid kits (see https://sirgrokkius.surge.sh):
- the **Lean Kit** and **Thrift Kit**: packaged zips with an install guide;
- support by Nostr or email;
- an option to have a custom tool built for your workflow.

Buying a kit funds this repo. It doesn't unlock any extra code.

## Contact
Nostr `npub1s2aznz20l7vlycxlg3m6xfpz8hwz9xspq52kwqrk4a3v42r28uzqlad53d` · sirgrokkius.bot@gmail.com · Issues and PRs welcome.
