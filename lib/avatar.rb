# frozen_string_literal: true

require 'gtk4'
require 'adwaita'
require 'soup3'

# Avatar is the circular account-picture button used everywhere a post or
# profile shows who posted it.
#
# Ported from upstream's src/Widgets/Avatar.vala: an Adw.Avatar wrapped in a
# flat circular Gtk.Button, showing the account's display name as initials
# until its avatar image downloads, after which the image replaces the
# initials.
#
# Two differences from upstream:
#
# * Upstream fetches images through Tuba.Helper.Image, an app-wide disk cache
#   this port has not built yet. #avatar_url= fetches directly over
#   Soup::Session instead, with no on-disk cache, which is the one thing a
#   future Helper::Image would add back.
# * Upstream's #allow_mini_profile pops a Views.Profile.ProfileAccount mini
#   profile on click. Views::Profile does not exist in this port yet, so
#   that whole feature — the property, the popover and the mini_clicked
#   signal it would emit — is left out rather than built against nothing.
# * Upstream's #alternative_text= calls update_property with an
#   accessibility-description array. Same binding gap BaseView documents:
#   the Ruby bindings cannot marshal that call's array-of-enum argument
#   ("GIArgument(array/C)[interface(enum)](GtkAccessibleProperty)"), so this
#   port leaves the setter out rather than call code that always raises.
#   Everything a sighted user sees is unchanged.
#
class Avatar < Gtk::Button
  DEFAULT_SIZE = 48
  FALLBACK_TEXT = 'd'

  attr_reader :account, :avatar_url

  def initialize
    super()
    self.child = inner_avatar
    self.halign = :center
    self.valign = :center
    self.css_classes = ['flat', 'circular', 'image-button', 'ttl-flat-button', 'wavi']
    on_invalidated
  end

  def account=(value)
    on_invalidated(value)
    @account = value
  end

  def size = inner_avatar.size

  def size=(value)
    inner_avatar.size = value
  end

  def custom_image = inner_avatar.custom_image

  # Fetches the given URL and, once it decodes as an image, swaps it in for
  # the initials. A nil URL (no avatar set yet) leaves the initials showing.
  def avatar_url=(value)
    @avatar_url = value
    unless value.nil?
      fetch_avatar(value)
    end
  end

  private

    def on_invalidated(account = nil)
      if account.nil?
        inner_avatar.text = FALLBACK_TEXT
        inner_avatar.show_initials = false
      else
        inner_avatar.text = account.display_name
        inner_avatar.show_initials = true
        self.avatar_url = account.avatar
      end
    end

    def fetch_avatar(url)
      session.send_and_read_async(
        Soup::Message.new('GET', url),
        GLib::PRIORITY_DEFAULT,
        nil,
      ) { |source_session, result| on_fetch_response(source_session, result, url) }
    end

    def on_fetch_response(source_session, result, requested_url)
      if requested_url == avatar_url
        begin
          bytes = source_session.send_and_read_finish(result)
          on_cache_response(texture_from_bytes(bytes.to_s))
        rescue GLib::Error, GdkPixbuf::PixbufError => e
          warn "Avatar: failed to load #{requested_url}: #{e.message}"
        end
      end
    end

    def texture_from_bytes(data)
      pixbuf_loader.tap do |loader|
        loader.write(data)
        loader.close
      end.pixbuf.then { |pixbuf| Gdk::Texture.new(pixbuf) }
    end

    def pixbuf_loader = GdkPixbuf::PixbufLoader.new

    def on_cache_response(texture)
      inner_avatar.custom_image = texture
    end

    def session = @session ||= Soup::Session.new

    def inner_avatar
      @inner_avatar ||= Adwaita::Avatar.new(DEFAULT_SIZE, nil, true)
    end
end
