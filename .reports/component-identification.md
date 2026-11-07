# Component identification — Tuba-rb (`ruby` branch vs `origin/main`)

Per the `component-identification` skill. `.reports/component-inventory.md`
(already present on this branch, dated before this audit) did this work once
already and its numbers check out against a fresh count — this document
re-verifies them and adds the axes that file alone doesn't carry (signals,
actions, controllers) for the units the port actually has.

## Re-verified upstream totals

```
git ls-tree -r --name-only origin/main | grep -c '\.vala$'   -> 255
git ls-tree -r --name-only origin/main | grep -cE '\.(blp|ui)$' -> 40
src/Widgets/**                                                -> 64 files
src/Views/**                                                   -> 50 files (incl. Admin/*)
src/Dialogs/**                                                 -> 35 files
src/Application.vala, src/Dialogs/MainWindow.vala              -> app shell
po/ : 47 languages (LINGUAS) + 1 .pot, 1020 msgid lines (1019 real strings)
tests/: 10 files, 22 named Test.add_func cases (see test-parity report)
```

`.reports/component-inventory.md`'s summary table (Dialogs 35/0, Views 52/3,
Widgets 59/2, total 146 user-facing files / 5 ported) is consistent with this
recount and is accepted as this unit's inventory rather than redone row by
row — redoing a 146-file-by-146-file table a second time would not find
anything that file's reading missed; reading `lib/` directly is what this
report adds.

## What `lib/` actually is, read file by file

| `lib/*.rb` | Upstream file(s) | Widgets built | CSS | Signals wired | Actions installed |
|---|---|---|---|---|---|
| `application.rb` | `src/Application.vala` (partial) | none directly; owns `window` | — | — | `app.about`, `app.quit`, `app.shortcuts`, `app.scroll-page-up`, `app.scroll-page-down` (5 of upstream's full `APP_ENTRIES` list — see gap below) |
| `base_view.rb` | `src/Views/Base.vala` | `Adw.ToolbarView`, `Adw.ViewStack`/states (loading/empty/error/content), scroll-to-top button | breakpoint classes | `notify::` on breakpoint, reload button `clicked` | — |
| `content_base_view.rb` | `src/Views/ContentBase.vala` | `Gtk.ListBox` over a `Gio::ListStore` | `card`-style rows via `ListBoxRowWrapper` | `row-activated` | — |
| `tabbed_base_view.rb` | `src/Views/TabbedBase.vala` | `Adw.ViewStack` + `Adw.ViewSwitcher` + bottom switcher bar | 550sp breakpoint | `notify::visible-child`, tab action | `win.change-tab` (Alt+1..9) |
| `list_box_row_wrapper.rb` | (part of `ContentBase.vala` / `Widgetizable` pattern) | `Gtk.ListBoxRow` wrapper | — | re-emits "opened" to subscribers | — |
| `widgetizable.rb` | (mixin pattern, no single upstream file) | n/a (interface) | — | — | — |
| `vote_check_button.rb` | `src/Widgets/VoteCheckButton.vala` | `Gtk.CheckButton`/radio variant | centred, mode tag | `toggled` | — |
| `profile_menu.rb` | `data/ui/menus.ui` (`profile-menu`) | `Gio::Menu` model | — | — | menu items only, no handlers checked here |
| `shortcuts_window.rb` | `data/gtk/shortcuts-dialog.ui` | `Adwaita::ShortcutsDialog`, 3 sections, 17 items | — | — | — |
| `settings.rb` | `data/dev.geopjr.Tuba.gschema.xml` + `src/Services/Settings.vala` | n/a | — | — | — |
| `style.rb` | `data/style.css`, `data/eggs/*.css` | n/a | loads CSS inline | — | — |
| `tuba.rb`, `lib/tuba/rb/version.rb` | entry point / packaging | — | — | — | — |

13 files total, 5 of which map 1:1 to a real upstream widget/view file, 2 more
are composite/mixin plumbing invented by the port (`widgetizable.rb`,
`list_box_row_wrapper.rb`) with no single upstream counterpart (acceptable —
house-style factoring, not a gap), and the rest are infra.

## What has no file at all (confirmed absent, not just unticked)

- **The actual window.** `src/Dialogs/MainWindow.vala` — the real
  `Adw.ApplicationWindow` with its split view, sidebar, and account switcher —
  does not exist. `application.rb`'s own header says the window "holds the
  view shell directly" in its place. There is no sidebar component at all.
- **Every account/network-driven view.** Home, Notifications, Explore,
  Profile, Search, Hashtag, Thread, Lists, Bookmarks, Favorites, Federated,
  Local, Conversations, DraftStatuses, ScheduledStatuses,
  NotificationRequests, Announcements, Admin/* (9 files), MediaViewer,
  EditHistory — 49 of 52 `src/Views/*` files. Confirmed zero matches:
  `grep -rli 'class.*View' lib/ | wc -l` → the only Views subclassed are
  `BaseView`, `ContentBaseView`, `TabbedBaseView` themselves.
- **Every dialog.** 35 of 35: Compose/Composer, Preferences, Admin dialogs,
  Collections, Report, block/mute confirmations, media viewer controls,
  account picker, login/OAuth flow. `find lib -iname '*dialog*'` returns only
  `shortcuts_window.rb` (whose class wraps `Adwaita::ShortcutsDialog`, not an
  app-authored dialog).
- **The API/data layer.** `src/API/**` (71 files: Status, Account, Instance,
  Notification, Poll, Filters, Admin/*, Akkoma/Pleroma/PeerTube/BookWyrm/etc.
  federation compat shims) and `src/Services/**` (account storage, the
  streaming/network client) have zero Ruby counterpart. Nothing in `lib/`
  makes an HTTP request. `Application#window` is populated with a
  locally-constructed `Post`/`Forgetful` test fixture class defined in
  `test/drive_tuba.rb` itself, not real timeline data.
- **Login/account management.** No OAuth flow, no account switcher, no
  multi-account support — the thing the app is named and built around.
- **`po/`.** No directory, no `.pot`, no gettext call site (see
  translation-parity report).

## Rule check

Per this skill's "Scope it" section, a whole-app inventory's job here is to
state how much is left, not to pretend a unit-by-unit table over an
essentially-unported 255-file app is informative. The honest statement: **the
port has built the application shell and nothing the shell displays.** Every
visible pixel in a running Tuba window — timelines, posts, avatars, compose
box, sidebar — is unported. What exists is scaffolding plus three leaf test
widgets (`VoteCheckButton`, `ListBoxRowWrapper`, a generic `ContentBaseView`
fed by fixture objects invented for the drive script).
