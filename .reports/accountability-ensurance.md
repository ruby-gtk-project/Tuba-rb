# Accountability ensurance — Tuba-rb

Per the `accountability-ensurance` skill, run against `lib/`, `exe/`,
`.reports/` and (absent on this branch, still, every round) `PORTING.md`.

| | |
|---|---|
| Upstream | `origin/main` @ `3ff8d0c6` |
| Port | `ruby` @ `6e37c565` |

## Headline this round: the runtime gate is real again, and the rspec entry-point bug from last round is actually fixed

The task that commissioned this round stated the gate as `drive_ok=true, 79
checks passed, 0 failed, covering 16 components`. Re-run live for this audit:

```
nix develop --command xvfb-run -a ruby test/drive_tuba.rb
...
79 of 79 checks passed
DRIVE OK
```

Matches exactly (up from 74/74 two rounds ago). This is still a narrow gate
— ~13-16 of ~146 user-facing upstream units — and the task's framing ("a
component no check exercises is unverified, not done") still applies to the
other ~130+ units with no file, see `.reports/component-identification.md`.
But the number itself is accurate, re-confirmed a second round running.

**Last round flagged a broken documented test entry point**: `.rspec`
configured a `RspecJunitFormatter` formatter that was not installed, so
plain `rspec` crashed before running a single example. This round's commit
(`6e37c565`) removes the two offending lines from `.rspec`. Re-run live for
this audit, not taken on the commit message's word:

```
nix develop --command xvfb-run -a rspec
...
85 examples, 0 failures
```

**Fixed, confirmed.** This is the pattern this skill exists to watch for in
the other direction too — a claimed fix that is actually checked, not just
repeated. It is retired as a finding this round; it stays in the history
section below as a record, and will be re-checked again next round rather
than assumed permanent.

## Scan

```sh
bash .claude/skills/accountability-ensurance/scripts/find-excuses.sh .
```

## Hits, this round

```
.reports/component-parity.md:48          unported   (this round's own report)
.reports/component-identification.md:123 unported   (this round's own report)
.reports/component-inventory.md:7        no Ruby counterpart
.reports/component-inventory.md:12       by design
.reports/component-inventory.md:25       no Ruby counterpart
.reports/component-inventory.md:292      no Ruby counterpart
lib/tabbed_base_view.rb:26               unported
```

(Re-run live for this audit with the current line numbers; same hits as the
previous round, no new one introduced by this round's `utils_blurhash.rb`
addition or by the `.rspec` fix.)

(Hits inside `.reports/accountability-ensurance.md` itself are this file's
own past-tense narration of previous rounds' hits, quoted for the history
section below, not new excuses — excluded from the table above.)

## Reading each one

### `.reports/component-inventory.md:12` — "by design" (GResource line, re-checked)

Unchanged from two rounds ago, and still correctly scoped: it is attached
only to "the port never has `.ui` files" (a real, true architectural fact
about the house style, documented in the `ruby-gtk`/`ruby-gtk4-declarative`
skills), not to any live behaviour gap. The actual behaviour gaps near it
(GResource bundle loading, composer syntax highlighting) are stated in
first person elsewhere in the same file (see below) — this specific "by
design" is legitimate and not rewritten.

### `.reports/component-inventory.md:7, :25, :292` — "no Ruby counterpart"

All three are inside paragraphs that already carry a first-person admission
alongside the phrase (verified by reading each in context this round — e.g.
line 292's paragraph opens "I did not build the resource-bundle loading
mechanism… because I am too stupid to read the upstream source past the word
'GResource'…"). The phrase itself is a factual statement of absence sitting
next to an owned admission, not a bare "unported" standing alone as the
whole explanation. Not rewritten — these are the fixed form the skill asks
for, read correctly this time rather than flagged on pattern-match alone.

### `lib/tabbed_base_view.rb:26` — "unported"

Also inside an already-first-person paragraph ("I did not build
`add_timeline_tab`... because I am an idiot who got the generic mechanism
working and stopped before building the one real thing it was for"), carried
over fixed from two rounds ago. The word "unported" appears only inside a
parenthetical upstream-file pointer (`src/Views/Accounts.vala (unported)`),
not as a standalone excuse. Not rewritten.

### This round's own reports — "unported" (`component-parity.md:48`, `component-identification.md:113`)

Both are single-word summaries inside tables that otherwise name the
specific missing behaviour per row (e.g. component-parity.md's avatar
section names the mini-profile popover, `mini_clicked` signal, and
retry-on-network-change path by name, not just "avatar is unported"). The
flagged word itself is a table-cell shorthand next to a row that already
carries the specific claim. Acceptable as written; not rewritten.

## No TODO/FIXME-style buried excuses

```sh
grep -rniE 'TODO|FIXME|not implemented|for now|in a future|stub' lib/ exe/
```

Five hits this round (one new: `lib/utils_blurhash.rb:4`), all either a
quoted explanation of a real limitation (`lib/application.rb:31`,
`lib/composer.rb:32`, both inside the same first-person admission
paragraphs already covered above) or incidental prose unrelated to excusing
a gap (`lib/profile_menu.rb:37`, a translator comment about a Mastodon
feature name, not about the port itself; `lib/preferences_dialog.rb:11`,
describing what upstream's *excluded* rows would need, inside the file's
own honest scoping comment; `lib/utils_blurhash.rb:4` — the regex's "TODO"
pattern false-matching the substring inside "Mas**todo**n", not a real
`TODO`, checked by reading the line). None hide a gap
behind a label.

No `PORTING.md` exists on this branch, any round so far — there is nowhere
for a gap to be excused in a document separate from the code or the reports
this task commissions, which is itself worth naming: the only two places
accountability can slip are `lib/`/`exe/` comments and `.reports/`, and both
were checked.

## Status of previous rounds' rewrites

- **Runtime gate**: two rounds back, the stated gate was found false on
  re-run, twice (53/0 claimed vs 52/53 actual). The round after that, 74/74
  held on live re-run. This round, 79/79 **also held**, re-run live. Two
  clean rounds in a row after two false ones — still not grounds to stop
  re-running it; it stays mandatory every round.
- **`rspec` entry point**: last round found plain `rspec` broken
  (`RspecJunitFormatter` missing). This round's commit removes the bad
  `.rspec` lines, and a live re-run confirms `rspec` now passes (85
  examples, 0 failures). Fixed, not just claimed-fixed.
- `lib/application.rb`, `lib/tabbed_base_view.rb` — fixed two rounds ago,
  confirmed still fixed by direct read this round.
- `.reports/component-inventory.md:12` (by design, GResource mechanism) —
  confirmed correctly scoped again this round.
- `.reports/component-inventory.md:36`'s old "out of scope" phrasing
  (API/Services/Utils carve-out) — fixed last round; confirmed this round
  that the carve-out language has not crept back into any of the five
  documents rewritten this round.

## Verdict

**Not clean.** The standing gap is the same one every round has found: this
is roughly a 5-10%-ported application (12 of ~146 user-facing units with
anything built, most of those partial — Blurhash, this round's only new
file, is a non-widget utility) with zero translation infrastructure and 10
of 22 upstream tests still unported. This round retires last round's
broken-`rspec`-entry-point finding (confirmed fixed, not just claimed) and
the runtime gate held a second round running. Do not stop re-running the
drive and spec commands every round on the strength of two clean rounds;
the two false rounds before them are exactly why not.
