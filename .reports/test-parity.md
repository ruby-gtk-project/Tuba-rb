# Test parity — Tuba-rb

| | |
|---|---|
| Upstream | `origin/main` @ `3ff8d0c6` |
| Port | `ruby` @ `b67c1339` |
| Upstream tests | 22 |
| Ported | 0 |
| Gaps | 22 |
| Test command | `nix develop --command xvfb-run -a -s '-screen 0 1920x1080x24' ruby test/drive_tuba.rb` |

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
| 6 | `/test_count` | text/character counting toward the post length limit is correct | — | **gap** |
| 7 | `/test_mention` | a `@handle` mention is recognised and counted/highlighted correctly | — | **gap** |
| 8 | `/test_ago` | a timestamp renders as a correct relative "x ago" string | — | **gap** |
| 9 | `/test_3_months` | the "months ago" boundary of relative-time formatting is correct | — | **gap** |
| 10 | `/test_humanize` | absolute/relative date humanisation picks the right format | — | **gap** |
| 11 | `/test_left` | time-remaining formatting (e.g. poll closes in…) is correct | — | **gap** |
| 12 | `/test_pango` | HTML from a status body converts to valid Pango markup | — | **gap** |
| 13 | `/test_remove_tags` | disallowed HTML tags are stripped from status content | — | **gap** |
| 14 | `/test_restore` | markup round-trips back to editable text correctly | — | **gap** |
| 15 | `/test_simplify` | status HTML is simplified to the subset the UI renders | — | **gap** |
| 16 | `/test_share_handler` | the OS share/open-with handler parses a shared URL/text correctly | — | **gap** |
| 17 | `/test_extractor` | hashtags are extracted from post text correctly | — | **gap** |
| 18 | `/test_strip_utm` | tracking (UTM) query parameters are stripped from a link | — | **gap** |
| 19 | `/test_strip_utm_fallback` | UTM stripping falls back safely on a malformed URL | — | **gap** |
| 20 | `/test_cleanup` | link-cleaning removes other known tracking params beyond UTM | — | **gap** |
| 21 | `/test_shorten` | large numbers (follower/boost counts) are shortened (e.g. 12.3K) | — | **gap** |
| 22 | `/test_web_ap_handler` | an ActivityPub/WebFinger URI is parsed/dispatched correctly | — | **gap** |

All 22 are gaps for the same underlying reason: **none of the Ruby code these
tests would exercise exists.** `src/Utils/Blurhash.vala`, `Celebrate.vala`,
`Counting.vala` (actually counting/mention logic lives in `src/Utils/*` or
similar), `DateTime` helpers, `Html.vala`, `ShareHandler.vala`,
`TagExtractor.vala`, `Tracking.vala`, `Units.vala`, `WebApHandler.vala` have
no `lib/*.rb` counterpart — `grep -rli` for any of blurhash/celebrate/
humanize/strip_utm/webfinger style logic in `lib/` returns nothing. There is
no partially-ported case here; it is 22/22 with no code to even partially
test.

## What the port's own suite actually is

`test/drive_tuba.rb` has **48** `d.check(...)` calls under **21** `d.step`
groupings (verified: `grep -c 'd.check('` = 48, matching the runtime gate's
"48 checks passed"). Every one of them is a widget-driving check against the
11 components identified in `.reports/component-identification.md`
(application shell, base view, content base view, tabbed view, shortcuts
dialog, about dialog, profile menu, settings, vote check button, list box row
wrapper, widgetizable). **Zero of the 48 correspond to any of the 22 upstream
tests above** — they test different code entirely (UI plumbing vs. text/date/
URL utility functions). The runtime gate ("48 checks passed, 0 failed, 11
components") is real and reproducible (re-ran it for this audit: `48 of 48
checks passed`, `DRIVE OK`) but it is **evidence about a different, much
narrower slice of the app than test-parity asks about.** A green 48/48 says
nothing about whether `/test_strip_utm` or `/test_pango` holds in Ruby,
because no Ruby code implements what those two test.

## Verdict

**0/22, 22 gaps.** The port has inherited none of upstream's safety net for
text processing, date formatting, number shortening, tag/mention extraction,
blurhash decoding, or protocol URI handling — all of which are prerequisites
for the views and widgets that are also unported (see component-identification
and component-parity reports). The drive suite is real and its 48/48 is not
itself a false claim, but reporting "tests pass" for this port without this
ledger would be exactly the false-green pattern `accountability-ensurance`
exists to catch: a real, narrow, passing suite cited as if it covered ground
it does not touch.

## Extra

- `test/drive_tuba.rb` — 48 checks driving the application shell, base/content/
  tabbed view states, shortcuts dialog, about dialog, profile menu, settings
  persistence, and the two house widgets. Outside the upstream-test count by
  definition (these check the port's own scaffolding, not anything upstream's
  `tests/` directory pinned).
