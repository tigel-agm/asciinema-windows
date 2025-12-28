# frozen_string_literal: true

require_relative "style"
require_relative "segment"
require_relative "cells"

module Rich
  # A span of styled text within a Text object
  class Span
    # @return [Integer] Start position (inclusive)
    attr_reader :start

    # @return [Integer] End position (exclusive)
    attr_reader :end

    # @return [Style] Style for this span
    attr_reader :style

    def initialize(start_pos, end_pos, style)
      @start = start_pos
      @end = end_pos
      @style = style.is_a?(String) ? Style.parse(style) : style
      freeze
    end

    # @return [Integer] Length of the span
    def length
      @end - @start
    end

    # Check if span overlaps with a range
    def overlaps?(start_pos, end_pos)
      @start < end_pos && @end > start_pos
    end

    # Adjust span after insertion at position
    def adjust_insert(position, length)
      if position <= @start
        Span.new(@start + length, @end + length, @style)
      elsif position < @end
        Span.new(@start, @end + length, @style)
      else
        self
      end
    end

    # Adjust span after deletion at position
    def adjust_delete(position, length)
      delete_end = position + length

      if delete_end <= @start
        Span.new(@start - length, @end - length, @style)
      elsif position >= @end
        self
      elsif position <= @start && delete_end >= @end
        nil # Span completely deleted
      elsif position <= @start
        Span.new(position, @end - length, @style)
      elsif delete_end >= @end
        Span.new(@start, position, @style)
      else
        Span.new(@start, @end - length, @style)
      end
    end

    def inspect
      "#<Rich::Span [#{@start}:#{@end}] #{@style}>"
    end
  end

  # Rich text with style spans.
  # Text objects contain plain text plus a list of style spans that define
  # how different portions of the text should be rendered.
  class Text
    # @return [String] Plain text content
    attr_reader :plain

    # @return [Array<Span>] Style spans
    attr_reader :spans

    # @return [Style, nil] Base style for entire text
    attr_reader :style

    # @return [Symbol] Justification (:left, :center, :right, :full)
    attr_reader :justify

    # @return [Symbol] Overflow handling (:fold, :crop, :ellipsis)
    attr_reader :overflow

    # @return [Boolean] No wrap
    attr_reader :no_wrap

    # @return [Boolean] End with newline
    attr_reader :end

    # Create new Text
    # @param text [String] Initial text
    # @param style [Style, String, nil] Base style
    # @param justify [Symbol] Text justification
    # @param overflow [Symbol] Overflow handling
    # @param no_wrap [Boolean] Disable wrapping
    def initialize(
      text = "",
      style: nil,
      justify: :left,
      overflow: :fold,
      no_wrap: false,
      end_str: "\n"
    )
      @plain = +text.to_s
      @spans = []
      @style = style.is_a?(String) ? Style.parse(style) : style
      @justify = justify
      @overflow = overflow
      @no_wrap = no_wrap
      @end = end_str
    end

    # @return [Integer] Length of text
    def length
      @plain.length
    end

    # @return [Integer] Cell width of text
    def cell_length
      Cells.cached_cell_len(@plain)
    end

    # @return [Boolean] True if text is empty
    def empty?
      @plain.empty?
    end

    # Append text with optional style
    # @param text [String, Text] Text to append
    # @param style [Style, String, nil] Style for appended text
    # @return [self]
    def append(text, style: nil)
      if text.is_a?(Text)
        append_text(text)
      else
        start_pos = @plain.length
        @plain << text.to_s

        if style
          parsed_style = style.is_a?(String) ? Style.parse(style) : style
          @spans << Span.new(start_pos, @plain.length, parsed_style)
        end
      end
      self
    end

    alias << append

    # Append a Text object
    # @param other [Text] Text to append
    # @return [self]
    def append_text(other)
      offset = @plain.length
      @plain << other.plain

      other.spans.each do |span|
        @spans << Span.new(span.start + offset, span.end + offset, span.style)
      end

      self
    end

    # Apply a style to a range
    # @param style [Style, String] Style to apply
    # @param start_pos [Integer] Start position
    # @param end_pos [Integer, nil] End position (nil = end of text)
    # @return [self]
    def stylize(style, start_pos = 0, end_pos = nil)
      end_pos ||= @plain.length
      return self if start_pos >= end_pos

      parsed_style = style.is_a?(String) ? Style.parse(style) : style
      @spans << Span.new(start_pos, end_pos, parsed_style)
      self
    end

    # Apply a style to the entire text
    # @param style [Style, String] Style to apply
    # @return [self]
    def stylize_all(style)
      stylize(style, 0, @plain.length)
    end

    # Get a substring as a new Text object
    # @param start_pos [Integer] Start position
    # @param length [Integer, nil] Length (nil = to end)
    # @return [Text]
    def slice(start_pos, length = nil)
      end_pos = length ? start_pos + length : @plain.length
      new_text = Text.new(@plain[start_pos...end_pos], style: @style)

      @spans.each do |span|
        next unless span.overlaps?(start_pos, end_pos)

        new_start = [span.start - start_pos, 0].max
        new_end = [span.end - start_pos, end_pos - start_pos].min
        new_text.spans << Span.new(new_start, new_end, span.style)
      end

      new_text
    end

    # Split text by a delimiter
    # @param delimiter [String] Delimiter to split on
    # @return [Array<Text>]
    def split(delimiter = "\n")
      parts = []
      pos = 0

      @plain.split(delimiter, -1).each do |part|
        end_pos = pos + part.length
        parts << slice(pos, part.length)
        pos = end_pos + delimiter.length
      end

      parts
    end

    # Wrap text to a given width
    # @param width [Integer] Maximum width
    # @return [Array<Text>]
    def wrap(width)
      return [self.dup] if width <= 0 || cell_length <= width

      lines = []
      current_line = Text.new(style: @style)
      current_width = 0

      words = @plain.split(/(\s+)/)
      word_pos = 0

      words.each do |word|
        word_width = Cells.cell_len(word)
        word_end = word_pos + word.length

        if current_width + word_width <= width
          # Word fits
          current_line.append(word)
          # Copy spans for this word
          @spans.each do |span|
            if span.overlaps?(word_pos, word_end)
              new_start = [span.start - word_pos, 0].max + current_line.length - word.length
              new_end = [span.end - word_pos, word.length].min + current_line.length - word.length
              current_line.spans << Span.new(new_start, new_end, span.style)
            end
          end
          current_width += word_width
        elsif word_width > width
          # Word is too long, need to break it
          unless current_line.empty?
            lines << current_line
            current_line = Text.new(style: @style)
            current_width = 0
          end

          # Break long word
          word.each_char do |char|
            char_width = Cells.char_width(char)
            if current_width + char_width > width
              lines << current_line
              current_line = Text.new(style: @style)
              current_width = 0
            end
            current_line.append(char)
            current_width += char_width
          end
        else
          # Start new line
          lines << current_line unless current_line.empty?
          current_line = Text.new(style: @style)
          current_line.append(word.lstrip)
          current_width = Cells.cell_len(word.lstrip)
        end

        word_pos = word_end
      end

      lines << current_line unless current_line.empty?
      lines
    end

    # Highlight occurrences of words
    def highlight_words(words, style:)
      words.each do |word|
        pos = 0
        while (pos = @plain.index(word, pos))
          stylize(style, pos, pos + word.length)
          pos += word.length
        end
      end
      self
    end

    # Highlight occurrences matching a regex
    def highlight_regex(re, style:)
      @plain.scan(re) do
        match = Regexp.last_match
        stylize(style, match.begin(0), match.end(0))
      end
      self
    end

    # Copy the text object
    def copy
      dup
    end

    # Convert to segments for rendering
    # @return [Array<Segment>]
    def to_segments
      return [Segment.new(@plain, style: @style)] if @spans.empty?

      # Build a list of style changes
      changes = []
      @spans.each do |span|
        changes << [span.start, :start, span.style]
        changes << [span.end, :end, span.style]
      end
      changes.sort_by! { |c| [c[0], c[1] == :end ? 0 : 1] }

      segments = []
      active_styles = []
      pos = 0

      changes.each do |change_pos, change_type, style|
        if change_pos > pos
          # Emit segment for text between pos and change_pos
          combined_style = combine_styles(active_styles)
          combined_style = @style + combined_style if @style && combined_style
          combined_style ||= @style

          segments << Segment.new(@plain[pos...change_pos], style: combined_style)
        end

        if change_type == :start
          active_styles << style
        else
          active_styles.delete_at(active_styles.rindex(style) || active_styles.length)
        end

        pos = change_pos
      end

      # Emit remaining text
      if pos < @plain.length
        combined_style = combine_styles(active_styles)
        combined_style = @style + combined_style if @style && combined_style
        combined_style ||= @style

        segments << Segment.new(@plain[pos..], style: combined_style)
      end

      segments
    end

    # Render text to string with ANSI codes
    # @param color_system [Symbol] Color system
    # @return [String]
    def render(color_system: ColorSystem::TRUECOLOR)
      Segment.render(to_segments, color_system: color_system)
    end

    # @return [String]
    def to_s
      @plain
    end

    def inspect
      "#<Rich::Text #{@plain.inspect} spans=#{@spans.length}>"
    end

    def dup
      new_text = Text.new(@plain.dup, style: @style)
      @spans.each { |span| new_text.spans << span }
      new_text
    end

    class << self
      # Assemble text from multiple parts
      # @param parts [Array] Alternating text and style pairs
      # @return [Text]
      def assemble(*parts)
        text = Text.new

        parts.each do |part|
          case part
          when String
            text.append(part)
          when Array
            content, style = part
            text.append(content, style: style)
          when Text
            text.append_text(part)
          end
        end

        text
      end

      # Create styled text
      # @param content [String] Text content
      # @param style [String] Style definition
      # @return [Text]
      def styled(content, style)
        text = Text.new(content)
        text.stylize_all(style)
        text
      end

      # Create from markup
      # @param markup [String] Markup text
      # @return [Text]
      def from_markup(markup)
        Markup.parse(markup)
      end
    end

    private

    def combine_styles(styles)
      return nil if styles.empty?
      return styles.first if styles.length == 1

      styles.reduce { |combined, style| combined + style }
    end
  end
end
