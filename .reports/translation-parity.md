# Translation parity — Tuba-rb

| | |
|---|---|
| Upstream | `origin/main` @ `3ff8d0c6` |
| Port | `ruby` @ `6e37c565` |
| Upstream msgids | 1019 (`po/dev.geopjr.Tuba.pot`, 1020 `msgid "` lines minus the 1 empty header) |
| Upstream languages shipped | 47 (`po/LINGUAS`) + the template |
| Port msgids | 0 |
| Port languages | 0 |
| Gaps | 1019 / 1019 |

## What exists upstream

```
po/LINGUAS                      -> 47 language codes
po/POTFILES                     -> list of source files containing translatable strings
po/dev.geopjr.Tuba.pot          -> 1020 msgid lines (1019 real strings + header)
po/{ar,be,bg,...,zh_Hant}.po    -> 47 translated catalogues
```

## What exists in the port

```
find . -iname '*.po' -not -path './.git/*'    -> (nothing)
find . -name po -not -path './.git/*'          -> (nothing)
grep -rn "gettext\|N_(\|_(\|msgid" lib/ exe/   -> (nothing real; see below)
```

**No `po/` directory. No `.pot`. No `LINGUAS`. No gettext/FastGettext
dependency in the `Gemfile`. No `_()`/`N_()`/`gettext()` call site anywhere
in `lib/` or `exe/`.** Every user-visible string in the port — button
labels, dialog titles, shortcuts-dialog item titles, the about dialog,
empty/error state text, and now every `PreferencesDialog` row title/subtitle
in `APPEARANCE_ROWS`/`POSTS_ROWS`/`BEHAVIOR_ROWS`/`TIMELINES_ROWS`/
`ONLINE_SERVICES_ROWS` — is a bare Ruby string literal.

Confirmed again, unchanged, in `lib/shortcuts_window.rb`: every shortcut
title upstream marks `translatable="yes"` is transcribed as a plain string,
with `# translators:` *comments* left in place above several entries —
comments that exist to guide extraction over a string that nothing ever
extracts.

```ruby
# lib/shortcuts_window.rb:20
# translators: shortcut description
['Show Preferences', 'app.open-preferences'],
```

**New this round:** `lib/preferences_dialog.rb` adds roughly 30 more
user-visible row titles/subtitles (e.g. `'Darken Images on Dark Mode'`,
`'Warn before boosting a post that includes attachments without alt text'`),
all plain string literals, none marked. `lib/avatar.rb`'s only user-visible
text is the single-character initials fallback, not translatable upstream
either, so it contributes nothing new to either side of this count.

## Three claims, all failing

1. **Key sets equal.** 0 vs 1019. Not close.
2. **Byte-identical keys.** No port keys exist to compare.
3. **Languages ship.** 0 of 47.

## Why this matters beyond "currently English-only"

Every string written into the port without a marker is a second debt on top
of the 1019 untouched upstream strings. This round alone, `preferences_dialog.rb`
added roughly 30 more unmarked strings across its five row tables — on top
of the shortcuts dialog's 17, the about dialog's, and `base_view.rb`'s empty/
error text from previous rounds. Each is a string a future translation pass
must find by reading source, because no extraction tool has anything to walk.

## This round

`lib/utils_blurhash.rb` (the one file to land this round) decodes a
blurhash string into pixel data and is purely arithmetic — it has no
user-visible string, so it contributes nothing to either side of this
count. Re-checked for this audit: still no `po/`, no `.pot`, no gettext
call site, confirmed again with the same greps as above.

## Verdict

**0/1019, unchanged in kind and in absolute count from the previous
round** — this round's one new file added no new unmarked strings either,
being pure arithmetic. No catalogue, no extraction, no marker function, no
language. The gap has not narrowed, and has not widened this round, but
every prior round's unmarked strings (shortcuts dialog, preferences rows,
about dialog, base-view empty/error text) remain exactly as unmarked as
before.
