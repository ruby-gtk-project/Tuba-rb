# Test parity — Tuba-rb

| | |
|---|---|
| Upstream | `origin/main` @ `3ff8d0c6` |
| Port | `ruby` @ `6e37c565` |
| Upstream tests | 22 named `Test.add_func` cases across 10 `.vala` files |
| Ported | 12 |
| Gaps | 10 |
| Spec files | `spec/utils_units_spec.rb`, `spec/utils_date_time_spec.rb`, `spec/utils_counting_spec.rb`, `spec/utils_tag_extractor_spec.rb`, `spec/utils_blurhash_spec.rb` (new this round) |
| Drive script | `test/drive_tuba.rb` — 79/79, see below |

## Census (upstream, `tests/*.test.vala`)

```
tests/Blurhash.test.vala      /test_base83_decode      121
tests/Blurhash.test.vala      /test_blurhash_data      124
tests/Blurhash.test.vala      /test_blurhash_ratio     123
tests/Blurhash.test.vala      /test_blurhash_validity  122
tests/Celebrate.test.vala     /test_celebrate          153
tests/Counting.test.vala      /test_count               44
tests/Counting.test.vala      /test_mention             45
tests/DateTime.test.vala      /test_3_months           199
tests/DateTime.test.vala      /test_ago                197
tests/DateTime.test.vala      /test_humanize           198
tests/DateTime.test.vala      /test_left               196
tests/Html.test.vala          /test_pango               77
tests/Html.test.vala          /test_remove_tags         80
tests/Html.test.vala          /test_restore             78
tests/Html.test.vala          /test_simplify            79
tests/ShareHandler.test.vala  /test_share_handler       42
tests/TagExtractor.test.vala  /test_extractor          102
tests/Tracking.test.vala      /test_cleanup            134
tests/Tracking.test.vala      /test_strip_utm          132
tests/Tracking.test.vala      /test_strip_utm_fallback 133
tests/Units.test.vala         /test_shorten             35
tests/WebApHandler.test.vala  /test_web_ap_handler      31
```

## Bijection

| Upstream test file | Cases | Port spec | Ported | Gap |
|---|---:|---|---:|---|
| `Units.test.vala` | 1 | `spec/utils_units_spec.rb` | 1 | — |
| `Counting.test.vala` | 2 | `spec/utils_counting_spec.rb` | 2 | — |
| `DateTime.test.vala` | 4 | `spec/utils_date_time_spec.rb` | 4 | — |
| `TagExtractor.test.vala` | 1 | `spec/utils_tag_extractor_spec.rb` | 1 | — |
| `Blurhash.test.vala` | 4 | `spec/utils_blurhash_spec.rb` (new this round) | 4 | — |
| `Html.test.vala` | 4 | none (`lib/utils_html.rb` does not exist) | 0 | **gap: 4** |
| `Tracking.test.vala` | 3 | none (`lib/utils_tracking.rb` does not exist) | 0 | **gap: 3** |
| `Celebrate.test.vala` | 1 | none | 0 | **gap: 1** |
| `ShareHandler.test.vala` | 1 | none | 0 | **gap: 1** |
| `WebApHandler.test.vala` | 1 | none | 0 | **gap: 1** |

12/22 ported, 10/22 gap — matches the file-by-file census exactly: every
ported spec corresponds to a `Utils/*.vala` file that also has a `lib/*.rb`
port (`utils_units.rb`, `utils_counting.rb`, `utils_date_time.rb`,
`utils_tag_extractor.rb`, and now `utils_blurhash.rb`); every un-ported test
corresponds to a `Utils/*.vala` file with **no** `lib/*.rb` port at all
(Html, Tracking, Celebrate, ShareHandler, WebApHandler). No test exists in
the port for a file the port itself doesn't have — that's expected, but it
also means test parity here is entirely downstream of component parity, not
an independent axis yet. Note the census's "4 cases" for Blurhash undercounts
what actually runs: `spec/utils_blurhash_spec.rb` fans each case out into
several `it` blocks (fixture-driven), so the real example count is higher
than 4 — see the suite run below.

## Does the suite actually run?

**Yes, verified live for this round, and the previous round's entry-point
bug is fixed.** The last round found plain `rspec` crashing because `.rspec`
unconditionally required a `RspecJunitFormatter` formatter that nothing in
the Gemfiles installs. This round's commit (`6e37c565`) drops those two
lines from `.rspec`, and re-running the plain command for this audit
confirms it now works:

```
$ nix develop --command xvfb-run -a rspec
...
Randomized with seed ...
.....................................................................................
85 examples, 0 failures
```

85 examples (not 22 — each upstream test case fans out into multiple `it`
blocks, e.g. one per fixture value), 0 failures, run through the plain
`rspec` executable with no workaround — confirmed by direct execution for
this audit, not assumed from the commit message. The dev shell's banner
still prints the longer one-liner as its documented command, which is now
redundant rather than load-bearing:

```
$ nix develop --command xvfb-run -a ruby -e 'require "rspec/core"; exit RSpec::Core::Runner.run(["--format", "progress", "--require", "spec_helper", "spec"])'
...
85 examples, 0 failures
```

Both commands pass. The infrastructure gap flagged two rounds ago is
retired — the documented contributor entry point (`rspec`) now works as
written, confirmed live, not carried forward as fixed-but-unverified.

## Drive script

```
nix develop --command xvfb-run -a ruby test/drive_tuba.rb
...
79 of 79 checks passed
DRIVE OK
```

Re-run live for this audit, matches the task's stated gate exactly. Per
`.reports/component-identification.md`, this exercises roughly 13–16 of
~146 user-facing upstream units — real, but narrow. The task's own framing
("a component no check exercises is unverified, not done") means the other
~130+ units have no behavioural verification of any kind, not rspec and not
drive.

## Verdict

Test parity: **12/22 upstream cases ported**, 1:1 with the `Utils/*.vala`
files that have a port. Not a single test exists yet for any Dialog, View,
or Widget file — because none of those have enough of a port to test. The
suite that exists passes, and this round the plain `rspec` entry point
(the previous round's finding) is fixed and confirmed working live.
