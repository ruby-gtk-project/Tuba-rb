# Test parity — Tuba-rb

| | |
|---|---|
| Upstream | `origin/main` @ `3ff8d0c6` |
| Port | `ruby` @ `72660377` |
| Upstream tests | 22 named `Test.add_func` cases across 10 `.vala` files |
| Ported | 8 |
| Gaps | 14 |
| Spec files | `spec/utils_units_spec.rb`, `spec/utils_date_time_spec.rb`, `spec/utils_counting_spec.rb`, `spec/utils_tag_extractor_spec.rb` (unchanged since last round) |
| Drive script | `test/drive_tuba.rb` — 74/74, see below |

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
| `Blurhash.test.vala` | 4 | none (`lib/utils_blurhash.rb` does not exist) | 0 | **gap: 4** |
| `Html.test.vala` | 4 | none (`lib/utils_html.rb` does not exist) | 0 | **gap: 4** |
| `Tracking.test.vala` | 3 | none (`lib/utils_tracking.rb` does not exist) | 0 | **gap: 3** |
| `Celebrate.test.vala` | 1 | none | 0 | **gap: 1** |
| `ShareHandler.test.vala` | 1 | none | 0 | **gap: 1** |
| `WebApHandler.test.vala` | 1 | none | 0 | **gap: 1** |

8/22 ported, 14/22 gap — matches the file-by-file census exactly: every
ported spec corresponds to a `Utils/*.vala` file that also has a `lib/*.rb`
port (`utils_units.rb`, `utils_counting.rb`, `utils_date_time.rb`,
`utils_tag_extractor.rb`); every un-ported test corresponds to a
`Utils/*.vala` file with **no** `lib/*.rb` port at all (Blurhash, Html,
Tracking, Celebrate, ShareHandler, WebApHandler). No test exists in the port
for a file the port itself doesn't have — that's expected, but it also means
test parity here is entirely downstream of component parity, not an
independent axis yet.

## Does the suite actually run?

**Yes, verified live for this round** — but only through the exact command
the dev shell's own banner prints, not through the plain `rspec` executable:

```
$ nix develop --command xvfb-run -a rspec
...
uninitialized constant RspecJunitFormatter (NameError)
```

`.rspec` unconditionally requires a `RspecJunitFormatter` formatter
(`--format RspecJunitFormatter --out results/test_results.xml`) that is not
installed in the dev shell's gem set. **Running `rspec` the ordinary way, as
any CI step or any contributor typing the obvious command would, crashes
before a single example runs.** This is a real infrastructure gap, filed in
`.reports/accountability-ensurance.md` as well, since it means the
documented "run the specs" entry point from a contributor's perspective
(`rspec`) is broken on this branch right now.

The banner's workaround bypasses `.rspec` by invoking the runner
programmatically with an explicit, minimal format list:

```
$ nix develop --command xvfb-run -a ruby -e 'require "rspec/core"; exit RSpec::Core::Runner.run(["--format", "progress", "--require", "spec_helper", "spec"])'
...
NOTE: kettle-test isn't installed; running with plain RSpec.
.....................................................
52 examples, 0 failures
```

52 examples (not 22 — each test case fans out into multiple `it` blocks,
e.g. one per fixture value), 0 failures, confirmed by direct execution for
this audit. So: **the suite does run and does pass, but not through its own
configured entry point** — a real but narrower gap than "never executed."

## Drive script

```
nix develop --command xvfb-run -a ruby test/drive_tuba.rb
...
74 of 74 checks passed
DRIVE OK
```

Re-run live for this audit, matches the task's stated gate exactly. Per
`.reports/component-identification.md`, this exercises roughly 12–14 of
~146 user-facing upstream units — real, but narrow. The task's own framing
("a component no check exercises is unverified, not done") means the other
~132 units have no behavioural verification of any kind, not rspec and not
drive.

## Verdict

Test parity: **8/22 upstream cases ported**, 1:1 with the `Utils/*.vala`
files that have a port. Not a single test exists yet for any Dialog, View,
or Widget file — because none of those have enough of a port to test. The
suite that exists passes, but its own `.rspec` configuration is broken for
the plain invocation; only the dev shell's hand-written workaround command
runs it.
