# Translation parity — Tuba-rb

| | |
|---|---|
| Upstream | `origin/main` @ `3ff8d0c6` |
| Port | `ruby` @ `0dd5a528` |
| Upstream msgids | 983 (`po/dev.geopjr.Tuba.pot`, 984 `msgid "` lines minus the 1 empty header) |
| Upstream languages shipped | 47 (`po/LINGUAS`) + the template |
| Port msgids | 0 |
| Port languages | 0 |
| Gaps | 983 / 983 |

## What exists upstream

```
po/LINGUAS                      -> 47 language codes
po/POTFILES                     -> list of source files containing translatable strings
po/dev.geopjr.Tuba.pot          -> 984 msgid lines (983 real strings + header)
po/{ar,be,bg,...,zh_Hant}.po    -> 47 translated catalogues
```

## What exists in the port

```
find . -iname '*.po' -not -path './.git/*'   -> (nothing)
find . -name po -not -path './.git/*'         -> (nothing)
grep -rn "gettext\|N_(\|_(\|msgid" lib/ exe/  -> (nothing; one unrelated comment
                                                  line in content_base_view.rb
                                                  mentioning "GLib." in prose,
                                                  not a call)
```

**No `po/` directory. No `.pot`. No `LINGUAS`. No gettext/FastGettext
dependency in the `Gemfile`. No `_()`/`N_()`/`gettext()` call site anywhere
in `lib/` or `exe/`.** Every user-visible string the port currently shows —
button labels, dialog titles, the shortcuts-dialog item titles, the about
dialog, empty/error state text in `base_view.rb` — is a bare Ruby string
literal.

Confirmed directly in `lib/shortcuts_window.rb`: every shortcut title upstream
marks `translatable="yes"` (several with `context="shortcut window"`) is
transcribed into the `SECTIONS` hash as a plain string, with `# translators:`
*comments* left in place above several entries — comments that exist to guide
a translator extracting the string, written over a string that is never
extracted, because nothing in this file or anywhere else calls a marker
function on it.

```ruby
# lib/shortcuts_window.rb:20
# translators: shortcut description
['Show Preferences', 'app.open-preferences'],
```

This is worse than an unmarked string with no comment: it is a string
annotated *as if* it were wired for translation, which reads — to the next
person who touches this file — as already handled.

## Three claims, all failing

1. **Key sets equal.** 0 vs 983. Not close.
2. **Byte-identical keys.** There are no port keys to compare bytes against —
   the port extracts zero, so this claim fails for the same reason as claim 1
   rather than independently of it.
3. **Languages ship.** 0 of 47. A port with a `po/` directory and an empty
   `.po` would at least preserve the *infrastructure*; this port has none of
   it, so there is nothing for a translator to resume work on, and no build
   step compiles or installs any `.mo`.

## Why this matters beyond "currently English-only"

Every string written into the port from here on, written without a marker, is
a second debt on top of the 983 untouched upstream strings — the shortcuts
dialog alone added 17 new unmarked strings this fork, and the about dialog,
empty-state titles, and error messages in `base_view.rb` add more. Each one
is a string a future translation pass has to find by reading source, because
no extraction tool (`xgettext` or the Ruby/GNOME equivalent) has anything to
walk.

## Verdict

**0/983.** Translation parity does not partially hold; it does not hold at
all. There is no catalogue, no extraction, no marker, and no language. This
is a full gap, not a "not yet started on this unit" — every unit built so far
(shell, shortcuts dialog, about dialog, base view states) has already shipped
unmarked strings into the port, so each new unit widens the gap rather than
leaving it where it was.
