# frozen_string_literal: true

require 'adwaita'

# Style is Tuba's stylesheet and the two easter-egg stylesheets.
#
# Ported from upstream's data/style.css and data/eggs/6.css, data/eggs/7.css,
# together with the loading code in src/Application.vala (`load_egg` and the
# `Tuba.toggle_css` helper). Upstream ships the three sheets inside its
# GResource bundle and hands them to Gtk.CssProvider.load_from_resource; a
# GResource needs a compile step and an installed bundle, so the port carries
# the same declarations inline and loads them with load_from_data instead.
#
# The sheets are byte-for-byte the upstream ones: the same 132 classes, in the
# same cascade order, so a widget that asks for "ttl-view" or "notification-
# badge" gets exactly what upstream gives it.
#
class Style
  # Upstream adds its provider at GTK_STYLE_PROVIDER_PRIORITY_APPLICATION, so
  # the sheet overrides Adwaita's defaults but still loses to user CSS.
  PRIORITY = Gtk::StyleProvider::PRIORITY_APPLICATION

  SHEET = <<~'CSS'
/* Android font weight workaround, carried over from upstream data/style.css */
window.android *:not(.title-2):not(.title-1) {
	font-weight: 700;
}

/*
	Utility Classes
*/
.no-min-size {
	min-width: 0;
	min-height: 0;
}

.initial-font-size {
	font-size: initial;
}

.font-bold {
	font-weight: bold;
}

.no-shadow {
	box-shadow: none;
}

.devel-bg {
	background-image: cross-fade(5% -gtk-recolor(url(resource:///org/gnome/Adwaita/styles/assets/devel-symbolic.svg)), image(rgba(0,0,0,0)));
}

.italic {
	font-style: italic;
}

.monospace {
	font-family: monospace;
}

.no-padding {
	padding: 0;
}

.color-yellow-4 {
	color: var(--yellow-4);
}

.font-large {
	font-size: large;
}

.pill-like {
	border-radius: 9999px;
}

.background-none {
	background: none;
}

.min-size-64 {
	min-height: 64px;
	min-width: 64px;
}

.min-size-42 {
	min-width: 42px;
	min-height: 42px;
}

.text-uppercase {
	text-transform: uppercase;
}

.font-small {
	font-size: small;
}

.tuba-circular,
.dropdown-circular > button {
	border-radius: 9999px;
}

.ttl-flat-button {
	padding: 0px;
	margin: 0px;
}

.border-radius-6 {
	border-radius: 6px;
}

/*
	Overrides
*/
calendar, calendar>header {
	border: none;
}

calendar>header>button, calendar>grid>label {
	border-radius: 9px;
}

rubberband {
	border-radius: 9px;
}

flowboxchild {
	padding: 0;
}

video > overlay > revealer > controls {
	padding: 12px;
}

GtkSourceAssistant {
	background: var(--popover-bg-color);
	padding: 8px;
	/* border-radius of child + padding */
	border-radius: 14px;
}

GtkSourceAssistant.completion list row {
	padding: 6px 12px 6px 12px;
}

GtkSourceAssistant scrolledwindow undershoot {
	background-image: none;
	box-shadow: none;
}

GtkSourceAssistant scrolledwindow .cell.icon {
	padding-left: 0;
	padding-top: 0;
	padding-bottom: 0;
}

GtkSourceAssistant row {
	border-radius: 6px;
	margin: 6px 0;
	padding: 6px;
}

GtkSourceAssistant row:selected {
	background: rgb(from var(--accent-bg-color) r g b / calc(alpha * 0.33));
	color: currentColor;
}

GtkSourceAssistant row:first-child,
GtkSourceAssistant row:last-child {
	margin: 0;
}

list.uniform-border-color row {
	border-bottom-color: var(--border-color);
}

.emoji-reaction-expander>box>list,
.emoji-reaction-expander>box>list>row {
	border-radius: inherit;
}

.sourceview.reset {
	background: transparent;
	color: currentColor;
}

popover.no-padding > contents {
	padding: 0;
}

flowbox > flowboxchild:hover,
flowbox > flowboxchild:active,
flowbox > flowboxchild:selected:hover,
flowbox > flowboxchild:selected:active {
 background-color: inherit;
}

.ttl-box-no-shadow>revealer>box {
	box-shadow: none;
}

.about .app-version{color:#fff;text-shadow:-1px -1px 0#000,1px -1px 0#000,-1px 1px 0#000,1px 1px 0#000;background:linear-gradient(150deg,#fdd81755 0,#66338b55 8.3%,#fff5 16.6%,#f4aec855 24.9%,#7bcce555 33.2%,#94551655 41.5%,#0005 49.8%,#e2201655 58.1%,#f2891755 66.4%,#efe52455 74.7%,#78b82a55 83%,#2c58a4 91.3%,#6d238055 100%);}
.about .app-version:hover{background:radial-gradient(circle at 9.75% 50%,#0000 6.66%,#7902aa 6.7%,#0000 8.4%),conic-gradient(at 26.66% 50%,#0000 222.75deg,#ffd800 0 317.25deg,#0000 0),conic-gradient(at 33% 50%,#0000 222.75deg,white 0 317.25deg,#0000 0),conic-gradient(at 39% 50%,#0000 222.75deg,#ffa6b9 0 317.25deg,#0000 0),conic-gradient(at 45.66% 50%,#0000 222.75deg,#00d2ff 0 317.25deg,#0000 0),conic-gradient(at 52% 50%,#0000 222.75deg,#753000 0 317.25deg,#0000 0),conic-gradient(at 58.33% 50%,#0000 222.75deg,#000 0 317.25deg,#0000 0),linear-gradient(to bottom,#e40303,#e40303 16.67%,#ff8c00 16.67%,#ff8c00 33.33%,#ffed00 33.33%,#ffed00 50%,#008026 50%,#008026 66.67%,#004dff 66.67%,#004dff 83.33%,#750787 83.33%,#750787);}

/*
	Drive
*/
drive-item .indicator-box {
	border-radius: 9999px;
	padding: 6px;
}

drive-item:drop(active) {
	border:none;
	box-shadow: none;
}

drive-item:drop(active) image {
	box-shadow: inset 0 0 0 1px var(--accent-color);
	border-radius: 9px;
}

/*
	Search
*/
.search.rounded { /* .search is used on GTK widgets, avoid overriding */
	border-radius: 999px;
	padding-left: 12px;
	padding-right: 12px;
	padding-top: 3px;
	padding-bottom: 3px;
}

.entry-button {
	margin: 0;
	padding: 0;
	min-width: 0; /* 24px; */
	min-height: 0; /* 24px; */
}

.entry-button:not(:hover):not(:focus-within) > image {
	opacity: 0.7;
}

/*
	Custom Emoji Picker
*/
.picker-emoji-button {
	padding: 5px;
}

.cep-category row {
	border-radius: 6px;
	padding: 8px 12px;
	margin: 3px 6px;
	font-weight: bold;
}

/*
	Badge Indicators
*/
.notification-badge {
	font-weight: bold;
	font-size: 0.8em;
	border-radius: 10px;
	min-width: 0.8em;
	min-height: 0.8em;
	line-height: 0.8em;
	padding: 0.4em 5px;
	background-color: var(--accent-bg-color);
	color: white;
}

.notification-badge.no-attention {
	background-color: rgb(from var(--sidebar-fg-color) r g b / calc(alpha * 0.4));
}

.notifications-all.dim-enabled .can-be-dimmed {
	opacity: 0.70;
}

/* .cover-badge.button > button {
	padding-top: 0px;
	padding-bottom: 0px;
} */

/*
	Status Actions
*/
@keyframes rotate_star {
	from { -gtk-icon-transform: rotate(-72deg); }
	to {}
}

@keyframes bounce {
	0% { -gtk-icon-transform: translateY(-3px); }
	50% { -gtk-icon-transform: translateY(3px); }
	100% {}
}

@keyframes rotate_half {
	from { -gtk-icon-transform: rotate(-180deg); }
	to {}
}

@keyframes beat {
	0% {}
	50% { -gtk-icon-transform: scale(1.2); }
	100% {}
}

.ttl-status-action-reblog.enabled image {
	animation: rotate_half 0.4s ease;
}

.ttl-status-action-bookmark.enabled image {
	animation: bounce 0.4s ease;
}

.ttl-status-action-star.enabled image {
	animation: rotate_star 0.4s ease;
}

.ttl-status-action-heart.enabled image {
	animation: beat 1s ease;
}

.grouped-icon {
	--current-color-percentage: 15%;

	padding: 6px;
	background-color: color-mix(in srgb, currentColor var(--current-color-percentage), transparent);
	border-radius: 9999px;
}

.grouped-icon.star,
.ttl-status-action-star:hover,
.ttl-status-action-star.enabled {
	color: var(--yellow-5);
}

.ttl-status-action-star:active {
	color: var(--yellow-4);
}

.grouped-icon.reblog,
.ttl-status-action-reblog:hover,
.ttl-status-action-reblog.enabled {
	color: var(--purple-3);
}

.ttl-status-action-reblog:active {
	color: var(--purple-4);
}

.grouped-icon.follow,
.ttl-status-action-reply:hover,
.ttl-status-action-reply.enabled {
	color: var(--green-3);
}

.ttl-status-action-reply:active {
	color: var(--green-4);
}

.grouped-icon.sign-up,
.ttl-status-action-heart:hover,
.ttl-status-action-heart.enabled,
.ttl-status-action-bookmark:hover,
.ttl-status-action-bookmark.enabled {
	color: var(--red-3);
}

.ttl-status-action-heart:active,
.ttl-status-action-bookmark:active {
	color: var(--red-4);
}

.ttl-status-action-quote:hover,
.ttl-status-action-quote.enabled {
	color: var(--blue-3);
}

.ttl-status-action-quote:active {
	color: var(--blue-4);
}

.ttl-post-actions.narrow {
	font-size: smaller;
}

.ttl-post-actions.narrow > box > button {
	min-height: 30px;
}

.ttl-post-actions button image,
.ttl-post-actions button label {
	transition-duration: 200ms;
}

/*
	Preview and News Cards
*/
.preview_card {
	padding: 0;
}

.preview_card_v {
	border-radius: 6px 6px 0px 0px;
	min-height: 250px;
}

.ttl-view:not(.large-view) .preview_card_v {
	min-height: 150px;
}

.preview_card_h:dir(ltr) {
	border-radius: 6px 0px 0px 6px;
}

.preview_card_h:dir(rtl) {
	border-radius: 0px 6px 6px 0px;
}

.preview_card:not(.explore),
.preview_card:not(.explore) image:not(.min-size-64) {
	background-color: rgb(from currentColor r g b / calc(alpha * 0.0625));
}

.preview_card:not(.explore):hover {
	background-color: rgb(from currentColor r g b / calc(alpha * 0.125));
}

.preview_card:not(.explore):active {
	background-color: rgb(from currentColor r g b / calc(alpha * 0.1625));
}

.verified-author {
	padding: 0 5px;
}

.ttl-view:not(.large-view) .preview_card.explore .preview_card_h {
	border-radius: 0px;
}

.ttl-view:not(.large-view) .preview_card.explore {
	border-radius: 0px;
}

.ttl-view .preview_card.explore {
	border-radius: 12px;
}

/*
	Bookwyrm
*/
.bkwm-desc {
	padding: 12px;
}

/*
	Composer
*/
.spoilered-attachmentsbin picture {
	filter: blur(15px);
}

.composer-attachment,
.attachment-picture {
	border-radius: 12px;
}

.composer-attachment {
	background-color: color-mix(in srgb, currentColor 10%, transparent);
}

.composer-attachment .alt-indicator {
	--accent-percentage: 35%;
	--contrast-color: white;

	background-color: color-mix(in srgb, color-mix(in srgb, var(--error-bg-color) var(--accent-percentage), var(--contrast-color)) 80%, transparent);
	font-size: smaller;
	border-radius: 6px; /* 12px (parent radius) - 6px (margin) */
	font-weight: bold;
	padding: 3px 8px;
}

.composer-attachment .alt-indicator.success {
	background-color: color-mix(in srgb, color-mix(in srgb, var(--success-bg-color) var(--accent-percentage), var(--contrast-color)) 80%, transparent);
}

.editor-component {
	padding-bottom: 28px;
}

.attachment-editor-picker {
	background-color: var(--shade-color);
	padding: 12px 0;
}

.small-pill {
	padding: 10px 16px;
	border-radius: 9999px;
}

/*
	LabelWithWidgets
*/
.lww-scale-emoji-hover .lww-emoji {
	transition-duration: 150ms;
}

.lww-scale-emoji-hover .lww-emoji:hover {
	transform: scale(2);
}

/*
	VoteRow
*/
.ttl-poll-row {
	padding: 0;
}

.ttl-poll-row:first-child {
	border-top-left-radius: 12px;
	border-top-right-radius: 12px;
}

.ttl-poll-row:last-child {
	border-bottom-left-radius: 12px;
	border-bottom-right-radius: 12px;
}

/*
	Timelines
*/
.circular-spinner {
	border-radius: 100%;
	padding: 3px;
}

.card-spacing {
	background-color: var(--card-bg-color);
	margin-top: 6px;
	margin-bottom: 6px;
}

/* Focus ring */
.card-spacing > *:focus-within {
	border-radius: inherit;
}

/* .ttl-view listview>row.activatable:selected:hover,
.ttl-view listview>row.activatable:hover {
	background-color: transparent;
}

.ttl-view listview>row.activatable:selected:active,
.ttl-view listview>row.activatable:active {
	box-shadow: none;
} */

/* .ttl-view .content row:first-child { */
.ttl-view>.fake-content>row:first-child {
	margin-top: 0px;
}

/* .ttl-view .content row:last-child { */
.ttl-view>.fake-content>row:last-child {
	margin-bottom: 0px;
}

/* .ttl-view:not(.large-view) .content .card { */
.ttl-view:not(.large-view)>.fake-content>.card,
.ttl-view:not(.large-view)>.fake-content>.toggle-group-17,
.ttl-view:not(.large-view)>.fake-content>.toggle-group-17 > toggle-group {
	border-left: none;
	border-right: none;
	border-radius: 0px;
}

/* .ttl-view:not(.large-view) .content { */
.ttl-view:not(.large-view)>.fake-content {
	padding: 0px;
}

/* .ttl-view .content { */
.ttl-view>.fake-content {
	transition: all 200ms cubic-bezier(0.25, 0.46, 0.45, 0.94);
}

.ttl-view.large-view>.fake-content:first-child {
	padding-top: 32px;
}

.ttl-view.large-view>.fake-content:last-child {
	padding-bottom: 32px;
}

/* .ttl-view:not(.large-view) .content .card { */
.ttl-view:not(.large-view)>.fake-content>.card {
	border-bottom: 1px var(--border-color) solid;
}

/* .ttl-view:not(.large-view) .content .card:first-child { */
.ttl-view:not(.large-view)>.fake-content>.toggle-group-17 +.card,
.ttl-view:not(.large-view)>.fake-content>.card:first-child {
	border-top: 1px var(--border-color) solid;
}

/* .ttl-view:not(.large-view) .content .card { */
.ttl-view:not(.large-view)>.fake-content>.card {
	box-shadow: none;
}

/* .ttl-view:not(.large-view) .content .card.card-spacing { */
.ttl-view:not(.large-view)>.fake-content>.card.card-spacing {
	margin: 0px;
}

.ttl-view.large-view>.fake-content {
	padding-left: 0;
	padding-right: 0;
	margin-left: 18px;
	margin-right: 18px;
}

/*
	Sidebar
*/
.sidebar-item {
	padding: 3px 14px;
}

.ttl-separator {
	background-color: transparent;
	min-height: 8px;
}

/*
	Sidebar Account Switchers
*/
.ttl-account-switcher {
	padding: 0;
}

.ttl-account-switcher row {
	border-radius: 10px;
	margin: 3px 0px;
	padding-right: 0px;
	padding-left: 0px;
}

.ttl-account-switcher row:first-child {
	margin-top: 0px;
}

.ttl-account-switcher .new-account {
	margin-bottom: 0px;
}

.ttl-account-switcher separator {
	margin: 3px 0px;
}

.ttl-account-switcher row.active avatar {
	border: 2px solid var(--accent-bg-color);
}

.ttl-account-switcher .blue-checkmark {
	color: var(--light-1);
	border: solid var(--accent-bg-color) 2px;
	background-color: var(--accent-bg-color);
	margin-bottom: 3px;
	opacity: 0;
}

.ttl-account-switcher row.active .blue-checkmark {
	opacity: 1;
}

/*
	View FABs
*/
.compose-button {
	padding: 8px;
}

.scroll-to-top-btn {
	transition-duration: 200ms;
	transition-property: margin-bottom;
}

.scroll-to-top-btn.composer-btn-revealed {
	margin-bottom: 56px;
}

/*
	Status
*/
.status-box {
	margin: 14px 18px 18px 18px;
}

.status-box.has-actions, .ttl-view:not(.large-view) .status-box.has-actions {
	margin-bottom: 6px;
}

.ttl-view:not(.large-view) .status-box {
	margin: 10px 8px 12px 8px;
}

.hashtag-bar-hashtag {
	padding: 2px 7px;
}

.filter {
	margin: -2px;
	border-radius: 0;
}

.ttl-quote {
	border-radius: 6px;
	font-weight: initial;
}

.ttl-quote-state {
	padding: 6px;
}

.ttl-status-font-large > .ttl-large-body {
	font-size: larger;
}

.ttl-large-body {
	font-size: larger;
}

.ttl-status-line-height-large {
	line-height: 1.4;
}

.ttl-status-avatar-actor {
	margin-top: -20px;
	margin-left: -6px;
	padding: 0;
	background: none;
}

.ttl-status-avatar-border {
	border: 3px solid var(--popover-bg-color);
	border-radius: 100%;
	background-color: var(--popover-bg-color);
}

.ttl-post.direct {
	background-color: rgb(from var(--warning-bg-color) r g b / calc(alpha * 0.1));
}

.ttl-post.direct:hover {
	--multiplier: 0.7;
	background-color: hsl(from rgb(from var(--warning-bg-color) r g b / calc(alpha * 0.1)) h calc(s * var(--multiplier)) calc(l * var(--multiplier)));
}

.ttl-post.local {
	background-color: color-mix(in srgb, var(--purple-1) 10%, transparent);
}

.ttl-post.local:hover {
	--shade-color: black;
	background-color: color-mix(in srgb, color-mix(in srgb, var(--purple-1) 10%, transparent), var(--shade-color) 1%);
}

.ttl-status-heading-padding {
	margin-top: -5px;
	padding: 0 5px;
	margin-left: -5px;
	margin-right: -5px;
}

.ttl-status-badge {
	border-radius: 9px;
	margin: 8px;
	padding: 1px 6px;
}

.ttl-status-badge:not(.error):not(.success) {
	color: white;
	background-color: rgba(0, 0, 0, .8);
}

.ttl-status-badge.sensitive-label {
	padding: 10px 32px;
	border-radius: 9999px;
}

.ttl-name-button {
	padding: 0 5px;
	margin-left: -5px;
	margin-right: -5px;
}

.ttl-code {
	padding: 12px;
	background: rgba(150, 150, 150, .1);
	border-radius: 6px;
}

/*
	Admin Mode
*/
.report-status .attachment-picture { /* We need to protect admins from NSFW images */
	filter: blur(15px) grayscale(1);
}

.report-status:hover .attachment-picture {
	filter: none;
}

/*
	Focus Picker
*/
.focus-picker {
	padding: 4px;
}

/*
	Profile Editor
*/
.profile-editor .background-cover {
	border-radius: 12px;
	background-color: var(--shade-color);
}

/*
	Profile
*/
.account-avatar {
	margin-top: -30px;
}

.ttl-profile-fields-box > flowboxchild {
	border-radius: 0;
}

.ttl-profile-stat-button {
	padding: 8px 12px;
	min-height: 32px;
	border-radius: 0px;
}

.ttl-profile-stat-button:first-child {
	border-bottom-left-radius: 12px;
}

.ttl-profile-stat-button:last-child {
	border-bottom-right-radius: 12px;
}

.ttl-view:not(.large-view) .ttl-profile-cover-container .ttl-profile-stat-button:first-child,
.ttl-view:not(.large-view) .ttl-profile-cover-container .ttl-profile-stat-button:last-child {
	border-bottom-left-radius: 0px;
	border-bottom-right-radius: 0px;
}

.cover-badge {
	padding: 6px 12px;
	border-radius: 9px;
	margin: 8px;
}

.cover-badge.only-icon {
	padding: 6px;
}

.ttl-profile-cover .header-image {
	background: grey;
	border-radius: 0;
}

.ttl-profile-cover-container,
.ttl-profile-cover-container row,
popover.mini-profile row  {
	padding: 0px;
}

.ttl-profile-cover .main-avi avatar,
.profile-editor avatar {
	border: 6px solid var(--window-bg-color);
	background: var(--window-bg-color);
}

.large .header-image {
	border-radius: 12px 12px 0 0;
}

.ttl-profile-cover.thanks {
	--alpha-multiplier: 0.1;

	background-color: rgb(from var(--accent-bg-color) r g b / calc(alpha * var(--alpha-multiplier)));
}

.ttl-profile-cover.thanks avatar {
	border-color: rgb(from var(--accent-bg-color) r g b / calc(alpha * var(--alpha-multiplier)));
}

.ttl-profile-cover > .content {
	background: none;
}

.ttl-view:not(.large-view) .ttl-profile-cover>.content {
	border-bottom-left-radius: 0px;
	border-bottom-right-radius: 0px;
}

.profile-role {
	background-color: rgb(from currentColor r g b / calc(alpha * 0.1));
	padding: 4px 11px;
	font-size: 12.2px;
	font-weight: 500;
}

.ttl-profile-fields-box-container:not(.single) > .ttl-profile-fields-box > flowboxchild > .ttl-profile-field {
	border-bottom: solid 1px var(--border-color);
	border-right: solid 1px var(--border-color);
}

.ttl-profile-fields-box-container.odd > .ttl-profile-fields-box > flowboxchild:last-child > .ttl-profile-field {
	border-bottom: none;
}

.ttl-profile-fields-box-container:not(.odd) {
	border: none;
}

.ttl-profile-fields-box-container:not(.single) {
	margin-right: -1px; /* much simpler than complex nth-child selectors */
}

.ttl-profile-field {
	padding: 6px 12px;
}

.ttl-verified-field {
	color: var(--success-color);
	background: rgb(from var(--success-bg-color) r g b / calc(alpha * 0.1));
}

.ttl-birthday-field {
	color: var(--accent-pink);
	background: rgb(from var(--accent-pink) r g b / calc(alpha * 0.1));
}

.ttl-mutuals {
	padding: 0 5px;
	margin-left: -5px;
	margin-right: -5px;
}

.ttl-mutuals label {
	font-weight: normal;
}

.ttl-mutuals .mutual-avi:not(.first-avi) {
	margin-left: -6px;
}

.mutual-avi {
	border: 2px solid var(--card-bg-color);
	background-color: var(--card-bg-color);
}

.verified-link, .verified-link link {
	color: var(--success-color);
}

.note-row {
	background-color: rgb(from var(--warning-bg-color) r g b / calc(alpha * 0.1));
}

.note-row:hover {
	--multiplier: 0.7;
	background-color: hsl(from rgb(from var(--warning-bg-color) r g b / calc(alpha * 0.1)) h calc(s * var(--multiplier)) calc(l * var(--multiplier)));
}

/*
	Profile Filter Group
*/
.toggle-group-17 {
	background: none;
	padding: 0;
	margin-top: 6px;
	margin-bottom: 6px;
	border-radius: 9px;
}

/*
	FediWrapped
*/
@keyframes annual-avi-bg {
	0% { background-position: center 100%; }
	100% { background-position: center 0%; }
}

@keyframes annual-tuba-bg {
	0% { background-position: 0%; }
	100% { background-position: 100%; }
}

.annual .main-avi {
	background: -gtk-icontheme("tuba-explore2-large-symbolic");
	background-repeat: repeat;
	background-size: 16px;
	padding: 16px;
	animation: annual-avi-bg 5s linear infinite;
}

.annual .tuba {
	background-image: -gtk-icontheme("tuba-transparent-symbolic");
	background-repeat: repeat;
	background-size: 24px;
	background-position: center center;
	color: var(--accent-yellow);
	background-color: color-mix(in srgb, currentColor 15%, var(--window-bg-color));
	animation: annual-tuba-bg 5s linear infinite;
}

.annual-screenshot-box {
	padding: 12px;
	border-radius: 16px;
}

.annual-screenshot-box.style-window {
	background-color: var(--window-bg-color);
}

.annual-screenshot-box.style-accent {
	background-color: var(--accent-bg-color);
}

.annual-screenshot-box.style-pride {
	background-image: linear-gradient(135deg, rgba(228,3,3,0.3) 0%, rgba(255,140,0,0.3) 20%, rgba(255,237,0,0.3) 40%, rgba(0,128,38,0.3) 60%, rgba(0,77,255,0.3) 80%, rgba(117,7,135,0.3) 100%);
	background-color: var(--window-bg-color);
}

.annual-screenshot-box.style-trans {
	background-image: linear-gradient(135deg, rgba(92,206,250,0.5) 0%, rgba(246,168,183,0.5) 25%, rgba(255,255,255,0.5) 50%, rgba(246,168,183,0.5) 75%, rgba(92,206,250,0.5) 100%);
	background-color: var(--window-bg-color);
}

/*
	Media Viewer
*/
.media-viewer {
	color: white;
}

.media-viewer .top-bar {
	background-image: none;
}

.osd-box {
  border-radius: 12px;
  background-color: rgba(0, 0, 0, 0.65);
  padding: 6px;
}

/*
	Media Player Video/Audio controls
*/
.audio-controls {
	--alpha: 0.8;

	background-color: rgba(38,38,38,var(--alpha));
	border-radius: 9999px;
	padding: 2px;
}
.audio-controls,
clapper-gtk-lead-container>box {
	--accent-bg-color: @accent_bg_color;
	--accent-color: oklab(from var(--accent-bg-color) var(--standalone-color-oklab));
}
.audio-controls scale trough highlight {
	min-height: 6px;
}
.audio-controls>button:hover,
.audio-controls>button:checked {
	background-color: rgba(63,63,63,var(--alpha));
}
.audio-controls>button:active {
	background-color: rgba(82,82,82,var(--alpha));
}
.audio-controls>scalebutton>button {
	border-radius: 9999px;
}

/*
	DropOverlay
*/
dropoverlay,
dropoverlay > overlay > :not(revealer) {
	box-shadow: none;
}

dropoverlay .status {
	background-color: color-mix(in srgb, var(--accent-bg-color) 60%, transparent);
	color: var(--accent-fg-color);
}

/*
	Pill SplitButton
*/
splitbutton.pill {
	border-radius: 9999px;
}

splitbutton.pill > button {
	padding: 10px 16px;
}

splitbutton.pill > menubutton > button {
	padding: 10px 8px;
}

splitbutton.pill:dir(ltr) > button,
splitbutton.pill:dir(rtl) > menubutton,
splitbutton.pill:dir(rtl) > menubutton > button {
	border-top-left-radius: inherit;
	border-bottom-left-radius: inherit;
}

splitbutton.pill:dir(rtl) > button,
splitbutton.pill:dir(ltr) > menubutton,
splitbutton.pill:dir(ltr) > menubutton > button {
	border-top-right-radius: inherit;
	border-bottom-right-radius: inherit;
}

/*
	New Account Dialog
*/
.statusbox {
	margin: 36px 12px;
	border-spacing: 12px;
}

.statusbox > image {
	color: color-mix(in srgb, currentColor var(--dim-opacity), transparent);
	-gtk-icon-size: 128px;
	margin-bottom: 24px;
}

.statusbox > :last-child {
	margin-top: 24px;
}

/*
	Celebrate
*/
.theme-disability.about .app-version{background:linear-gradient(45deg,#59595955 0,#59595955 37.5%,#cf728055 37.5%,#cf728055 42.5%,#eede7755 42.5%,#eede7755 47.5%,#e8e8e855 47.5%,#e8e8e855 52.5%,#7bc2e055 52.5%,#7bc2e055 57.5%,#3bb07d55 57.5%,#3bb07d55 62.5%,#59595955 62.5%,#59595955 100%);}
.theme-disability.about .app-version:hover{background:linear-gradient(45deg,#595959 0,#595959 37.5%,#cf7280 37.5%,#cf7280 42.5%,#eede77 42.5%,#eede77 47.5%,#e8e8e8 47.5%,#e8e8e8 52.5%,#7bc2e0 52.5%,#7bc2e0 57.5%,#3bb07d 57.5%,#3bb07d 62.5%,#595959 62.5%,#595959 100%);}
.theme-lesbian.about .app-version{background:linear-gradient(to bottom,#d1260155,#d1260155 20%,#ff8f4555 20%,#ff8f4555 40%,#fff5 40%,#fff5 60%,#cf559b55 60%,#cf559b55 80%,#9b1a5855 80%,#9b1a5855);}
.theme-lesbian.about .app-version:hover{background:linear-gradient(to bottom,#d12601,#d12601 20%,#ff8f45 20%,#ff8f45 40%,#fff 40%,#fff 60%,#cf559b 60%,#cf559b 80%,#9b1a58 80%,#9b1a58);}
.theme-pan.about .app-version{background:linear-gradient(to bottom,#ff218c55,#ff218c55 33.33%,#fed80055 33.33%,#fed80055 66.67%,#21b1ff55 66.67%,#21b1ff55);}
.theme-pan.about .app-version:hover{background:linear-gradient(to bottom,#ff218c,#ff218c 33.33%,#fed800 33.33%,#fed800 66.67%,#21b1ff 66.67%,#21b1ff);}
.theme-trans.about .app-version{background:linear-gradient(to bottom,#5ccefa55,#5ccefa55 20%,#f6a8b755 20%,#f6a8b755 40%,#fff5 40%,#fff5 60%,#f6a8b755 60%,#f6a8b755 80%,#5ccefa55 80%,#5ccefa55);}
.theme-trans.about .app-version:hover{background:linear-gradient(to bottom,#5ccefa,#5ccefa 20%,#f6a8b7 20%,#f6a8b7 40%,#fff 40%,#fff 60%,#f6a8b7 60%,#f6a8b7 80%,#5ccefa 80%,#5ccefa);}
.theme-bi.about .app-version{background:linear-gradient(to bottom,#d6027055,#d6027055 40%,#9a4f9655 40%,#9a4f9655 60%,#0039a955 60%,#0039a955);}
.theme-bi.about .app-version:hover{background:linear-gradient(to bottom,#d60270,#d60270 40%,#9a4f96 40%,#9a4f96 60%,#0039a9 60%,#0039a9);}
.theme-agender.about .app-version{background:linear-gradient(to bottom,#0005,#00000055 14.29%,#bcc4c755 14.29%,#bcc4c755 28.57%,#fff5 28.57%,#fff5 42.86%,#b7f58455 42.86%,#b7f58455 57.14%,#fff5 57.14%,#fff5 71.43%,#bcc4c755 71.43%,#bcc4c755 85.71%,#00000055 85.71%,#0005);}
.theme-agender.about .app-version:hover{background:linear-gradient(to bottom,#000,#000 14.29%,#bcc4c7 14.29%,#bcc4c7 28.57%,#fff 28.57%,#fff 42.86%,#b7f584 42.86%,#b7f584 57.14%,#fff 57.14%,#fff 71.43%,#bcc4c7 71.43%,#bcc4c7 85.71%,#000 85.71%,#000);}
.theme-aro.about .app-version{background:linear-gradient(to bottom,#309c3455,#309c3455 20%,#9dce6955 20%,#9dce6955 40%,#fff5 40%,#fff5 60%,#a0a0a055 60%,#a0a0a055 80%,#0005 80%,#0005);}
.theme-aro.about .app-version:hover{background:linear-gradient(to bottom,#309c34,#309c34 20%,#9dce69 20%,#9dce69 40%,#fff 40%,#fff 60%,#a0a0a0 60%,#a0a0a0 80%,#000 80%,#000);}
.theme-ace.about .app-version{background:linear-gradient(to bottom,#0005,#0005 25%,#a3a3a355 25%,#a3a3a355 50%,#fff5 50%,#fff5 75%,#82008055 75%,#82008055);}
.theme-ace.about .app-version:hover{background:linear-gradient(to bottom,#000,#000 25%,#a3a3a3 25%,#a3a3a3 50%,#fff 50%,#fff 75%,#820080 75%,#820080);}
.theme-non-binary.about .app-version{background:linear-gradient(to bottom,#fdf52f55,#fdf52f55 25%,#fff5 25%,#fff5 50%,#9d5ad255 50%,#9d5ad255 75%,#0005 75%,#0005);}
.theme-non-binary.about .app-version:hover{background:linear-gradient(to bottom,#fdf52f,#fdf52f 25%,#fff 25%,#fff 50%,#9d5ad2 50%,#9d5ad2 75%,#000 75%,#000);}
.theme-black-history.about .app-version{background:linear-gradient(to bottom,#e31b2355,#e31b2355 33%,#0005 33%,#0005 66%,#00853f55 66%,#00853f55);}
.theme-black-history.about .app-version:hover{background:linear-gradient(to bottom,#e31b23,#e31b23 33%,#000 33%,#000 66%,#00853f 66%,#00853f);}
.theme-aids.about .app-version{background:linear-gradient(to bottom,#ffffff55,#ffffff55 20%,#d1111355 20%,#d1111355 40%,#ffffff55 40%,#ffffff55 60%,#d1111355 60%,#d1111355 80%,#ffffff55 80%,#ffffff55);}
.theme-aids.about .app-version:hover{background:linear-gradient(to bottom,#fff,#fff 20%,#d11113 20%,#d11113 40%,#fff 40%,#fff 60%,#d11113 60%,#d11113 80%,#fff 80%,#fff);}
.theme-intersex.about .app-version{background:radial-gradient(closest-side circle at center,#ffd80055 44%,#7902aa55 44%,#7902aa55 56%,#ffd80055 56%);}
.theme-intersex.about .app-version:hover{background:radial-gradient(closest-side circle at center,#ffd800 44%,#7902aa 44%,#7902aa 56%,#ffd800 56%);}
.theme-autism.about .app-version{background:linear-gradient(to bottom,#e5304355,#e5304355 16.66%,#f6834755 16.66%,#f6834755 33.33%,#fac85755 33.33%,#fac85755 66.67%,#99d67155 66.67%,#99d67155 83.33%,#21ae7555 83.33%,#21ae7555);}
.theme-autism.about .app-version:hover{background:linear-gradient(to bottom,#e53043,#e53043 16.66%,#f68347 16.66%,#f68347 33.33%,#fac857 33.33%,#fac857 66.67%,#99d671 66.67%,#99d671 83.33%,#21ae75 83.33%,#21ae75);}

/*
	Media Queries
*/
@media (prefers-color-scheme: dark) {
	/* wait for light-dark() */
	.grouped-icon.star,
	.ttl-status-action-star:hover,
	.ttl-status-action-star.enabled {
		color: var(--yellow-1);
	}

	.ttl-status-action-star:active {
		color: var(--yellow-2);
	}

	.grouped-icon.reblog,
	.ttl-status-action-reblog:hover,
	.ttl-status-action-reblog.enabled {
		color: var(--purple-1);
	}

	.ttl-status-action-reblog:active {
		color: var(--purple-2);
	}

	.grouped-icon.follow,
	.ttl-status-action-reply:hover,
	.ttl-status-action-reply.enabled {
		color: var(--green-1);
	}

	.ttl-status-action-reply:active {
		color: var(--green-2);
	}

	.grouped-icon.sign-up,
	.ttl-status-action-heart:hover,
	.ttl-status-action-heart.enabled,
	.ttl-status-action-bookmark:hover,
	.ttl-status-action-bookmark.enabled {
		color: var(--red-1);
	}

	.ttl-status-action-heart:active,
	.ttl-status-action-bookmark:active {
		color: var(--red-2);
	}

	.ttl-status-action-quote:hover,
	.ttl-status-action-quote.enabled {
		color: var(--blue-1);
	}

	.ttl-status-action-quote:active {
		color: var(--blue-2);
	}

	.ttl-post.direct:hover, .note-row {
		--multiplier: 1.3;
	}

	.ttl-post.local:hover {
		--shade-color: white;
	}

	.ttl-darken-images avatar:not(:hover), .ttl-darken-images picture:not(:hover) {
		filter: brightness(.8) contrast(1.2);
	}

	.composer-attachment .alt-indicator {
		--accent-percentage: 50%;
		--contrast-color: black;
	}

	.composer-attachment .alt-indicator.success {
		--accent-percentage: 40%;
	}
}

/*
	Collections
*/
.collection {
	padding: 6px;
}

.collection-button {
	font-weight: initial;
}

.collection-button .collection {
	padding : 0;
}

.collection-sensitive {
	filter: blur(4px);
}

@media (prefers-contrast: more) {
	.ttl-profile-cover.thanks {
		--alpha-multiplier: 0.08;
	}

	.grouped-icon {
		--current-color-percentage: 5%;
	}

	.grouped-icon,
	.composer-attachment,
	.composer-attachment .alt-indicator,
	.audio-controls,
	clapper-gtk-lead-container>box {
		box-shadow: inset 0 0 0 1px var(--border-color);
	}

	.composer-attachment .alt-indicator {
		background-color: var(--window-bg-color);
		color: var(--window-fg-color);
	}

	clapper-gtk-lead-container>box {
		background-color: rgba(38,38,38,1);
	}

	.audio-controls {
		--alpha: 1;
	}
}

/*
	Hard-coded font size steps
	?: toggling css is faster than creating css
	?: providers for every status
	?: changing dpi or font size applies to the
	?: whole app, not just statuses
*/
.ttl-status-font-large-80:not(.ttl-quote) {
	font-size: 80%;
}

.ttl-status-font-large-90:not(.ttl-quote) {
	font-size: 90%;
}

.ttl-status-font-large-110:not(.ttl-quote) {
	font-size: 110%;
}

.ttl-status-font-large-120:not(.ttl-quote) {
	font-size: 120%;
}

.ttl-status-font-large-130:not(.ttl-quote) {
	font-size: 130%;
}

.ttl-status-font-large-140:not(.ttl-quote) {
	font-size: 140%;
}

.ttl-status-font-large-150:not(.ttl-quote) {
	font-size: 150%;
}

.ttl-status-font-large-160:not(.ttl-quote) {
	font-size: 160%;
}

.ttl-status-font-large-170:not(.ttl-quote) {
	font-size: 170%;
}

.ttl-status-font-large-180:not(.ttl-quote) {
	font-size: 180%;
}

.ttl-status-font-large-190:not(.ttl-quote) {
	font-size: 190%;
}

.ttl-status-font-large-200:not(.ttl-quote) {
	font-size: 200%;
}
  CSS

  # The eggs are alternative sheets Tuba loads once, on a date-triggered
  # easter egg, instead of (not in addition to) the normal palette. Upstream
  # also forces the light color scheme while one is loaded.
  EGG_6 = <<~'CSS'
/* Based on Alice's (https://nyaa.place/) stylesheets */

.top-bar,
.bottom-bar {
	background-image: linear-gradient(to bottom, rgb(255 255 255 / 20%), rgb(0 0 0 / 15%));
	background-color: var(--accent-bg-color);
	box-shadow: inset 0 1px rgb(255 255 255 / 25%), inset 0 -1px rgb(0 0 0 / 15%);
	color: white;
	text-shadow: 0 -1px rgb(0 0 0 / 40%);
	-gtk-icon-shadow: 0 -1px rgb(0 0 0 / 40%);

	--button-bg-color: var(--accent-bg-color);
	--button-bg-gradient: linear-gradient(to bottom, rgb(255 255 255 / 25%), rgb(0 0 0 / 15%));
}

.top-bar>windowhandle {
	box-shadow: 0 0 5px 2px rgb(0 0 0 / 30%);
}

.toggle-group-17,
.toggle-group-17>toggle-group {
	border-radius: 3px;
}

.toggle-group-17>toggle-group {
	background: #3D3846;
	color: white;
}

.toggle-group-17>toggle-group toggle {
	border-radius: 3px;
	box-shadow: none;
	background: linear-gradient(to bottom, rgb(255 255 255 / 25%), rgb(0 0 0 / 15%));
}

.toggle-group-17>toggle-group toggle:checked {
	color: white;
	background-image: linear-gradient(to top, rgb(255 255 255 / 5%), rgb(0 0 0 / 15%));
}

.bottom-bar {
	background-color: #3D3846;
	--button-bg-color: #3D3846;
}

.top-bar button,
.bottom-bar button {
	background-color: var(--button-bg-color);
	background-image: var(--button-bg-gradient);
	box-shadow: inset 0 0 2px 1px rgb(0 0 0 / 15%), inset 0 1px rgb(0 0 0 / 40%), 0 1px rgb(255 255 255 / 20%);
	border-radius: 6px;
	text-shadow: 0 -1px rgb(0 0 0 / 40%);
	-gtk-icon-shadow: 0 -1px rgb(0 0 0 / 40%);
	color: white;
}

entry {
	background: white;
	color: black;
	text-shadow: none;
	-gtk-icon-shadow: none;
	box-shadow: inset 0 0 2px 1px rgb(0 0 0 / 45%);
	border-radius: 9999px;
}

button.destructive-action {
	--button-bg-color: var(--destructive-bg-color);
	color: white;
}

button.suggested-action {
	--button-bg-color: var(--accent-bg-color);
	color: white;
}

splitbutton.pill>button {
	border-top-right-radius: 0;
	border-bottom-right-radius: 0;
}

splitbutton.pill>menubutton>button {
	border-top-left-radius: 0;
	border-bottom-left-radius: 0;
}

.ttl-profile-cover row,
.boxed-list,
.card,
.boxed-list-separate row {
	background: white;
	color: black;
	box-shadow: inset 0 0 0 1px rgb(0 0 0 / 30%), inset 0 1px rgb(0 0 0 / 20%), 0 1px rgb(255 255 255 / 40%);
	text-shadow: none;
	-gtk-icon-shadow: none;
}

.header-image {
	border-radius: 0;
}

.card:hover {
	background: rgb(245, 245, 245);
}

.wavi,
avatar {
	border-radius: 6px;
}

toolbarview {
	--color1: oklch(from var(--accent-bg-color) 86% 3% h);
	--color2: oklch(from var(--accent-bg-color) 84% 3% h);
	background: repeating-linear-gradient(to right, var(--color1), var(--color1) 8px, var(--color2) 8px, var(--color2) 12px);
	text-shadow: 0 1px rgb(255 255 255 / 50%);
	-gtk-icon-shadow: 0 1px rgb(255 255 255 / 50%);
}

:root {
	--card-shade-color: rgb(0 0 0 / 20%);
}

.compose-button,
.sidebar-item image,
row .icon {
	background: var(--accent-bg-color);
	color: white;
	border-radius: 6px;
	box-shadow: inset 0 0 0 1px rgb(0 0 0 / 50%), inset 0 0 0 2px rgb(255 255 255 / 10%);
	background-image: radial-gradient(ellipse 200% at 50% -50%, white, rgba(255 255 255 / 20%) 50%, rgba(0 0 0 / 20%) 50%, transparent 65%);
	-gtk-icon-shadow: 0 0 2px rgb(0 0 0 / 40%);
}

.sidebar-item image,
row .icon {
	min-width: 32px;
	min-height: 32px;
	padding: 0;
	margin-top: 6px;
	margin-bottom: 6px;
}

.ttl-status-action-heart,
.ttl-status-action-star,
.ttl-status-action-reblog,
.ttl-status-action-quote,
.ttl-status-action-reply,
.ttl-status-action-bookmark {
	color: white;
	background-color: grey;
	box-shadow: inset 0 0 0 1px rgb(0 0 0 / 50%), inset 0 0 0 2px rgb(255 255 255 / 10%);
	background-image: radial-gradient(ellipse 200% at 50% -50%, white, rgba(255 255 255 / 20%) 50%, rgba(0 0 0 / 20%) 50%, transparent 65%);
}

.ttl-status-action-star:hover,
.ttl-status-action-star.enabled {
	background-color: var(--yellow-5);
}

.ttl-status-action-star:active {
	background-color: var(--yellow-4);
}

.ttl-status-action-reblog:hover,
.ttl-status-action-reblog.enabled {
	background-color: var(--purple-3);
}

.ttl-status-action-reblog:active {
	background-color: var(--purple-4);
}

.ttl-status-action-reply:hover,
.ttl-status-action-reply.enabled {
	background-color: var(--green-3);
}

.ttl-status-action-reply:active {
	background-color: var(--green-4);
}

.ttl-status-action-heart:hover,
.ttl-status-action-heart.enabled,
.ttl-status-action-bookmark:hover,
.ttl-status-action-bookmark.enabled {
	background-color: var(--red-3);
}

.ttl-status-action-heart:active,
.ttl-status-action-bookmark:active {
	background-color: var(--red-4);
}

.ttl-status-action-quote:hover,
.ttl-status-action-quote.enabled {
	background-color: var(--blue-3);
}

.ttl-status-action-quote:active {
	background-color: var(--blue-4);
}

@media (prefers-color-scheme: dark) {

	.ttl-status-action-heart,
	.ttl-status-action-star,
	.ttl-status-action-reblog,
	.ttl-status-action-quote,
	.ttl-status-action-reply,
	.ttl-status-action-bookmark {
		color: black;
		background-color: lightgrey;
	}

	sheet {
		color: black;
	}

	.ttl-status-action-star:hover,
	.ttl-status-action-star.enabled {
		background-color: var(--yellow-1);
	}

	.ttl-status-action-star:active {
		background-color: var(--yellow-2);
	}

	.ttl-status-action-reblog:hover,
	.ttl-status-action-reblog.enabled {
		background-color: var(--purple-1);
	}

	.ttl-status-action-reblog:active {
		background-color: var(--purple-2);
	}

	.ttl-status-action-reply:hover,
	.ttl-status-action-reply.enabled {
		background-color: var(--green-1);
	}

	.ttl-status-action-reply:active {
		background-color: var(--green-2);
	}

	.ttl-status-action-heart:hover,
	.ttl-status-action-heart.enabled,
	.ttl-status-action-bookmark:hover,
	.ttl-status-action-bookmark.enabled {
		background-color: var(--red-1);
	}

	.ttl-status-action-heart:active,
	.ttl-status-action-bookmark:active {
		background-color: var(--red-2);
	}

	.ttl-status-action-quote:hover,
	.ttl-status-action-quote.enabled {
		background-color: var(--blue-1);
	}

	.ttl-status-action-quote:active {
		background-color: var(--blue-2);
	}
}

.boxed-list row .icon {
	min-width: 32px;
	min-height: 32px;
	padding: 0;
	margin-top: 9px;
	margin-bottom: 9px;
}

.top-bar windowcontrols button {
	background: none;
	box-shadow: none;
}

.top-bar windowcontrols button image {
	background-color: black;
	background-image: radial-gradient(ellipse 200% at 50% -50%, white, rgba(255 255 255 / 20%) 50%, rgba(0 0 0 / 20%) 50%, transparent 65%);
	box-shadow: none;
	box-shadow: inset 0 0 0 2px white, 0 2px 3px 1px rgb(0 0 0 / 30%);
	-gtk-icon-shadow: 0 0 2px rgb(0 0 0 / 40%);
}

sheet {
	box-shadow: inset 0 0 0 3px rgba(255 255 255 / 80%), 0 0 2px rgba(0 0 0 / 40%), 0 5px 8px 2px rgb(0 0 0 / 40%);
}

bottom-sheet>sheet .top-bar {
	box-shadow: inset 0 -1px rgb(0 0 0 / 15%);
}

bottom-sheet>sheet,
bottom-sheet>sheet>outline,
bottom-sheet>sheet>stack>widget,
bottom-sheet>sheet>stack>button,
bottom-sheet>sheet>stack>button>widget {
	border-top-left-radius: 12px;
	border-top-right-radius: 12px;
}

bottom-sheet>sheet>outline {
	box-shadow: inset 0 1px rgb(255 255 255 / 25%);
}

row .title {
	font-weight: bold;
}

dialog.alert sheet {
	box-shadow: inset 0 0 0 3px rgba(255 255 255 / 80%), 0 0 2px rgba(0 0 0 / 40%), 0 5px 8px 2px rgb(0 0 0 / 40%);
	background-color: color-mix(in srgb, var(--accent-bg-color) 90%, transparent);
	background-image: radial-gradient(ellipse 500% at 50% -235%, rgba(255 255 255 / 20%) 48%, rgba(255 255 255 / 0%) 50%, rgba(0 0 0 / 30%) 50%);
	color: white;
	text-shadow: 0 -1px rgb(0 0 0 / 40%);
	-gtk-icon-shadow: 0 -1px rgb(0 0 0 / 40%);
}

dialog.alert button {
	background-color: var(--button-bg-color);
	background-image: linear-gradient(to bottom, rgb(255 255 255 / 25%), rgb(255 255 255 / 5%) 50%, rgb(0 0 0 / 15%) 50%, rgb(0 0 0 / 5%));
	box-shadow: inset 0 0 0 1px rgb(255 255 255 / 15%), 0 1px rgb(255 255 255 / 25%);
	border: 1px solid rgb(0 0 0 / 50%);
	border-radius: 6px;
	text-shadow: 0 -1px rgb(0 0 0 / 40%);
	-gtk-icon-shadow: 0 -1px rgb(0 0 0 / 40%);
	color: white;
	font-size: 130%;
}

.navigation-sidebar {
	padding: 0;
}

.navigation-sidebar row {
	margin: 0;
	border-radius: 0;
	margin-top: 2px;
	box-shadow: 0 -2px rgb(0 0 0 / 10%), 0 -1px rgb(255 255 255 / 60%);
}

.navigation-sidebar row:first-child {
	box-shadow: none;
	margin-top: 0;
}

.navigation-sidebar row:selected {
	color: white;
	background-color: var(--accent-bg-color);
	background-image: linear-gradient(to bottom, rgb(255 255 255 / 20%), rgb(0 0 0 / 15%));
	text-shadow: 0 -1px rgb(0 0 0 / 40%);
	-gtk-icon-shadow: 0 -1px rgb(0 0 0 / 40%);
}

.navigation-sidebar .header separator {
	background: none;
}

.sidebar-item {
	border-radius: 4px;

	padding-top: 0;
	padding-bottom: 0;
	min-height: 25px;
}

.sidebar-item:selected {
	color: white;
	background-color: var(--accent-bg-color);
	background-image: linear-gradient(to bottom, rgb(255 255 255 / 20%), rgb(0 0 0 / 15%));
	text-shadow: 0 -1px rgb(0 0 0 / 40%);
	-gtk-icon-shadow: 0 -1px rgb(0 0 0 / 40%);
}

.sidebar-pane {
	border-right: 1px solid rgb(0 0 0 / 50%);
}

.bottom-bar viewswitcher>button:checked image {
	color: var(--accent-bg-color);
}

overlay-split-view .ttl-sidebar toolbarview .top-bar {
	background: linear-gradient(180deg, #464e5b, #1e2633);

}

overlay-split-view>.background:not(.sidebar-pane) toolbarview,
.sidebar-pane toolbarview {
	background: #32394b;
	color: white;
}

overlay-split-view>.background:not(.sidebar-pane) toolbarview .sidebar-item:selected,
.sidebar-pane .sidebar-item:selected {
	background: linear-gradient(180deg, #475061, #383d50);
}

overlay-split-view>.background:not(.sidebar-pane) toolbarview .sidebar-item,
.sidebar-pane .sidebar-item {
	box-shadow: 0 -2px rgba(0, 0, 0, 0.1), 0 -1px #252c3c;
	border-top: 1px solid #3a4151;
}

.bottom-bar viewswitcher>button:checked image {
	color: var(--accent-bg-color);
}

overlay-split-view>.background:not(.sidebar-pane) toolbarview,
.sidebar-pane toolbarview {
	background: #32394b;
	color: white;
}

overlay-split-view>.background:not(.sidebar-pane) toolbarview .sidebar-item:selected,
.sidebar-pane .sidebar-item:selected {
	background: linear-gradient(180deg, #475061, #383d50);
}

overlay-split-view>.background:not(.sidebar-pane) toolbarview .sidebar-item,
.sidebar-pane .sidebar-item {
	box-shadow: 0 -2px rgba(0, 0, 0, 0.1), 0 -1px #252c3c;
	border-top: 1px solid #3a4151;
}

viewswitcher>button:checked {
	--button-bg-gradient: linear-gradient(to top, rgb(255 255 255 / 5%), rgb(0 0 0 / 15%));
}

.fake-content {
	background: none;
}

popover,
popover>contents {
	border-radius: 8px;
}

popover>contents {
	background: #ffffff;
	color: black;
}

popover>contents>scrolledwindow>viewport>stack>box {
	padding: 6px 0px;
}

popover>contents modelbutton {
	border: 1px solid transparent;
	border-radius: 0;
	padding: 2px 6px;
	min-height: 0;
}

popover>contents modelbutton:hover,
popover>contents modelbutton:focus {
	color: white;
	border: 1px solid #2d6ac4;
	background: linear-gradient(180deg, #518ef9, #0466ee);
}
  CSS

  EGG_7 = <<~'CSS'
/* Based on Alice's (https://nyaa.place/) stylesheets */

.ttl-profile-stat-button {
	padding: 0px 6px;
	border-radius: 0px;
}

.ttl-profile-stat-button:first-child {
	border-bottom-left-radius: 0px;
}

.ttl-profile-stat-button:last-child {
	border-bottom-right-radius: 0px;
}

.ttl-name-button {
	margin-right: 0px;
}

.spoilered-attachmentsbin picture,
.spoilered-attachment {
	filter: none;
	opacity: 0.1;
}

.boxed-list {
	background: none;
	box-shadow: none;
}

.card,
.boxed-list>row {
	border: 1px solid #0002;
	border-radius: 4px;
	box-shadow: none;
	background: none;
}

.card:hover,
.boxed-list>row:hover {
	border: 1px solid #bbd1e2;
	background: linear-gradient(180deg, #ebf4fe, #cfe3fb);
	border-radius: 4px;
}

dialog sheet {
	border-radius: 6px;
	background: none;
	outline: 1px solid rgb(255 255 255 / 50%);
	box-shadow: 0 0 0 1px rgb(0 0 0 / 50%), 0 3px 10px rgb(0 0 0 / 50%);

}

scrollbar:backdrop {
	background: transparent;
}

scrollbar {
	border: none;
	background: transparent;
}

toolbarview.browser.background {
	background: none;
}

scrollbar>range>trough {
	padding: 0px;
	margin: 0px;
	min-width: 0;
	border-radius: 0;
}

scrollbar slider {
	background-color: var(--accent-bg-color);
	background-image: linear-gradient(to right,
			rgb(255 255 255 / 20%) 50%,
			rgb(255 255 255 / 0%) 0%,
			rgb(255 255 255 / 10%));

	border-radius: 10px;
	opacity: 0.8;

	min-width: 15px;
}

scrollbar slider:hover {
	background-image: linear-gradient(to right,
			rgb(255 255 255 / 30%) 50%,
			rgb(255 255 255 / 10%) 0%,
			rgb(255 255 255 / 20%));
}

dialog sheet toolbarview>*:not(.top-bar),
.newaccdialogdeck toolbarview>*:not(.top-bar) {
	background-color: var(--window-bg-color);
	margin: 0 6px;
	box-shadow: 0 0 0 2px rgb(255 255 255 / 80%),
		0 0 0 1px rgb(0 0 0 / 80%);
}

dialog sheet toolbarview>.bottom-bar,
.newaccdialogdeck toolbarview>.bottom-bar {
	margin-bottom: 6px;
	box-shadow: 0 0 0 -2px rgb(255 255 255 / 80%),
		0 0 0 1px rgb(0 0 0 / 80%);
}

popover,
popover>contents {
	border-radius: 4px;
}

popover>contents {
	background: #f0f0f0;
}

popover>contents>scrolledwindow>viewport>stack>box {
	padding: 2px 2px;
}

popover>contents modelbutton {
	border: 1px solid transparent;
	border-radius: 3px;
	padding: 2px 6px;
	min-height: 0;
}

popover>contents modelbutton:hover,
popover>contents modelbutton:focus {
	border: 1px solid #bbd1e2;
	background: linear-gradient(180deg, #ebf4fe, #cfe3fb);
}

.header-image {
	border-radius: 0;
}

.wavi,
avatar {
	border-radius: 10px;
}

.toggle-group-17,
.toggle-group-17>toggle-group {
	border-radius: 3px;
}

.toggle-group-17>toggle-group {
	background: #e1ebf7;
}

.toggle-group-17>toggle-group toggle {
	border-radius: 3px;
	box-shadow: none;
}

.toggle-group-17>toggle-group toggle:checked {
	border: 1px solid #bbd1e2;
	background: linear-gradient(180deg, #ebf4fe, #cfe3fb);
}

dialog sheet {
	background-color: oklch(from var(--accent-bg-color) 90% min(c, 0.075) h / 70%);
	background-image: linear-gradient(135deg, #fff5 70px, transparent 100px), linear-gradient(225deg, #fff5 70px, transparent 100px), linear-gradient(54deg, transparent 30%, #fff3 45%, #fff6 50%, #fff3 55%, transparent 70%);
	backdrop-filter: blur(3px);
	color: black;
	text-shadow: 0 0 1em white;
	-gtk-icon-shadow: 0 0 1em white;
}

window.background {
	box-shadow: 0 0 0 1px rgb(0 0 0 / 50%), 0 3px 10px rgb(0 0 0 / 50%);
	outline: 1px solid rgb(255 255 255 / 50%);
	background-color: oklch(from var(--accent-bg-color) 90% min(c, 0.075) h / 70%);
	background-image: linear-gradient(135deg, #fff5 70px, transparent 100px), linear-gradient(225deg, #fff5 70px, transparent 100px), linear-gradient(54deg, transparent 30%, #fff3 45%, #fff6 50%, #fff3 55%, transparent 70%);
	backdrop-filter: blur(3px);
	color: black;
	text-shadow: 0 0 1em white;
	-gtk-icon-shadow: 0 0 1em white;
}

.sidebar-item {
	border-radius: 4px;

	padding-top: 0;
	padding-bottom: 0;
	min-height: 25px;
}

.sidebar-item:selected {
	border: 1px solid #bbd1e2;
	background: linear-gradient(180deg, #ebf4fe, #cfe3fb);
}

.devel .top-bar {
	background-image: none;
}

.sidebar {
	border-right: none;
}

.sidebar-pane,
.content-pane navigation-view-page>.background {
	background: none;
	box-shadow: none;
}

overlay-split-view>.background:not(.sidebar-pane) toolbarview,
.sidebar-pane toolbarview>box {
	box-shadow: 0 0 0 2px rgb(255 255 255 / 80%),
		0 0 0 1px rgb(0 0 0 / 80%);
	background: linear-gradient(135deg, #fff5 70px, transparent 100px), linear-gradient(225deg, #fff5 70px, transparent 100px), linear-gradient(54deg, transparent 30%, #fff3 45%, #fff6 50%, #fff3 55%, transparent 70%), #e1ebf7;
	text-shadow: none;
	-gtk-icon-shadow: none;
}

overlay-split-view>.background:not(.sidebar-pane) toolbarview>box {
	margin: 0 0 0 0;
}

.sidebar-pane toolbarview>box {
	margin: 0 0 6px 6px;
}

.search.rounded {
	background: white;
	box-shadow: 0 0 0 2px rgb(255 255 255 / 80%),
		0 0 0 1px rgb(0 0 0 / 80%);
	border-radius: 6px;
	padding-top: 0;
	padding-bottom: 0;
}

navigation-view-page>.background>toolbarview>overlay {
	background-color: var(--window-bg-color);
	margin: 0 6px 6px 0;
	box-shadow: 0 0 0 2px rgb(255 255 255 / 80%),
		0 0 0 1px rgb(0 0 0 / 80%);
	text-shadow: none;
	-gtk-icon-shadow: none;
}

.content-pane {
	background: none;
}

.content-pane toolbarview>stack {
	margin: 0 6px 6px 0;
	box-shadow: 0 0 0 2px rgb(255 255 255 / 80%),
		0 0 0 1px rgb(0 0 0 / 80%);
	background: #e1ebf7;
	text-shadow: none;
	-gtk-icon-shadow: none;
}

window {
	border-radius: 6px;
}

windowcontrols>* {
	min-height: 0;
	min-width: 0;
	padding: 0 4px;
	border-top-left-radius: 0;
	border-top-right-radius: 0;
	margin-top: -8px;
	margin-bottom: 18px;
	border-bottom-left-radius: 4px;
	border-bottom-right-radius: 4px;
}

windowcontrols .maximize,
windowcontrols .minimize {
	background-color: rgb(from var(--accent-bg-color) r g b / calc(alpha * 0.33));
}

windowcontrols>button:first-child:not(:last-child) {
	border-bottom-right-radius: 0px;
	margin-left: 2px;
}

windowcontrols>button:last-child:not(:first-child) {
	border-bottom-left-radius: 0px;
	margin-right: 2px;
}

windowcontrols>button:not(:last-child):not(:first-child) {
	border-bottom-left-radius: 0px;
	border-bottom-right-radius: 0px;
}

.close {
	background-color: #bd3727;

	box-shadow: inset 0 0 0 1px rgb(255 255 255 / 40%),
		0 0 0 2px rgb(255 255 255 / 80%),
		0 0 0 1px rgb(0 0 0 / 80%);
	padding: 0 10px;
}

.close:hover:not(:active) {
	box-shadow: inset 0 0 0 1px rgb(255 255 255 / 40%),
		0 0 0 2px rgb(255 255 255 / 80%),
		0 0 0 1px rgb(0 0 0 / 80%),
		0 0 10px 0 #bd3727;
}

windowcontrols image {
	background: none;
}

button {
	background-color: var(--accent-bg-color);
	background-image: linear-gradient(to bottom,
			rgb(255 255 255 / 20%) 50%,
			rgb(255 255 255 / 0%) 0%,
			rgb(255 255 255 / 10%));
	color: white;
	text-shadow: 0 0 2px rgb(0 0 0 / 80%);
	-gtk-icon-shadow: 0 0 2px rgb(0 0 0 / 80%);
	box-shadow: inset 0 0 0 1px rgb(255 255 255 / 40%),
		0 0 0 2px rgb(255 255 255 / 80%),
		0 0 0 1px rgb(0 0 0 / 80%);
	transition: none;
}

button:hover {
	background-image: linear-gradient(to bottom,
			rgb(255 255 255 / 30%) 50%,
			rgb(255 255 255 / 10%) 0%,
			rgb(255 255 255 / 20%));
}

button:active {
	background-image: linear-gradient(to bottom,
			rgb(255 255 255 / 10%) 50%,
			rgb(0 0 0 / 10%) 0%,
			rgb(255 255 255 / 0%));
	box-shadow: inset 0 0 5px rgb(0 0 0 / 40%),
		0 0 0 2px rgb(255 255 255 / 80%),
		0 0 0 1px rgb(0 0 0 / 80%);
}


.ttl-status-action-heart,
.ttl-status-action-star,
.ttl-status-action-reblog,
.ttl-status-action-quote,
.ttl-status-action-reply,
.ttl-status-action-bookmark {
	background-color: grey;
	background-image: linear-gradient(to bottom,
			rgb(255 255 255 / 20%) 50%,
			rgb(255 255 255 / 0%) 0%,
			rgb(255 255 255 / 10%));
}

.ttl-status-action-star:hover,
.ttl-status-action-star.enabled {
	background-color: var(--yellow-5);
}

.ttl-status-action-star:active {
	background-color: var(--yellow-4);
}

.ttl-status-action-reblog:hover,
.ttl-status-action-reblog.enabled {
	background-color: var(--purple-3);
}

.ttl-status-action-reblog:active {
	background-color: var(--purple-4);
}

.ttl-status-action-reply:hover,
.ttl-status-action-reply.enabled {
	background-color: var(--green-3);
}

.ttl-status-action-reply:active {
	background-color: var(--green-4);
}

.ttl-status-action-heart:hover,
.ttl-status-action-heart.enabled,
.ttl-status-action-bookmark:hover,
.ttl-status-action-bookmark.enabled {
	background-color: var(--red-3);
}

.ttl-status-action-heart:active,
.ttl-status-action-bookmark:active {
	background-color: var(--red-4);
}

.ttl-status-action-quote:hover,
.ttl-status-action-quote.enabled {
	background-color: var(--blue-3);
}

.ttl-status-action-quote:active {
	background-color: var(--blue-4);
}

@media (prefers-color-scheme: dark) {


	popover>contents,
	.sidebar-pane,
	window.background toolbarview:not(.media-viewer) headerbar,
	.toggle-group-17>toggle-group,
	.ttl-profile-cover:hover row,
	.card:hover,
	.boxed-list>row:hover,
	.toggle-group-17>toggle-group toggle:checked {
		color: black;
	}

	sheet toolbarview {
		color: white;
	}

	.card,
	.boxed-list>row {
		border: 1px solid #fff2;
	}

	.ttl-status-action-heart,
	.ttl-status-action-star,
	.ttl-status-action-reblog,
	.ttl-status-action-quote,
	.ttl-status-action-reply,
	.ttl-status-action-bookmark {
		color: black;
		background-color: lightgrey;
	}

	.ttl-status-action-star:hover,
	.ttl-status-action-star.enabled {
		background-color: var(--yellow-1);
	}

	.ttl-status-action-star:active {
		background-color: var(--yellow-2);
	}

	.ttl-status-action-reblog:hover,
	.ttl-status-action-reblog.enabled {
		background-color: var(--purple-1);
	}

	.ttl-status-action-reblog:active {
		background-color: var(--purple-2);
	}

	.ttl-status-action-reply:hover,
	.ttl-status-action-reply.enabled {
		background-color: var(--green-1);
	}

	.ttl-status-action-reply:active {
		background-color: var(--green-2);
	}

	.ttl-status-action-heart:hover,
	.ttl-status-action-heart.enabled,
	.ttl-status-action-bookmark:hover,
	.ttl-status-action-bookmark.enabled {
		background-color: var(--red-1);
	}

	.ttl-status-action-heart:active,
	.ttl-status-action-bookmark:active {
		background-color: var(--red-2);
	}

	.ttl-status-action-quote:hover,
	.ttl-status-action-quote.enabled {
		background-color: var(--blue-1);
	}

	.ttl-status-action-quote:active {
		background-color: var(--blue-2);
	}
}

viewswitcher>button:not(:checked) {
	background-color: grey;
}
  CSS

  EGGS = {
    '6' => EGG_6,
    '7' => EGG_7,
  }.freeze

  class << self
    # Installs the main stylesheet on a display. Called once, from the
    # application's startup, before any window is built.
    def apply(display = Gdk::Display.default)
      add(SHEET, display)
    end

    # Upstream's Application.load_egg: at most one egg per run, and the light
    # color scheme is forced for as long as it is loaded.
    def load_egg(name, display: Gdk::Display.default)
      unless loaded_egg?
        EGGS.fetch(name.to_s).then do |sheet|
          @loaded_egg = true
          add(sheet, display)
          Adwaita::StyleManager.default.color_scheme = :force_light
        end
      end
      loaded_egg?
    end

    def loaded_egg? = @loaded_egg == true

    # Upstream's Tuba.toggle_css: add the class when the state is on, remove
    # it when it is off. Every settings-driven class in the app goes through
    # this, so the two directions stay in one place.
    def toggle(widget, state, name)
      if state
        widget.add_css_class(name)
      else
        widget.remove_css_class(name)
      end
    end

    private

      def add(sheet, display)
        Gtk::CssProvider.new.tap do |provider|
          provider.load_from_data(sheet)
          Gtk::StyleContext.add_provider_for_display(display, provider, PRIORITY)
        end
      end
  end
end
