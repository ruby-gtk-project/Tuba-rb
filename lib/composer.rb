# frozen_string_literal: true

require 'gtk4'
require 'adwaita'
require 'libspelling'

require_relative 'utils_exif'

# Composer is a minimal stand-in for upstream's post-writing dialog: a text
# box to write into, and a button to attach an image.
#
# Ported from upstream's src/Dialogs/Composer/Window.vala and its Editor and
# Attachment components. I did not build the real composer - no visibility
# picker, no polls, no content warnings, no multi-attachment carousel, no
# actually posting anywhere - because this port has no account or network
# layer to post through yet. What is here is the two pieces upstream reaches
# through gems this port's gemspec claimed as dependencies but never called:
#
# * libspelling. Upstream's Editor.vala backs its text view with a
#   GtkSource.Buffer and wires a Spelling.TextBufferAdapter onto it
#   (Spelling.Checker.get_default, adapter.enabled = settings
#   .spellchecker_enabled); that adapter needs a GtkSource.Buffer, which
#   needs a gem (gtksourceview5) this port's gemspec does not declare and
#   which this change does not add. #check_spelling below calls
#   Spelling::Checker directly instead, word by word over a plain
#   Gtk::TextBuffer, and tags the misspelled ones - the same dictionary
#   lookup upstream's adapter drives, without a new dependency.
# * gexiv2. Upstream's AttachmentThumbnailer runs Utils.Exif.extract_alt_text
#   on every attached image's file and prefills the alt-text field from the
#   result (Attachment.vala's on_extracted_alt_text). #on_image_chosen below
#   does exactly that, through the real Utils::Exif (lib/utils_exif.rb,
#   itself real GExiv2 calls) rather than a stub.
#
class Composer
  SPELLCHECK_TAG = 'misspelled'

  def initialize(settings:)
    @settings = settings
  end

  def build
    window.tap do |win|
      win.child = toolbar_view

      toolbar_view.tap do |view|
        view.add_top_bar(header)
        view.content = clamp
      end

      header.tap do |hb|
        hb.pack_start(attach_button)
      end

      clamp.tap do |c|
        c.child = box
      end

      box.tap do |b|
        b.append(scrolled)
        b.append(alt_text_row)
      end

      scrolled.tap do |s|
        s.child = text_view
      end

      buffer.signal_connect('changed') { on_text_changed }
      attach_button.signal_connect('clicked') { on_attach_clicked }

      # Upstream's Editor.locale setter picks the account's posting language;
      # this port has no account layer to read that from, so the checker's
      # dictionary defaults to US English rather than whatever Spelling
      # falls back to (often nothing, with every word then "correct" for
      # lack of a dictionary to fail against).
      if spelling_checker.language.nil?
        spelling_checker.language = 'en_US'
      end
    end
  end

  def present(parent)
    window.transient_for = parent
    window.present
  end

  private

    attr_reader :settings

    def window
      @window ||= Gtk::Window.new.tap do |win|
        win.title = 'New Post'
        win.modal = true
        win.set_default_size(480, 360)
      end
    end

    def toolbar_view = @toolbar_view ||= Adwaita::ToolbarView.new
    def header = @header ||= Adwaita::HeaderBar.new

    def attach_button
      @attach_button ||= Gtk::Button.new.tap do |btn|
        btn.icon_name = 'image-x-generic-symbolic'
        btn.tooltip_text = 'Attach Image'
      end
    end

    def clamp = @clamp ||= Adwaita::Clamp.new
    def box = @box ||= Gtk::Box.new(:vertical, 8)
    def scrolled = @scrolled ||= Gtk::ScrolledWindow.new.tap { |s| s.vexpand = true }

    def text_view
      @text_view ||= Gtk::TextView.new.tap do |view|
        view.wrap_mode = :word_char
        view.buffer = buffer
      end
    end

    def buffer
      @buffer ||= Gtk::TextBuffer.new.tap do |buf|
        @spellcheck_tag = buf.create_tag(SPELLCHECK_TAG, underline: :error)
      end
    end

    def spellcheck_tag = buffer && @spellcheck_tag

    def alt_text_row
      @alt_text_row ||= Adwaita::EntryRow.new.tap do |row|
        row.title = 'Image Description (alt text)'
      end
    end

    # Spelling::Checker.default is the same instance upstream reaches through
    # Spelling.Checker.get_default. Checking is skipped entirely when the
    # user has spellchecking turned off, same as upstream's
    # `adapter.enabled`.
    def spelling_checker = @spelling_checker ||= Spelling::Checker.default

    def on_text_changed
      if settings.spellchecker_enabled?
        check_spelling
      end
    end

    # Clears the misspelled tag across the whole buffer, then walks the text
    # word by word and reapplies it to every word Spelling::Checker rejects.
    # This is the word-by-word check Spelling.TextBufferAdapter runs
    # internally; done by hand here because the adapter itself needs a
    # GtkSource.Buffer this port does not depend on.
    def check_spelling
      buffer.remove_tag(spellcheck_tag, buffer.start_iter, buffer.end_iter)

      text = buffer.text
      text.to_enum(:scan, /[[:alpha:]']+/).each do
        match = Regexp.last_match
        word = match[0]

        unless spelling_checker.check_word(word, -1)
          buffer.apply_tag(
            spellcheck_tag,
            buffer.get_iter_at(offset: match.begin(0)),
            buffer.get_iter_at(offset: match.end(0)),
          )
        end
      end
    end

    def on_attach_clicked
      file_chooser.show
    end

    def file_chooser
      @file_chooser ||= Gtk::FileChooserNative.new('Attach Image', window, :open, 'Select', 'Cancel').tap do |chooser|
        chooser.signal_connect('response') { |_, response_id| on_file_chosen(response_id) }
      end
    end

    def on_file_chosen(response_id)
      if response_id == Gtk::ResponseType::ACCEPT
        file_chooser.file.then { |file| on_image_chosen(file.path) }
      end
    end

    # Upstream's Attachment.vala, on_extracted_alt_text: only fills the alt
    # text in if the user has not already written one.
    def on_image_chosen(path)
      Utils::Exif.extract_alt_text(path).then do |alt_text|
        if !alt_text.nil? && alt_text_row.text.to_s.empty?
          alt_text_row.text = alt_text
        end
      end
    end
end
