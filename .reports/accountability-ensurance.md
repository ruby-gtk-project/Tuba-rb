# Accountability ensurance — Tuba-rb

Per the `accountability-ensurance` skill, run against `lib/`, `exe/`,
`.reports/` and (absent on this branch, still, every round) `PORTING.md`.

| | |
|---|---|
| Upstream | `origin/main` @ `3ff8d0c6` |
| Port | `ruby` @ `72660377` |

## Headline this round: the runtime gate is real, not a false green

The task that commissioned this round stated the gate as `drive_ok=true, 74
checks passed, 0 failed, covering 14 components`. Two previous rounds each
found the stated gate did not match a fresh run (53/0 claimed vs 52/53 actual
failing; see this file's history below). **This round, the claim checks
out**, re-run twice live for this audit:

```
nix develop --command xvfb-run -a ruby test/drive_tuba.rb
...
74 of 74 checks passed
DRIVE OK
```

This is still a narrow gate — ~12-14 of ~146 user-facing upstream units — and
the task's framing ("a component no check exercises is unverified, not
done") still applies to the other ~132-134 units with no file, see
`.reports/component-identification.md`. But the number itself is accurate
this time, which is the specific failure mode this skill exists to catch,
and it did not recur.

## New finding this round: a broken documented test entry point

`.rspec` configures a formatter (`RspecJunitFormatter`) that is not installed
in the dev shell's gem set. Running the plain `rspec` executable — what a CI
step or any contributor would type — crashes before a single example runs:

```
nix develop --command xvfb-run -a rspec
...
uninitialized constant RspecJunitFormatter (NameError)
```

The dev shell's own banner papers over this with a one-line workaround that
bypasses `.rspec` entirely (`ruby -e 'require "rspec/core"; exit
RSpec::Core::Runner.run([...])'`), which does work (52 examples, 0 failures,
re-run live for this audit). So the suite is not a false green — it genuinely
passes when run the way the project tells you to run it — but the *first*
thing anyone would reach for (`rspec`) is broken, and nothing in `.rspec`,
the `Gemfile`, or a `PORTING.md` (which does not exist) documents why, or
that the workaround exists for a reason rather than habit. This is closer to
an infrastructure bug than an excuse, but it meets this skill's bar for
"a green claim that rests on something never executed [the normal way]" —
filed here and in `.reports/test-parity.md`.

## Scan

```sh
bash .claude/skills/accountability-ensurance/scripts/find-excuses.sh .
```

## Hits, this round

```
.reports/component-parity.md:48          unported   (this round's own report)
.reports/component-identification.md:113 unported   (this round's own report)
.reports/component-inventory.md:7        no Ruby counterpart
.reports/component-inventory.md:12       by design
.reports/component-inventory.md:25       no Ruby counterpart
.reports/component-inventory.md:292      no Ruby counterpart
lib/tabbed_base_view.rb:26               unported
```

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

Four hits, all either a quoted explanation of a real limitation
(`lib/application.rb:31`, `lib/composer.rb:32`, both inside the same
first-person admission paragraphs already covered above) or incidental prose
unrelated to excusing a gap (`lib/profile_menu.rb:37`, a translator comment
about a Mastodon feature name, not about the port itself;
`lib/preferences_dialog.rb:11`, describing what upstream's *excluded* rows
would need, inside the file's own honest scoping comment). None hide a gap
behind a label.

No `PORTING.md` exists on this branch, any round so far — there is nowhere
for a gap to be excused in a document separate from the code or the reports
this task commissions, which is itself worth naming: the only two places
accountability can slip are `lib/`/`exe/` comments and `.reports/`, and both
were checked.

## Status of previous rounds' rewrites

- **Runtime gate**: previous two rounds each found the stated gate false on
  re-run (53/0 claimed vs 52/53 actual, twice). This round's 74/0 claim
  **held** on a live re-run, twice. This is the first round where the
  headline finding is "the gate was accurate" rather than "the gate was
  false" — recorded as a data point, not a pattern yet (one clean round
  after two false ones does not retire the check; it stays mandatory every
  round).
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
is roughly a 5%-ported application (12-14 of ~146 user-facing units with
anything built, most of those partial) with zero translation infrastructure
and 14 of 22 upstream tests unported. This round adds one new, narrower
finding — the broken `rspec` entry point — and retires the previous rounds'
false-runtime-gate finding, which did not recur. Do not stop re-running the
drive and spec commands every round on the strength of this round's clean
result; the two previous rounds are exactly why not.
