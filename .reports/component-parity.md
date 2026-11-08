# Component parity — Tuba-rb

| | |
|---|---|
| Upstream | `origin/main` @ `3ff8d0c6` |
| Port | `ruby` @ `6e37c565` |
| Units with anything to compare | 12 / ~146 user-facing files |
| Units with full (all-axis) parity | 3 (`list_box_row_wrapper.rb`, `widgetizable.rb`, `profile_menu.rb`) |

Per the `component-parity` skill, parity is claimed per unit, never as an
app-wide total. 134 upstream units have no port file at all and are listed
as flat gaps in `.reports/component-identification.md` rather than padded
into this table.

## Unit: application shell — `src/Application.vala` -> `lib/application.rb`

| Facet | Up | Port | Verdict |
|---|---|---|---|
| Actions | ~20 app actions (about, quit, shortcuts, scroll-page-{up,down}, compose, refresh, search, open-preferences, new-window, toggle-sidebar, switch-account-*, open-account, …) | `about`, `quit`, `shortcuts`, `scroll-page-up`, `scroll-page-down`, plus actions to open the composer and preferences | **gap** — roughly 13 of ~20 app-level actions are still not installed anywhere (`refresh`, `search`, `new-window`, `toggle-sidebar`, `switch-account-*`, `open-account`) |
| About dialog | name, version, developers, artists, translator credits, issue URL | drive check confirms "named and versioned" only | **unverified** on the credits axis |
| Window | real `MainWindow`: split view, sidebar, account switcher | bare content view, no sidebar, no switcher | **gap** |
| Style/startup | `data/style.css` + `eggs/*.css`, colour-scheme setting | ported, drive check passes | parity |

Verdict: **gap.**

## Unit: base view states — `src/Views/Base.vala` -> `lib/base_view.rb`

All four driven checks pass this round (loading, empty, error with
icon/title/message/reload, wide-vs-narrow padding, filled model with
activation, screenshot+clear). The previous round's deterministic
`wide views keep the large-view padding` failure does **not** reproduce on
this commit — re-run twice for this audit, both green.

Verdict: **parity**, for the four states and breakpoint behaviour the drive
script exercises. Not verified: upstream's actual pull-to-refresh / infinite
scroll wiring on top of this base class, since no concrete subclass with
live data exists to exercise it.

## Unit: tabbed view — `src/Views/TabbedBase.vala` -> `lib/tabbed_base_view.rb`

Tab build, stack-replaces-not-just-visual-swap, Alt+1..9 switching, and
rename-propagation all pass. Verdict: **parity** for what's driven.

## Unit: house widgets — `VoteCheckButton.vala`, `ListBoxRowWrapper.vala` -> `lib/vote_check_button.rb`, `lib/list_box_row_wrapper.rb`

Verdict: **parity** (leaf widgets, no external dependents to wire up yet —
upstream's `VoteBox`/`VoteRow` that *use* `VoteCheckButton` are themselves
unported, so this widget has no consumer in the port).

## Unit: avatar — `src/Widgets/Avatar.vala` -> `lib/avatar.rb` (new this round)

| Facet | Up | Port | Verdict |
|---|---|---|---|
| Fallback | shows initials when no account/image | drive check: "Avatar starts on initials" passes | parity |
| Follows account | updates when the bound account changes | drive check: "then follows an account" passes | parity |
| Mini profile popover | `allow_mini_profile` property + `clicked` connects/disconnects `show_mini_profile`, which pops a `Gtk.Popover` built from `Views.Profile.ProfileAccount`, and emits `mini_clicked` | not implemented — no `allow_mini_profile`, no popover, no `mini_clicked` signal in `lib/avatar.rb` | **gap** — honestly disclosed in the port's own header comment |
| Retry-on-network-change | `retry_on_network_changes` re-fetches a failed avatar once `is-online` flips, via a UUID-cache-busted URL | not implemented | **gap**, undisclosed in the port's header (only the disk-cache, mini-profile and accessibility gaps are called out there) |
| Accessibility description | `alternative_text=` calls `update_property(DESCRIPTION, ...)` | left out — port's comment says the Ruby bindings can't marshal that call's argument shape | **gap**, disclosed and explained |
| Disk cache (`Tuba.Helper.Image`) | avatar images cached on disk app-wide | port fetches directly over `Soup::Session` each time, no cache | **gap**, disclosed |

Verdict: **partial.** The two behaviours the drive script exercises
(initials fallback, following an account's avatar URL) are real. Three of
four undriven gaps are disclosed in the port's own file header; the
retry-on-network-change gap is real but not mentioned there, so "every gap
in this file is disclosed" is itself not quite true.

## Unit: shortcuts dialog — `data/gtk/shortcuts-dialog.ui` -> `lib/shortcuts_window.rb`

Structure/count/action-vs-accelerator axes: parity (3 sections, 17 items,
same titles and order, 7 action-backed + 10 literal accelerators preserved).
Text/translation axis: **gap** — every title is a bare string literal; see
`.reports/translation-parity.md`. One failing axis makes the unit a gap per
the skill's rule, even though three of four axes are clean.

## Unit: composer — `src/Dialogs/Composer/Dialog.vala` + `Editor.vala` + `Attachment.vala` -> `lib/composer.rb`

| Facet | Up | Port | Verdict |
|---|---|---|---|
| Text entry + spellcheck | `GtkSource.Buffer` + libspelling, live tagging as you type | plain `Gtk::TextBuffer` + libspelling, `changed` signal wired directly (confirmed by drive checks 21-22, not just a private-method call) | parity for spellcheck specifically |
| Alt-text from image metadata | gexiv2 reads embedded alt text on attach | gexiv2 call confirmed real (drive check 23: reads a real file, handles `file://`, prefills the row) | parity for this one path |
| Visibility picker, content warning, polls, schedule, drafts, multi-attachment carousel, quote policy, language picker, posting itself | full composer surface | none exist | **gap** — this is the overwhelming majority of what `Composer/Dialog.vala` does |

Verdict: **partial, correctly scoped by the port's own header comment** in
`lib/composer.rb`, which lists exactly what's missing. Calling this unit
"ported" without qualification would be false; calling the two wired paths
(spellcheck, alt-text extraction) ported is accurate and is what the drive
script actually verifies.

## Unit: preferences — `src/Dialogs/Preferences.vala` -> `lib/preferences_dialog.rb` (new this round)

| Facet | Up | Port | Verdict |
|---|---|---|---|
| Settings-bound rows (Appearance, Posts, Behavior, Timelines, font-size scale, proxy entry, periodic-update switches, per-event notification mutes, Group switch) | `Settings.bind` to the GSettings schema | same rows, bound to `lib/settings.rb`'s JSON-backed keys; drive checks confirm round-trip binding (switch flips the key and back), scale debounce fires exactly once, notification-mute array mutation is correct | parity for the rows that exist |
| Visibility/language/content-type/quote-policy combo rows | populated from `accounts.active` + Mastodon API | not built — no account layer to source them from | **gap** |
| Filters page | fetched over the network | not built | **gap** |
| UnifiedPush / push subscription | PATCH to the server | not built | **gap** |
| Analytics preview (GtkSource-based) | shown in a page | not built — gemspec doesn't declare gtksourceview5 | **gap** |

Verdict: **partial**, scoped correctly in the port's own file header. The
rows that exist are genuinely wired (not just laid out — the debounce and
mute-array checks prove live two-way binding), but roughly half of
upstream's Preferences window — everything that needs the account/network
layer — is absent.

## Unit: profile menu — `data/ui/menus.ui` (`profile-menu`) -> `lib/profile_menu.rb`

Verdict: **parity** — hinted section plus every item, confirmed by drive
check 32.

## Flat gaps (no port file, not unit-comparable)

134 upstream units: 33 of 35 Dialogs, 49 of 52 Views (including the real
main window), 55 of 59 Widgets, all 71 `API/*` files, all 13 `Services/*`
files, and `po/` (47 languages + the template). Enumerated in full in
`.reports/component-inventory.md` and `.reports/component-identification.md`.

## Verdict

**12 units have something to compare; 3 are full parity, the rest (9) are
partial-with-a-named-gap or outright gap on at least one axis.** 134 units
remain flat gaps (the one file that landed since the last round,
`lib/utils_blurhash.rb`, ports `src/Utils/Blurhash.vala`, which has no
widget and sits outside this report's 146-file Dialogs/Views/Widgets scope —
see `.reports/component-identification.md`). The runtime gate (79/79 this
round, up from 74/74) is real, but it only ever touches ~13–16 units — it is
not evidence for the other ~130+, and the task's framing ("a component no
check exercises is unverified, not done") applies to the bulk of this app.
