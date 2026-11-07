# Test parity — Tuba-rb

| | |
|---|---|
| Upstream | `origin/main` @ `3ff8d0c6` |
| Port | `ruby` @ `0dd5a528` |
| Upstream tests | 22 |
| Ported | 8 |
| Gaps | 14 |
| Test command (specs) | `nix develop --command xvfb-run -a ruby -e 'require "rspec/core"; exit RSpec::Core::Runner.run(["--format", "progress", "--require", "spec_helper", "spec"])'` — **52 examples, 0 failures**, re-run for this audit |
| Test command (drive) | `nix develop --command xvfb-run -a ruby test/drive_tuba.rb` — **52 of 53 checks passed, 1 failed, DRIVE FAILED**, re-run twice for this audit (deterministic, not a flake) — see below and `.reports/accountability-ensurance.md` |

**Revision note.** The previous version of this document, from an earlier
round, reported `0/22` and predates `spec/utils_units_spec.rb`,
`spec/utils_date_time_spec.rb`, `spec/utils_counting_spec.rb` and
`spec/utils_tag_extractor_spec.rb`, all four of which exist on `ruby` now and
were run for this audit. The bijection table below is rebuilt against the
current tree.

## Census

Run with `.claude/skills/test-parity/scripts/test-census.sh` against a
detached worktree of `origin/main`:

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

22 named `Test.add_func` cases across 10 files, cross-checked against
`tests/meson.build`'s registered binaries (one binary per file, matches).

## Bijection table

| # | Upstream test | Purpose (behaviour) | Port test | State |
|---|---|---|---|---|
| 1 | `/test_base83_decode` | decodes a base83 blurhash string to its component values | — | **gap** |
| 2 | `/test_blurhash_data` | blurhash decode produces the right pixel data for a known hash | — | **gap** |
| 3 | `/test_blurhash_ratio` | blurhash aspect ratio is derived correctly from components | — | **gap** |
| 4 | `/test_blurhash_validity` | an invalid blurhash string is rejected rather than crashing | — | **gap** |
| 5 | `/test_celebrate` | the celebrate/confetti trigger fires on the right condition | — | **gap** |
| 6 | `/test_count` | text/character counting toward the post length limit is correct | `spec/utils_counting_spec.rb` `.chars (test_count)` — 3 content-length cases incl. the ICU Devanagari-conjunct divergence, named in the spec | **ported** |
| 7 | `/test_mention` | a `@handle` mention is recognised and counted/highlighted correctly | `spec/utils_counting_spec.rb` `.replace_mentions (test_mention)` | **ported** |
| 8 | `/test_ago` | a timestamp renders as a correct relative "x ago" string | `spec/utils_date_time_spec.rb` `#test_ago` + the relative-dates block (1h/2m/etc) | **ported** |
| 9 | `/test_3_months` | the "months ago" boundary of relative-time formatting is correct | `spec/utils_date_time_spec.rb` `.is_3_months_old (test_3_months)` — 7 boundary cases | **ported** |
| 10 | `/test_humanize` | absolute/relative date humanisation picks the right format | `spec/utils_date_time_spec.rb` `#test_humanize` | **ported** |
| 11 | `/test_left` | time-remaining formatting (e.g. poll closes in…) is correct | `spec/utils_date_time_spec.rb` `#test_left` + the relative-dates block | **ported** |
| 12 | `/test_pango` | HTML from a status body converts to valid Pango markup | — | **gap** |
| 13 | `/test_remove_tags` | disallowed HTML tags are stripped from status content | — | **gap** |
| 14 | `/test_restore` | markup round-trips back to editable text correctly | — | **gap** |
| 15 | `/test_simplify` | status HTML is simplified to the subset the UI renders | — | **gap** |
| 16 | `/test_share_handler` | the OS share/open-with handler parses a shared URL/text correctly | — | **gap** |
| 17 | `/test_extractor` | hashtags are extracted from post text correctly | `spec/utils_tag_extractor_spec.rb` — 8 cases covering the trailing-paragraph extraction rules, `MAX_TAGS_ALLOWED` boundary | **ported** |
| 18 | `/test_strip_utm` | tracking (UTM) query parameters are stripped from a link | — | **gap** |
| 19 | `/test_strip_utm_fallback` | UTM stripping falls back safely on a malformed URL | — | **gap** |
| 20 | `/test_cleanup` | link-cleaning removes other known tracking params beyond UTM | — | **gap** |
| 21 | `/test_shorten` | large numbers (follower/boost counts) are shortened (e.g. 12.3K) | `spec/utils_units_spec.rb` `.shorten (test_shorten)` incl. negative-number cases | **ported** |
| 22 | `/test_web_ap_handler` | an ActivityPub/WebFinger URI is parsed/dispatched correctly | — | **gap** |

8 of 22 are now ported: `DateTime` (4/4), `Counting` (2/2), `TagExtractor`
(1/1), `Units` (1/1) — all four map to `lib/utils_*.rb` files that landed
after the previous round's `0/22` report. The remaining 14 gaps are for the
same reason the previous report gave: **no Ruby code exists for them to
exercise.** `src/Utils/Blurhash.vala`, `Celebrate.vala`, `Html.vala`,
`ShareHandler.vala`, `Tracking.vala`, `WebApHandler.vala` have no `lib/*.rb`
counterpart — `grep -rli` for any of blurhash/celebrate/pango/strip_utm/
webfinger-style logic in `lib/` returns nothing.

## What the port's own suite actually is

`test/drive_tuba.rb` has **53** `d.check(...)` calls (`grep -c 'd.check('
test/drive_tuba.rb` → 53) across the 11 components named in
`.reports/component-identification.md` (application shell, settings, base
view, content base view, widgetizable, vote check button, profile menu,
avatar, tabbed view, shortcuts dialog, about dialog). **Zero of the 53
correspond to any of the 22 upstream tests above** — they drive widgets, not
text/date/URL utility functions, and are entirely orthogonal to this ledger's
count. The task that commissioned this round of reports stated the drive gate
as `53 checks passed, 0 failed`. Re-run twice for this audit, under the dev
shell, it is **`52 of 53 checks passed`, `failed check: wide views keep the
large-view padding`, `DRIVE FAILED (1)`** — deterministic, not a flake. That
claim was false on this commit. See `.reports/accountability-ensurance.md`.

Separately, `spec/*.rb` (the 52 examples that back the 8 ported rows above)
pass cleanly under `rspec`, re-run for this audit: `52 examples, 0 failures`.
That suite is real and green; it is also a different test runner from the
one the task's gate number names, and it is the one actually responsible for
test parity's 8/22.

## Verdict

**8/22 ported, 14 gaps.** Up from the previous round's `0/22` — `DateTime`,
`Counting`, `TagExtractor` and `Units` are now covered by named specs that
pin the same cases upstream pinned, run under `rspec` and currently green.
The remaining 14 (`Blurhash` ×4, `Celebrate` ×1, `Html` ×4, `ShareHandler`
×1, `Tracking` ×3, `WebApHandler` ×1) have no Ruby code to test because the
behaviour itself is unported: text processing for status bodies
(HTML→Pango), link tracking-param stripping, blurhash image placeholders,
share-sheet handling, and ActivityPub/WebFinger URI dispatch are all
prerequisites for the views and widgets that are also unported (see
component-identification and component-parity reports). Reporting "tests
pass" for this port without this ledger, or citing the drive script's claimed
53/0 without re-running it, would be the false-green pattern
`accountability-ensurance` exists to catch.

## Extra

- `test/drive_tuba.rb` — 53 checks driving the application shell, settings,
  base/content/tabbed view states, shortcuts dialog, about dialog, profile
  menu, avatar and vote-check-button widgets. Outside the upstream-test count
  by definition (these check the port's own scaffolding, not anything
  upstream's `tests/` directory pinned), and, on this commit, one of the 53
  fails.
