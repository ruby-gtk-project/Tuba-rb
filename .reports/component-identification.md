# Component identification — Tuba-rb (`ruby` branch vs `origin/main`)

Per the `component-identification` skill, re-run for this round.

| | |
|---|---|
| Upstream | `origin/main` @ `3ff8d0c6` ("fix(ci): android apt (#1791)") |
| Port | `ruby` @ `72660377` |

## Re-verified upstream totals

```
git ls-tree -r --name-only origin/main | grep -c '\.vala$'      -> 255
git ls-tree -r --name-only origin/main | grep -cE '\.(blp|ui)$' -> 40
po/LINGUAS                                                       -> 47 languages
po/dev.geopjr.Tuba.pot                                           -> 1020 msgid lines (1019 real strings)
tests/: 10 .vala test files, 22 named Test.add_func cases (see test-parity report)
```

`src/Dialogs/**` = 35 files, `src/Views/**` = 52 files (incl. `Admin/*`),
`src/Widgets/**` = 59 files, `src/API/**` = 71 files, `src/Services/**` =
13 files. Total user-facing (Dialogs+Views+Widgets) = **146 files**.

## `lib/` file by file, since the last round

Four files landed since `.reports/component-inventory.md` (the opening
survey, still accurate as a baseline) was written: `lib/avatar.rb`,
`lib/utils_counting.rb`, `lib/utils_date_time.rb`, `lib/utils_tag_extractor.rb`,
`lib/utils_units.rb` (4 utils files, no widgets), and now `lib/preferences_dialog.rb`.
`lib/` is 19 `.rb` files total (22 including `tuba.rb`, `tuba/rb.rb`,
`tuba/rb/version.rb`).

| `lib/*.rb` | Upstream source | Widgets built | Signals / actions | Status |
|---|---|---|---|---|
| `application.rb` | `src/Application.vala` (partial) | app window holding a bare view shell | 5 of upstream's ~20 app actions (`about`, `quit`, `shortcuts`, `scroll-page-up`, `scroll-page-down`) + composer/preferences open actions | partial |
| `base_view.rb` | `src/Views/Base.vala` | loading spinner, empty state, error state (icon+title+message+reload button), breakpoint-driven `large-view` class | `notify::model`, reload-button `clicked` | partial base class only |
| `content_base_view.rb` | `src/Views/ContentBase.vala` | content list/cards | row-activated → open | partial base class only |
| `tabbed_base_view.rb` | `src/Views/TabbedBase.vala` | `Adw.ViewStack` + tab switching, Alt+1..9 | tab-switch, rename | partial base class only |
| `widgetizable.rb` | `src/Widgets/Widgetizable.vala` | mixin, no widgets of its own | loud-failure contract | parity (mixin behaviour) |
| `vote_check_button.rb` | `src/Widgets/VoteCheckButton.vala` | `Gtk.CheckButton` subclass | `toggled` | ported leaf widget |
| `list_box_row_wrapper.rb` | `src/Widgets/ListBoxRowWrapper.vala` | `Gtk.ListBoxRow` subclass | — | ported leaf widget |
| `avatar.rb` | `src/Widgets/Avatar.vala` | `Adw.Avatar`-backed widget: initials fallback, then image once an account loads | `notify::account` or equivalent follow-wiring | ported leaf widget — **new this round** |
| `profile_menu.rb` | `data/ui/menus.ui` (`profile-menu`) | `Gio::Menu` model | menu items | ported |
| `shortcuts_window.rb` | `data/gtk/shortcuts-dialog.ui` | 3 sections, 17 items | accel/action lookups | ported, text axis untranslated |
| `composer.rb` | `src/Dialogs/Composer/Dialog.vala` + `Editor.vala` (spellcheck) + `Attachment.vala` (alt-text) | text box, attach button, alt-text row | libspelling `changed` signal → tag-at-cursor, gexiv2 read on file chosen | heavy partial stand-in — no visibility/CW/poll/schedule/drafts/multi-attachment |
| `preferences_dialog.rb` | `src/Dialogs/Preferences.vala` | General + Notifications pages, switch rows, font-size scale, proxy entry | `Settings.bind`-equivalent two-way binding, debounced scale | ported for the Settings-key-bound rows only — **new this round** |
| `settings.rb` | `src/Services/Settings.vala` + `.gschema.xml` | — | key-change notify | JSON-backed re-implementation, not an installed GSettings schema |
| `style.rb` | `data/style.css` + `eggs/*.css` | — | colour-scheme follow | ported |
| `utils_counting.rb` | `src/Utils/Counting.vala` | — | — | ported (no widget) |
| `utils_date_time.rb` | `src/Utils/DateTime.vala` | — | — | ported (no widget) |
| `utils_tag_extractor.rb` | `src/Utils/TagExtractor.vala` | — | — | ported (no widget) |
| `utils_units.rb` | `src/Utils/Units.vala` | — | — | ported (no widget) |
| `utils_exif.rb` | `src/Utils/Exif.vala` (new, not previously tracked as its own file — backs `composer.rb`'s alt-text read) | — | — | ported (no widget) |

Nothing else in `lib/` corresponds to an upstream file.

## Runtime gate, re-run for this audit

```
nix develop --command xvfb-run -a ruby test/drive_tuba.rb
...
74 of 74 checks passed
DRIVE OK
```

Reproduced live for this round: **74/74, matches the task's stated gate
exactly.** Unlike the previous round (see `.reports/accountability-ensurance.md`'s
history section), this is not a false green this time — it was re-run, not
assumed.

Distinct units exercised by the drive script (counted from its `d.step`
labels): app shell, settings, base view (loading/empty/error/padding/content),
house widgets (VoteCheckButton + ListBoxRowWrapper), avatar, widgetizable,
tabbed view, shortcuts dialog, about dialog, composer (+libspelling+gexiv2),
preferences, profile menu — **12–14 depending how finely "base view" and
"composer" are split**, consistent with the task's "14 components" framing.

**A runtime gate over 12–14 components is not evidence about the other
~132–134 upstream units.** Per the task framing, a component no check
exercises is unverified, not done — and that is the overwhelming majority of
this app: every account/network-driven view, every dialog but two, the real
main window, the whole API/Services layer, and all of `po/`.

## What has no file at all (confirmed absent, not just unticked)

- **The actual window.** `src/Dialogs/MainWindow.vala` — split view, sidebar,
  account switcher — does not exist. `application.rb` substitutes a bare
  content view directly.
- **Every account/network-driven view.** 49 of 52 `src/Views/*` files
  (confirmed: `grep -rl 'class.*View' lib/` only turns up `BaseView`,
  `ContentBaseView`, `TabbedBaseView` themselves — no concrete page).
- **33 of 35 dialogs** (Composer and Preferences are partial stand-ins, not
  full ports; the other 33 have no file at all).
- **55 of 59 widgets** (VoteCheckButton, ListBoxRowWrapper, Avatar,
  Widgetizable are ported; status cards, attachment grids, poll widgets,
  notification rows, admin rows, the audio player, etc. are not).
- **The entire API/data layer.** `src/API/**` (71 files) and
  `src/Services/**` (13 files, incl. account storage and the network/
  streaming client) have zero Ruby counterpart. Nothing in `lib/` makes an
  HTTP request; `application.rb`'s window is fed by a fixture class defined
  in `test/drive_tuba.rb` itself, not live data.
- **Login / multi-account.** No OAuth flow, no account switcher — the thing
  the app is organised around.
- **`po/`.** No directory, no `.pot`, no gettext call site anywhere in
  `lib/` or `exe/` (see `.reports/translation-parity.md`).

## Rule check

The honest statement for this round, same shape as last round: **the port
has built the application shell, a handful of base classes, five leaf
widgets, and two partial dialogs (Composer, Preferences) — nothing else the
shell displays.** Every timeline, post, notification, and the real window
itself remain unported.
