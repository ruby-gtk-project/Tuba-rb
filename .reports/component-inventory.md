# Tuba — upstream component inventory

Survey of `origin/main` (Vala + GtkBuilder) against `lib/` on the `ruby`
branch. Produced with the `component-identification` skill: the declarative
`.ui` files read first, then every `src/Views`, `src/Widgets`, `src/Dialogs`
file classified by its primary class and its template, then the scanner over
both trees for the totals.

This is the **opening survey of a fresh fork**, so it is a map of how much app
there is, not a per-widget table. Per-component widget/CSS/signal/action rows
belong to the per-unit `component-parity` passes and are deliberately not here.

## How much app there is

Rescanned at the head of `ruby` (`component-scan.sh` over `origin/main` and
over `lib/`):

| | upstream (`src/` + `data/`) | port (`lib/` on `ruby`) |
|---|---:|---:|
| widget rows | 2135 (110 distinct types) | 33 (24 distinct) |
| controllers/gestures | 64 (12 distinct) | 1 (1 distinct) |
| CSS classes applied | 389 (132 distinct) | 17 (14 distinct) |
| signals connected | 638 (155 distinct) | 14 (10 distinct) |
| GAction names seen by the scan | 34 (20 distinct) | 1 |
| component files | 146 Vala + 40 `.ui` | 10 `lib/*.rb` |
| GSettings keys | 58 | 58 (`lib/settings.rb`) |
| translated source files (`po/POTFILES`) | 158, 46 locales | 0 |

The upstream column is unchanged from the first pass; the port column has
moved, because the view shell landed in `ef45222`.

### What exists on `ruby` now

Ten files, none of them a user-facing page — they are the shell every page
will sit in, plus the two mixins and the two non-widget services:

| `lib/*.rb` | Upstream | What it covers |
|---|---|---|
| `application.rb` | `src/Application.vala` | app id, about dialog, 5 of the 29 actions (`about`, `shortcuts`, `quit`, `scroll-page-{down,up}`) and their accels. Window is a plain `Gtk::ApplicationWindow` holding a bare `ContentBaseView`, standing in for `MainWindow` |
| `base_view.rb` | `src/Views/Base.vala` + `data/ui/views/base.ui` | header bar, clamped scrolled content, scroll-to-top button, loading/empty/error status pages |
| `content_base_view.rb` | `src/Views/ContentBase.vala` | model-bound `Gtk::ListBox` content (upstream's non-`USE_LISTVIEW` branch) |
| `tabbed_base_view.rb` | `src/Views/TabbedBase.vala` | view-switcher stack, switcher bar on narrow |
| `shortcuts_window.rb` | `data/gtk/shortcuts-dialog.ui` | the three shortcut sections, verbatim |
| `profile_menu.rb` | `data/ui/menus.ui` (`profile-menu`) | the profile header menu model |
| `style.rb` | `data/style.css`, `data/eggs/{6,7}.css` | the stylesheet, inline instead of via GResource |
| `settings.rb` | `data/dev.geopjr.Tuba.gschema.xml` + `src/Services/Settings.vala` | all 58 keys, global and per-account |
| `widgetizable.rb` | `src/Widgets/Widgetizable.vala` | the model-to-row mixin |
| `list_box_row_wrapper.rb` | `src/Widgets/ListBoxRowWrapper.vala` | the row that can report being opened |

Everything else in the inventory below is still unported. The `copy-menu` half
of `data/ui/menus.ui` is not in `profile_menu.rb` and needs a home.

## Naming rule used for the target paths

The pilot (`gnome-contacts-rb`) keeps one flat `lib/<thing>.rb` per upstream
source file. Tuba has 146 component files across four namespaces with
colliding leaf names (`Views/Accounts`, `Widgets/Admin/AccountRow`,
`Dialogs/Admin/Report` vs `Widgets/Admin/Report`), so the flat name carries the
namespace:

- `src/Views/X.vala` → `lib/x_view.rb`
- `src/Views/Admin/Pages/X.vala` → `lib/admin_x_page.rb`
- `src/Views/Admin/Timelines/X.vala` → `lib/admin_x_timeline.rb`
- `src/Dialogs/X.vala` → `lib/x_dialog.rb`
- `src/Dialogs/<Group>/X.vala` → `lib/<group>_x.rb`
- `src/Widgets/X.vala` → `lib/x.rb`
- `src/Widgets/<Group>/X.vala` → `lib/<group>_x.rb`

A `.ui` template merges into the Ruby file of the class that declares it — the
component is the *set* of files, and the port has no `.ui` by design.

## Window and shell

| Upstream | → | Kind | Exists |
|---|---|---|---|
| `src/Application.vala` | `lib/application.rb` | application (actions, accels, about) | partial — actions 5/29, about dialog, no `MainWindow` |
| `src/Dialogs/MainWindow.vala` + `data/ui/dialogs/main.ui` | `lib/main_window.rb` | window (`Adw.ApplicationWindow` → `AdwOverlaySplitView` + `AdwNavigationView` + `AdwToastOverlay` + breakpoint) | no |
| `src/Views/Sidebar.vala` + `data/ui/views/sidebar/view.ui` | `lib/sidebar_view.rb` | sidebar | no |
| `data/ui/views/sidebar/item.ui` (`ItemRow`) | `lib/sidebar_view.rb` | row (nested class) | no |
| `data/ui/views/sidebar/account.ui` (`AccountRow`) | `lib/sidebar_view.rb` | row (nested class) | no |
| `src/Views/Main.vala` | `lib/main_view.rb` | tabbed root view (Home / Notifications / Conversations) | no |
| `src/Views/Base.vala` + `data/ui/views/base.ui` | `lib/base_view.rb` | base view (header, empty state, error state, `StatusMessage`) | yes |
| `src/Views/ContentBase.vala` | `lib/content_base_view.rb` | base view | yes |
| `src/Views/TabbedBase.vala` | `lib/tabbed_base_view.rb` | base view | yes |
| `src/Views/Timeline.vala` | `lib/timeline_view.rb` | base view (paging, streaming) | no |
| `data/gtk/shortcuts-dialog.ui` | `lib/shortcuts_window.rb` | keyboard shortcuts dialog (no backing source file) | yes |
| `data/ui/menus.ui` (`profile-menu`, `copy-menu`) | `lib/profile_menu.rb` | menu model | partial — `profile-menu` only |
| `data/style.css`, `data/eggs/6.css`, `data/eggs/7.css` | `lib/style.rb` | stylesheet (132 distinct classes) | yes |
| `data/dev.geopjr.Tuba.gschema.xml` + `src/Services/Settings.vala` | `lib/settings.rb` | GSettings (58 keys) | yes |
| `src/Services/Accounts/Places.vala`, `.../Mastodon/Account.vala` | `lib/place.rb` | sidebar place model + the 13 built-in places | no |

### Sidebar places (built-in, from `Services/Accounts/Mastodon/Account.vala`)

Home, Notifications, Conversations, Bookmarks, Favorites, Lists, Search,
Explore, Local, Bubble, Federated, Hashtags, Drive — plus runtime repeaters for
favourite hashtags and favourite lists, and the account switcher rows with
"Add Account" and a destructive "Forget …" alert.

### Sidebar menu (built in source, not in a `.ui`)

Account submenu: New Post, Open Profile, Refresh. Misc submenu: Announcements,
Follow Requests, Mutes & Blocks, Draft Posts, Scheduled Posts, Collections,
#FediWrapped, Admin Dashboard, Preferences, Keyboard Shortcuts, About, Quit.

## Actions and accelerators (`src/Application.vala`)

29 `app.*` entries: `about`, `compose`, `back`, `refresh`, `search`, `quit`,
`back-home`, `scroll-page-down`, `scroll-page-up`, `goto-notifications`,
`open-status-url` (`s`), `answer-follow-request` (`(ssb)`), `follow-back`
(`(ss)`), `reply-to-status-uri` (`(ss)`), `remove-from-followers` (`(ss)`),
`open-preferences`, `open-current-account-profile`, `open-announcements`,
`open-follow-requests`, `open-mutes-blocks`, `open-scheduled-posts`,
`open-draft-posts`, `open-admin-dashboard`, `open-last-fediwrapped`,
`open-collections`, `open-containing-folder` (`s`), `increase-font-size`,
`decrease-font-size`, `reset-font-size`, plus `dev-only-window` on devel
builds.

Accelerators: `F1` about, `F2` dev window, `<Ctrl>comma` preferences,
`<Ctrl>T`/`<Ctrl>N` compose, `<Alt>BackSpace`/`<Alt>KP_Left` back,
`<Ctrl>R`/`F5` refresh, `<Ctrl>F`/`<Ctrl>L` search, `<Ctrl>Q` quit,
`<Ctrl>W` window.close, `<Alt>Home` back-home, `Page_Down`/`Page_Up` scroll.
The shortcuts dialog additionally documents `<Ctrl>Return`, `F11`,
`<Ctrl>plus`/`<Ctrl>equal`, `<Ctrl>minus`/`<Ctrl>underscore`,
`Left`/`KP_Left`, `Right`/`KP_Right`, `<Alt>Left`/`Escape`, and `app.shortcuts`
— which `Application.vala` does **not** install, so it is either an upstream
gap or installed by GTK; check before porting.

Command line: `--hidden`, `--unifiedpush-bg`.

## Views (47 files; `Base`, `ContentBase`, `TabbedBase`, `Main`, `Sidebar` and `Timeline` are in **Window and shell** above)

| Upstream | → | Kind | Exists |
|---|---|---|---|
| `src/Views/Home.vala` | `lib/home_view.rb` | timeline page (+ account suggestions) | no |
| `src/Views/Notifications.vala` | `lib/notifications_view.rb` | timeline page (streaming, filters) | no |
| `src/Views/Conversations.vala` | `lib/conversations_view.rb` | timeline page | no |
| `src/Views/Bookmarks.vala` | `lib/bookmarks_view.rb` | timeline page | no |
| `src/Views/Favorites.vala` | `lib/favorites_view.rb` | timeline page | no |
| `src/Views/Local.vala` | `lib/local_view.rb` | timeline page | no |
| `src/Views/Federated.vala` | `lib/federated_view.rb` | timeline page | no |
| `src/Views/Bubble.vala` | `lib/bubble_view.rb` | timeline page | no |
| `src/Views/Explore.vala` | `lib/explore_view.rb` | tabbed page | no |
| `src/Views/Search.vala` | `lib/search_view.rb` | tabbed page (+ `SearchEntry`, history rows) | no |
| `data/ui/dialogs/advanced_search.ui` (`AdvancedSearchDialog` in `Search.vala`) | `lib/advanced_search_dialog.rb` | dialog | no |
| `src/Views/Hashtag.vala` | `lib/hashtag_view.rb` | timeline page | no |
| `src/Views/Hashtags.vala` | `lib/hashtags_view.rb` | timeline page (+ favourite-tag button) | no |
| `src/Views/Lists.vala` | `lib/lists_view.rb` | timeline page (+ `Row`) | no |
| `src/Views/List.vala` | `lib/list_view.rb` | timeline page | no |
| `src/Views/Thread.vala` | `lib/thread_view.rb` | content page | no |
| `src/Views/Profile.vala` | `lib/profile_view.rb` | page (+ `NoteEditor` dialog, filter group, error row) | no |
| `src/Views/Accounts.vala` | `lib/accounts_view.rb` | timeline page | no |
| `src/Views/FollowRequests.vala` | `lib/follow_requests_view.rb` | timeline page | no |
| `src/Views/NotificationRequests.vala` | `lib/notification_requests_view.rb` | timeline page | no |
| `src/Views/NotificationRequestsList.vala` | `lib/notification_requests_list_view.rb` | timeline page | no |
| `src/Views/MutesBlocks.vala` | `lib/mutes_blocks_view.rb` | tabbed page | no |
| `src/Views/Announcements.vala` | `lib/announcements_view.rb` | timeline page | no |
| `src/Views/Collections.vala` | `lib/collections_view.rb` | tabbed page | no |
| `src/Views/ScheduledStatuses.vala` | `lib/scheduled_statuses_view.rb` | timeline page | no |
| `src/Views/DraftStatuses.vala` | `lib/draft_statuses_view.rb` | timeline page | no |
| `src/Views/EditHistory.vala` | `lib/edit_history_view.rb` | timeline page | no |
| `src/Views/StatusStats.vala` | `lib/status_stats_view.rb` | tabbed page | no |
| `src/Views/Link.vala` | `lib/link_view.rb` | timeline page | no |
| `src/Views/Drive.vala` | `lib/drive_view.rb` | page (+ `ItemWidget`, `EntryPopover`) | no |
| `src/Views/Browser.vala` | `lib/browser_view.rb` | dialog (in-app browser + its own header bar) | no |
| `src/Views/MediaViewer.vala` + `data/ui/views/media_viewer.ui` | `lib/media_viewer.rb` | full-screen viewer (+ `Item`) | no |
| `src/Views/Admin/Pages/Base.vala` | `lib/admin_base_page.rb` | base page | no |
| `src/Views/Admin/Pages/Dashboard.vala` | `lib/admin_dashboard_page.rb` | page | no |
| `src/Views/Admin/Pages/Accounts.vala` | `lib/admin_accounts_page.rb` | page (+ `AccountDialog`, `UndoRow`) | no |
| `src/Views/Admin/Pages/Reports.vala` | `lib/admin_reports_page.rb` | page | no |
| `src/Views/Admin/Pages/BlockedEmails.vala` | `lib/admin_blocked_emails_page.rb` | page | no |
| `src/Views/Admin/Pages/BlockedIPs.vala` | `lib/admin_blocked_ips_page.rb` | page | no |
| `src/Views/Admin/Pages/FederationAllowlist.vala` | `lib/admin_federation_allowlist_page.rb` | page | no |
| `src/Views/Admin/Pages/FederationBlocklist.vala` | `lib/admin_federation_blocklist_page.rb` | page | no |
| `src/Views/Admin/Timelines/PaginationTimeline.vala` | `lib/admin_pagination_timeline.rb` | base timeline | no |
| `src/Views/Admin/Timelines/Accounts.vala` | `lib/admin_accounts_timeline.rb` | timeline | no |
| `src/Views/Admin/Timelines/Reports.vala` | `lib/admin_reports_timeline.rb` | timeline | no |
| `src/Views/Admin/Timelines/BlockedIPs.vala` | `lib/admin_blocked_ips_timeline.rb` | timeline | no |
| `src/Views/Admin/Timelines/DomainAllow.vala` | `lib/admin_domain_allow_timeline.rb` | timeline | no |
| `src/Views/Admin/Timelines/DomainBlock.vala` | `lib/admin_domain_block_timeline.rb` | timeline | no |
| `src/Views/Admin/Timelines/EmailDomain.vala` | `lib/admin_email_domain_timeline.rb` | timeline | no |

## Dialogs (34 files; `MainWindow` is in **Window and shell** above)

| Upstream | → | Kind | Exists |
|---|---|---|---|
| `src/Dialogs/Composer/Dialog.vala` + `data/ui/dialogs/composer.ui` | `lib/composer_dialog.rb` | dialog (+ `PostButton`, `QuotationPolicy`) | no |
| `src/Dialogs/Composer/Editor.vala` | `lib/composer_editor.rb` | editor widget (+ `PlaceholderHack`) | no |
| `src/Dialogs/Composer/Attachable.vala` | `lib/composer_attachable.rb` | interface/mixin | no |
| `src/Dialogs/Composer/Attachment.vala` | `lib/composer_attachment.rb` | widget (+ `AltIndicator`, thumbnailer) | no |
| `src/Dialogs/Composer/AttachmentsBin.vala` | `lib/composer_attachments_bin.rb` | widget (+ alt-text `Editor` page) | no |
| `src/Dialogs/Composer/Polls.vala` | `lib/composer_polls.rb` | widget (+ `PollRow`, `Expiration`, `StatefulButton`) | no |
| `src/Dialogs/Composer/DropOverlay.vala` | `lib/composer_drop_overlay.rb` | overlay | no |
| `src/Dialogs/Composer/PreferredSizeBin.vala` | `lib/composer_preferred_size_bin.rb` | interface/mixin | no |
| `src/Dialogs/Composer/Drafts.vala` | `lib/composer_drafts.rb` | navigation page | no |
| `src/Dialogs/Composer/Schedule.vala` + `data/ui/dialogs/schedule.ui` | `lib/composer_schedule.rb` | navigation page | no |
| `src/Dialogs/Composer/Completion/CompletionProvider.vala` | `lib/composer_completion_provider.rb` | completion provider | no |
| `src/Dialogs/Composer/Completion/EmojiProvider.vala` | `lib/composer_completion_emoji_provider.rb` | completion provider | no |
| `src/Dialogs/Composer/Completion/HandleProvider.vala` | `lib/composer_completion_handle_provider.rb` | completion provider | no |
| `src/Dialogs/Composer/Completion/HashtagProvider.vala` | `lib/composer_completion_hashtag_provider.rb` | completion provider | no |
| `src/Dialogs/Preferences.vala` + `data/ui/dialogs/preferences.ui` | `lib/preferences_dialog.rb` | preferences (+ `FilterRow`, `QuotationPolicy`, `AnalyticsDialog`) | no |
| `src/Dialogs/NotificationSettings.vala` + `data/ui/dialogs/notification_settings.ui` | `lib/notification_settings_dialog.rb` | dialog (+ `NotificationRow`) | no |
| `src/Dialogs/NewAccount.vala` + `data/ui/dialogs/new_account.ui` | `lib/new_account_dialog.rb` | window (+ `SettingsDialog`) | no |
| `src/Dialogs/ProfileEdit.vala` + `data/ui/dialogs/profile_edit.ui` | `lib/profile_edit_dialog.rb` | dialog (+ `Field`) | no |
| `src/Dialogs/ProfileLists.vala` | `lib/profile_lists_dialog.rb` | dialog (+ `ARRow`) | no |
| `src/Dialogs/ListEdit.vala` + `data/ui/dialogs/list_edit.ui` | `lib/list_edit_dialog.rb` | dialog (+ `MemberCheckButton`) | no |
| `src/Dialogs/FilterEdit.vala` + `data/ui/dialogs/filter_edit.ui` | `lib/filter_edit_dialog.rb` | navigation page (+ `KeywordRow`) | no |
| `src/Dialogs/HashtagList.vala` | `lib/hashtag_list_dialog.rb` | dialog (+ `HashtagSearch` popover, `HashtagGroup`, `TagRow`) | no |
| `src/Dialogs/Collection.vala` | `lib/collection_dialog.rb` | dialog | no |
| `src/Dialogs/Collections.vala` | `lib/collections_dialog.rb` | preferences dialog | no |
| `src/Dialogs/Report.vala` | `lib/report_dialog.rb` | dialog (+ `StatusRow`) | no |
| `src/Dialogs/AnnualReport.vala` | `lib/annual_report_dialog.rb` | dialog (#FediWrapped, + `PostButton`) | no |
| `src/Dialogs/DevConsole.vala` | `lib/dev_console_dialog.rb` | dialog (devel only, + `WindowSize`) | no |
| `src/Dialogs/Saveable.vala` | `lib/saveable.rb` | interface/mixin (close-confirmation) | no |
| `src/Dialogs/Admin.vala` + `data/ui/dialogs/admin_dashboard.ui` | `lib/admin_dialog.rb` | window (+ `Place`) | no |
| `src/Dialogs/Admin/Base.vala` | `lib/admin_dialog_base.rb` | base dialog | no |
| `src/Dialogs/Admin/AddFederationBlock.vala` | `lib/admin_add_federation_block_dialog.rb` | dialog | no |
| `src/Dialogs/Admin/AddIPBlock.vala` | `lib/admin_add_ip_block_dialog.rb` | dialog | no |
| `src/Dialogs/Admin/Report.vala` | `lib/admin_report_dialog.rb` | dialog | no |
| `src/Dialogs/Admin/TakeAction.vala` | `lib/admin_take_action_dialog.rb` | dialog | no |

## Widgets (59 files; `ListBoxRowWrapper` and `Widgetizable` are the two already ported)

| Upstream | → | Kind | Exists |
|---|---|---|---|
| `src/Widgets/Status.vala` + `data/ui/widgets/status.ui` | `lib/status.rb` | the post card — the app's central widget | no |
| `src/Widgets/Status/ActionsRow.vala` | `lib/status_actions_row.rb` | row (reply/boost/favourite/bookmark/more) | no |
| `src/Widgets/Status/ReactionsRow.vala` | `lib/status_reactions_row.rb` | row | no |
| `src/Widgets/Status/FollowRequestRow.vala` | `lib/status_follow_request_row.rb` | row | no |
| `src/Widgets/StatusActionButton.vala` | `lib/status_action_button.rb` | button | no |
| `src/Widgets/Notification.vala` | `lib/notification.rb` | row (subclasses `Status`) | no |
| `src/Widgets/GroupedNotification.vala` | `lib/grouped_notification.rb` | row | no |
| `src/Widgets/NotificationRequest.vala` | `lib/notification_request.rb` | row | no |
| `src/Widgets/Conversation.vala` | `lib/conversation.rb` | row | no |
| `src/Widgets/ScheduledStatus.vala` | `lib/scheduled_status.rb` | row (+ `RescheduleDialog`) | no |
| `src/Widgets/Account.vala` + `data/ui/widgets/profile.ui` | `lib/account.rb` | row (+ `RelationshipButton`) | no |
| `src/Widgets/AccountRow.vala` | `lib/account_row.rb` | row | no |
| `src/Widgets/AccountSuggestions.vala` | `lib/account_suggestions.rb` | row (+ `AccountSuggestion`) | no |
| `src/Widgets/ProfileCover.vala` + `data/ui/views/profile_header.ui` | `lib/profile_cover.rb` | profile header (+ `MutualsButtonContent`, `ProfileStatsButton`) | no |
| `src/Widgets/ProfileFilterGroup.vala` | `lib/profile_filter_group.rb` | row | no |
| `src/Widgets/RelationshipButton.vala` | `lib/relationship_button.rb` | button | no |
| `src/Widgets/Avatar.vala` | `lib/avatar.rb` | button | no |
| `src/Widgets/Background.vala` | `lib/background.rb` | button | no |
| `src/Widgets/Announcement.vala` + `data/ui/widgets/announcement.ui` | `lib/announcement.rb` | row | no |
| `src/Widgets/Collection.vala` | `lib/collection.rb` | row (+ `Avatars`) | no |
| `src/Widgets/Tag.vala` | `lib/tag.rb` | row | no |
| `src/Widgets/HashtagBar.vala` | `lib/hashtag_bar.rb` | bin (+ `HashtagButton`) | no |
| `src/Widgets/VoteBox.vala` + `data/ui/widgets/votebox.ui` | `lib/vote_box.rb` | poll box | no |
| `src/Widgets/VoteRow.vala` | `lib/vote_row.rb` | row | no |
| `src/Widgets/VoteCheckButton.vala` | `lib/vote_check_button.rb` | check button | no |
| `src/Widgets/PreviewCard.vala` + `data/ui/widgets/preview_card.ui` | `lib/preview_card.rb` | card (+ `AuthorRow`) | no |
| `src/Widgets/PreviewCardExplore.vala` + `data/ui/widgets/preview_card_explore.ui` | `lib/preview_card_explore.rb` | row | no |
| `src/Widgets/PreviewCardInternal.vala` + `data/ui/widgets/preview_card_internal.ui` | `lib/preview_card_internal.rb` | card | no |
| `src/Widgets/BookWyrmPage.vala` + `data/ui/widgets/bookwyrmpage.ui` | `lib/bookwyrm_page.rb` | card | no |
| `src/Widgets/Attachment/Box.vala` | `lib/attachment_box.rb` | bin | no |
| `src/Widgets/Attachment/Item.vala` | `lib/attachment_item.rb` | bin | no |
| `src/Widgets/Attachment/Image.vala` | `lib/attachment_image.rb` | image item | no |
| `src/Widgets/AudioPlayer/Player.vala` | `lib/audio_player.rb` | player bin | no |
| `src/Widgets/AudioPlayer/Controls.vala` + `data/ui/widgets/audiocontrols.ui` | `lib/audio_player_controls.rb` | controls | no |
| `src/Widgets/AudioPlayer/Visualizer.vala` | `lib/audio_player_visualizer.rb` | custom-drawn widget | no |
| `src/Widgets/AudioPlayer/Stream.vala` | `lib/audio_player_stream.rb` | support object | no |
| `src/Widgets/CustomEmojiChooser.vala` | `lib/custom_emoji_chooser.rb` | popover (+ `EmojiCategory`, `EmojiButton`) | no |
| `src/Widgets/CustomEmojiChooserV2.vala` | `lib/custom_emoji_chooser_v2.rb` | popover (+ `EmojiCategory`) | no |
| `src/Widgets/Emoji.vala` | `lib/emoji.rb` | bin | no |
| `src/Widgets/EmojiLabel.vala` | `lib/emoji_label.rb` | label | no |
| `src/Widgets/EmojiReactionAccounts.vala` | `lib/emoji_reaction_accounts.rb` | expander row | no |
| `src/Widgets/ReactButton.vala` | `lib/react_button.rb` | button | no |
| `src/Widgets/RichLabel.vala` | `lib/rich_label.rb` | bin | no |
| `src/Widgets/LabelWithWidgets.vala` | `lib/label_with_widgets.rb` | custom widget | no |
| `src/Widgets/MarkupView.vala` | `lib/markup_view.rb` | box | no |
| `src/Widgets/SandwichSourceView.vala` | `lib/sandwich_source_view.rb` | source view | no |
| `src/Widgets/FocusPicker.vala` | `lib/focus_picker.rb` | custom widget | no |
| `src/Widgets/FocusPicture.vala` | `lib/focus_picture.rb` | custom widget | no |
| `src/Widgets/FadeBin.vala` | `lib/fade_bin.rb` | custom widget | no |
| `src/Widgets/ScaleRevealer.vala` | `lib/scale_revealer.rb` | bin | no |
| `src/Widgets/ListBoxRowWrapper.vala` | `lib/list_box_row_wrapper.rb` | row wrapper | yes |
| `src/Widgets/Widgetizable.vala` | `lib/widgetizable.rb` | interface/mixin | yes |
| `src/Widgets/Admin/AccountRow.vala` | `lib/admin_account_row.rb` | row | no |
| `src/Widgets/Admin/AssignedRow.vala` | `lib/admin_assigned_row.rb` | row | no |
| `src/Widgets/Admin/DomainAllow.vala` | `lib/admin_domain_allow.rb` | row | no |
| `src/Widgets/Admin/DomainBlock.vala` | `lib/admin_domain_block.rb` | expander row | no |
| `src/Widgets/Admin/EmailDomainBlock.vala` | `lib/admin_email_domain_block.rb` | row | no |
| `src/Widgets/Admin/IPBlock.vala` | `lib/admin_ip_block.rb` | row | no |
| `src/Widgets/Admin/Report.vala` | `lib/admin_report.rb` | row | no |

## Dropdown list factories (`data/gtk/dropdown/*.ui`, 12 files)

No backing source file of their own; each is a `GtkListItemFactory` used by a
dropdown in the composer or preferences, and each merges into the Ruby file of
its user:

`cep_main.ui`, `cep_emoji.ui` → `lib/custom_emoji_chooser_v2.rb` ·
`content_type.ui`, `content_type_title.ui` → `lib/composer_dialog.rb` ·
`expiration.ui`, `expiration_title.ui` → `lib/composer_polls.rb` ·
`language.ui`, `language_title.ui` → `lib/composer_dialog.rb` ·
`quotation_policy.ui`, `quotation_policy_title.ui` → `lib/composer_dialog.rb` ·
`icon.ui`, `full.ui` → generic, used by several dropdowns (admin pages,
preferences).

## Non-component prerequisites

Not UI, but no view can be built without them: `src/Services/Network/*`
(`Network`, `Request`, `RequestV2`, `Streamable`, `Streams`),
`src/Services/Accounts/*` (`AccountStore`, `SecretAccountStore`,
`InstanceAccount`, `AccountHolder`), `src/Services/Helpers/*`, `src/API/**`
(~80 entity files), `src/Utils/*` (`Html`, `DateTime`, `Blurhash`, `Counting`,
`Units`, `TagExtractor`, `Tracking`, `ShareHandler`, `WebApHandler`, `Locale`,
`Exif`, `Celebrate`, `Host`). Upstream has unit tests for ten of the `Utils`
(`tests/*.test.vala`) — the natural first spec targets on the port.

## Blockers and open questions

1. **Scale.** 146 component files (52 `Views`, 35 `Dialogs`, 59 `Widgets`),
   40 `.ui` files, 2135 upstream widget rows against 33 in the port — the
   shell, not a page. Full parity is not one work item; it needs a
   `PLAN.md` that sequences units (window+sidebar → `Status` → `Timeline` →
   Home → composer → the rest).
2. **GtkSourceView is not in the dev shell.** The composer editor is
   `GtkSource.View` with four completion providers and three custom `.lang`
   definitions (`data/langs/fedi-*.lang`). Probed in the fork's shell:
   `require "gtksourceview5"` raises `LoadError`, and the symbol table built
   here has no `GtkSource` rows. The composer unit needs either the gem added
   to `Gemfile`/`flake.nix` or a `Gtk::TextView` substitute — decide before
   planning it, not during.
3. **GStreamer is not in the dev shell.** `Widgets/AudioPlayer/*` and the
   media viewer need playback and an audio visualiser; `require "gst"` and
   `require "gstreamer"` both raise `LoadError`. Same decision as above.
4. **libsecret is not in the dev shell.** `SecretAccountStore` keeps tokens in
   the keyring and `require "secret"` raises `LoadError`; a port without it
   cannot log in at all. `gio2` is available, so `Gio` is an option for the
   non-secret half of the account store.
5. **Blurhash / Exif / ICU.** `src/Utils/Blurhash.vala`, `Exif.vala` and the
   `vapi/icu-uc.vapi` wrapper are C-level dependencies with no obvious Ruby
   equivalent — decide per unit whether to reimplement in Ruby or drop.
6. **Translations.** 158 files in `po/POTFILES`, 46 locales. Decide early
   whether the port carries the catalogue (`translation-parity` skill) or ships
   English only.
7. ~~**Shortcuts gap.**~~ Resolved: `app.shortcuts` is referenced by
   `data/gtk/shortcuts-dialog.ui` and the sidebar menu but never installed in
   upstream's `Application.vala` action table — libadwaita installs it for an
   `Adw.Application` that ships the dialog in its `gtk/` resource directory.
   The port has no GResource bundle, so `lib/application.rb` installs the
   action itself and presents `ShortcutsWindow`.
8. **Two emoji choosers.** `CustomEmojiChooser` and `CustomEmojiChooserV2` both
   exist upstream; find which is live before porting both.
