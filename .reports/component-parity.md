# Component parity — Tuba-rb

| | |
|---|---|
| Upstream | `origin/main` @ `3ff8d0c6` (fix(ci): android apt (#1791)) |
| Port | `ruby` @ `b67c1339` |
| Units with parity | 8 / ~140 |

**Runtime gate correction.** The task that commissioned this round of reports
asserted `drive_ok=true, 53 checks passed, 0 failed`. Re-running
`test/drive_tuba.rb` under the dev shell for this audit, twice, gives:
`52 of 53 checks passed`, `failed check: wide views keep the large-view
padding`, `DRIVE FAILED (1)`. That failure is folded into the "base view
states" unit below — it was previously reported clean and is not. See
`.reports/accountability-ensurance.md` for this treated as the false-green
finding it is.

Per the `component-parity` skill, parity is claimed **per unit**, never as an
app-wide total. The units below are the only ones with anything on the port
side to compare at all; every other upstream unit (49 Views, 35 Dialogs, 57
Widgets — see `.reports/component-identification.md`) has no port file and is
therefore not a unit with partial parity, it is a flat gap, listed in its own
section rather than padded into the table.

## Unit: application shell — `src/Application.vala` -> `lib/application.rb`

| Facet | Up | Port | Verdict |
|---|---|---|---|
| Actions | `APP_ENTRIES` installs ~20 (about, quit, shortcuts, scroll-page-{up,down}, compose, refresh, search, open-preferences, new-window, toggle-sidebar, switch-account-*, open-account, …) | 5 installed: `about`, `quit`, `shortcuts`, `scroll-page-up`, `scroll-page-down` | **gap**: ~15 of upstream's app-level actions have no action installed anywhere in the port — `compose`, `refresh`, `search`, `open-preferences` are all referenced from the port's own `shortcuts_window.rb` accelerator table as `app.compose`, `app.search`, `app.refresh`, `app.open-preferences`, with no matching `add_action`/`install_action` in `application.rb`. The shortcuts dialog advertises keys that fire nothing. |
| Accelerators | one per action above | bound only for the 5 ported actions | same gap, one level down |
| About dialog | populated: name, version, developers, artists, translators credits, issue URL | `app: about dialog: opens … populated` check passes, but only verifies "named and versioned" — translator/artist credit lists not compared | **unverified**, not confirmed clean |
| Window | `Dialogs.MainWindow`: split view, sidebar, account switcher | `ContentBaseView` fed by fixture data, no sidebar, no split view, no account switcher | **gap** |
| Style/startup | loads `data/style.css` + `eggs/*.css`, applies colour-scheme setting | `lib/style.rb` loads CSS inline, colour-scheme driven from `settings.rb` | parity (driven check passes: "color scheme maps to Adwaita" / "follows the key") |

Verdict: **gap**. The driven checks that exist all pass, but they check 5 of
~20 actions. "The app's actions are installed" is not true of this unit; "5
specific actions are installed and wired" is.

## Unit: shortcuts dialog — `data/gtk/shortcuts-dialog.ui` -> `lib/shortcuts_window.rb`

| Facet | Up | Port | Verdict |
|---|---|---|---|
| Sections | 3: General, Composer, Media Viewer | 3, same titles, same order | parity |
| Items | General 11, Composer 1, Media Viewer 5 (counted from the `.ui`) = 17 | same 17 titles/accelerators transcribed | parity (count, order) |
| Text | every title has `translatable="yes"` upstream, several carry `context="shortcut window"` | every title is a bare Ruby string literal, no `_()`/gettext call anywhere in the file | **gap** — text axis fails; see translation-parity report |
| Action-vs-accelerator split | 7 items reference an action name (looked up for its accel), 10 carry a literal accelerator | same split preserved, `shortcut.action_name =` for the 7 | parity (behaviour) |

Verdict: **gap** (text axis only — the widget/structure axes are clean, the
translation axis is not, and one failing axis is a gap per the skill's rule).

## Unit: base view states — `src/Views/Base.vala` -> `lib/base_view.rb`

Loading / empty / error / content states, breakpoint padding, scroll-to-top:
three of four driven checks pass (`shows the empty state`, `shows the error
title, message and icon`, `shows the reload button`, `narrow views drop it`).
The fourth, `wide views keep the large-view padding`, **fails** on a clean,
twice-reproduced run of `test/drive_tuba.rb` on this commit — see the gate
correction above. The port builds the `large-view` CSS class and the breakpoint
that should add it for narrow views, but the wide-view case that should carry
it does not, which is a real behavioural regression in the one file this unit
tests, not a flake.

Verdict: **gap**. Previously reported as parity on the strength of a drive run
that has since been shown not to reproduce; re-verify after a fix lands, do
not take a future green run on faith without re-running it for this report.

## Unit: tabbed view — `src/Views/TabbedBase.vala` -> `lib/tabbed_base_view.rb`

Stack/switcher wiring, Alt+1..9, tab renaming: all driven checks pass. One
named, in-file gap: `lib/tabbed_base_view.rb:21` — "Upstream's
`add_timeline_tab` … is not here: that view is not ported yet." This is an
honest row (see accountability-ensurance report) but is still a gap: the
factory that builds the one tab type Tuba actually opens by default
(`Views.Accounts`) does not exist.

Verdict: **parity** for the mechanism, **gap** for the one concrete tab type
upstream wires through it.

## Unit: profile menu — `data/ui/menus.ui` (`profile-menu`) -> `lib/profile_menu.rb`

Driven check passes ("profile menu: the hinted section plus every item").
Not independently verified here whether the menu's item *actions* (e.g.
`account.open-in-browser`, `account.copy-link`) exist anywhere upstream's
account action group would install them — the account action group itself
is unported (no `src/Services/*` account layer), so these menu items are
**decorative**: present in the model, firing actions nothing installs.

Verdict: **gap** (the menu widget has parity; the actions it targets do not
exist, so the menu is non-functional).

## Unit: `VoteCheckButton` — `src/Widgets/VoteCheckButton.vala` -> `lib/vote_check_button.rb`

Driven checks pass (centring, mode tag). No upstream poll-voting flow exists
to consume it (`Views/Thread`, the poll-display widget that embeds it, and
the vote-submission API call are all unported), so the component itself has
parity in isolation but is unreachable from any real screen in the app.

Verdict: **parity** (isolated unit only).

## Unit: `Avatar` — `src/Widgets/Avatar.vala` -> `lib/avatar.rb`

| Facet | Up | Port | Verdict |
|---|---|---|---|
| Widget | `Gtk.Button` (flat, circular) wrapping `Adw.Avatar` | same | parity |
| CSS | `flat`, `circular` | `flat`, `circular` (driven check: "it is a flat circular image button") | parity |
| Image fetch | `Tuba.Helper.Image`, an app-wide disk cache | direct `Soup::Session` fetch, no cache | **gap** — in-file admission, named with upstream file:line, not excused |
| Mini profile popover | `#allow_mini_profile` pops `Views.Profile.ProfileAccount`, emits `mini_clicked` on click | not built; no signal connected at all (confirmed: `grep -n 'signal\|connect' lib/avatar.rb` finds none) | **gap** — no click behaviour of any kind on this button, upstream or otherwise |
| Accessible description | `#alternative_text=` sets an accessibility-description property | left out (binding cannot marshal the array-of-enum argument; documented in-file with the exact GIArgument error) | **gap**, real binding limit — recorded here and belongs in `FINDINGS.md`, not just this file's comment |

Verdict: **parity** for the widget/CSS axes driven by the test; **gap** on
behaviour (the button does nothing when clicked — upstream's whole point of
wrapping a `Gtk.Button` around the avatar is the click) and on the
accessibility axis. Isolated unit: no `Views::Profile`, no account-data
source, nothing in the app actually constructs an `Avatar` with a live
account yet (`grep -rn 'Avatar.new' lib/ exe/` finds only the drive script's
fixture).

## Flat gaps — no port file, not a partial unit

- **35 / 35 Dialogs** — Compose, Preferences, Login/OAuth, Collections, Report,
  Admin (6 files), block/mute confirmations, media viewer, account picker.
- **49 / 52 Views** — every account-data-driven screen: Home, Notifications,
  Explore, Profile, Search, Hashtag(s), Thread, Lists, Bookmarks, Favorites,
  Federated, Local, Conversations, DraftStatuses, ScheduledStatuses,
  NotificationRequests(List), Announcements, Admin/* (9 files), MediaViewer,
  EditHistory, Browser, Link, Collections, Sidebar, StatusStats, Main.
- **57 / 59 Widgets** — everything that renders a post: the status/card
  widget, avatar, attachment box, poll widget, composer box, emoji picker,
  reaction row, account row, notification row, and so on.
- **The window itself** — `Dialogs/MainWindow.vala`, including the sidebar
  that is Tuba's primary navigation surface.
- **The entire API/network layer** backing every one of the above — no HTTP
  client, no entity models, no account storage.

## Rules check

No empty-state or error-state claim is made for a view that doesn't exist.
No CSS stylesheet diff was run — `data/style.css` vs the port's inline
`lib/style.rb` — because the 141 missing files' classes are the overwhelming
majority of what that diff would report, and a stylesheet diff against an
unbuilt UI is not informative; it is deferred to when there is a UI to diff.
That deferral is itself a gap in this report's coverage and is stated here
rather than silently skipped.
