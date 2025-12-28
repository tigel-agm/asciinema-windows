# frozen_string_literal: true

require_relative "style"
require_relative "segment"
require_relative "text"
require_relative "panel"
require_relative "box"
require_relative "cells"

module Rich
  # Markdown rendering for terminal output.
  # Parses and renders Markdown content with styling.
  class Markdown
    # Default styles for Markdown elements
    DEFAULT_STYLES = {
      # Headings
      h1: Style.new(color: Color.parse("bright_cyan"), bold: true),
      h2: Style.new(color: Color.parse("cyan"), bold: true),
      h3: Style.new(color: Color.parse("bright_blue"), bold: true),
      h4: Style.new(color: Color.parse("blue"), bold: true),
      h5: Style.new(color: Color.parse("bright_magenta")),
      h6: Style.new(color: Color.parse("magenta")),

      # Text formatting
      bold: Style.new(bold: true),
      italic: Style.new(italic: true),
      bold_italic: Style.new(bold: true, italic: true),
      strikethrough: Style.new(strike: true),
      code_inline: Style.new(color: Color.parse("bright_green"), bgcolor: Color.parse("color(236)")),

      # Links and references
      link: Style.new(color: Color.parse("bright_blue"), underline: true),
      link_url: Style.new(color: Color.parse("blue"), dim: true),

      # Lists
      bullet: Style.new(color: Color.parse("yellow")),
      list_number: Style.new(color: Color.parse("yellow")),

      # Blockquotes
      blockquote: Style.new(color: Color.parse("bright_black"), italic: true),
      blockquote_border: Style.new(color: Color.parse("magenta")),

      # Code blocks
      code_block: Style.new(bgcolor: Color.parse("color(236)")),
      code_border: Style.new(color: Color.parse("bright_black")),

      # Horizontal rule
      hr: Style.new(color: Color.parse("bright_black")),

      # Table
      table_header: Style.new(bold: true, color: Color.parse("cyan")),
      table_border: Style.new(color: Color.parse("bright_black"))
    }.freeze

    # @return [String] Source markdown
    attr_reader :source

    # @return [Hash] Style configuration
    attr_reader :styles

    # @return [Boolean] Use hyperlinks
    attr_reader :hyperlinks

    # @return [Integer] Code block indent
    attr_reader :code_indent

    # Create a new Markdown renderer
    # @param source [String] Markdown source text
    # @param styles [Hash] Custom styles to override defaults
    # @param hyperlinks [Boolean] Enable terminal hyperlinks
    # @param code_indent [Integer] Indent for code blocks
    def initialize(source, styles: {}, hyperlinks: true, code_indent: 4)
      @source = source.to_s
      @styles = DEFAULT_STYLES.merge(styles)
      @hyperlinks = hyperlinks
      @code_indent = code_indent
    end

    # Render markdown to string with ANSI codes
    # @param max_width [Integer] Maximum width
    # @return [String]
    def render(max_width: 80)
      lines = parse_and_render(max_width: max_width)
      lines.join("\n")
    end

    # Convert to segments
    # @param max_width [Integer] Maximum width
    # @return [Array<Segment>]
    def to_segments(max_width: 80)
      segments = []
      lines = parse_and_render(max_width: max_width)

      lines.each_with_index do |line, i|
        # Line is already a rendered string with ANSI codes
        segments << Segment.new(line)
        segments << Segment.new("\n") if i < lines.length - 1
      end

      segments
    end

    class << self
      # Render markdown from string
      # @param source [String] Markdown text
      # @param kwargs [Hash] Options
      # @return [String]
      def render(source, **kwargs)
        new(source, **kwargs).render(**kwargs)
      end

      # Render markdown from file
      # @param path [String] File path
      # @param kwargs [Hash] Options
      # @return [String]
      def from_file(path, **kwargs)
        source = File.read(path)
        new(source, **kwargs)
      end
    end

    private

    # Parse and render markdown
    # @param max_width [Integer] Maximum width
    # @return [Array<String>]
    def parse_and_render(max_width:)
      lines = @source.lines.map(&:chomp)
      output = []
      i = 0

      while i < lines.length
        line = lines[i]

        # Blank line
        if line.strip.empty?
          output << ""
          i += 1
          next
        end

        # Fenced code block
        if line.match?(/^```/)
          lang = line[3..].strip
          code_lines = []
          i += 1
          while i < lines.length && !lines[i].start_with?("```")
            code_lines << lines[i]
            i += 1
          end
          output.concat(render_code_block(code_lines.join("\n"), lang, max_width))
          i += 1
          next
        end

        # Heading
        if line.match?(%r{^\#{1,6}\s})
          output.concat(render_heading(line, max_width))
          i += 1
          next
        end

        # Horizontal rule
        if line.match?(/^[-*_]{3,}\s*$/)
          output << render_hr(max_width)
          i += 1
          next
        end

        # Unordered list
        if line.match?(/^\s*[-*+]\s/)
          list_lines = [line]
          i += 1
          while i < lines.length && (lines[i].match?(/^\s*[-*+]\s/) || lines[i].match?(/^\s{2,}/))
            list_lines << lines[i]
            i += 1
          end
          output.concat(render_unordered_list(list_lines, max_width))
          next
        end

        # Ordered list
        if line.match?(/^\s*\d+\.\s/)
          list_lines = [line]
          i += 1
          while i < lines.length && (lines[i].match?(/^\s*\d+\.\s/) || lines[i].match?(/^\s{2,}/))
            list_lines << lines[i]
            i += 1
          end
          output.concat(render_ordered_list(list_lines, max_width))
          next
        end

        # Blockquote
        if line.start_with?(">")
          quote_lines = [line]
          i += 1
          while i < lines.length && (lines[i].start_with?(">") || (!lines[i].strip.empty? && !lines[i].match?(/^[#\-*+\d]/)))
            quote_lines << lines[i]
            i += 1
          end
          output.concat(render_blockquote(quote_lines, max_width))
          next
        end

        # Table
        if line.include?("|") && i + 1 < lines.length && lines[i + 1].match?(/^\|?\s*[-:]+/)
          table_lines = [line]
          i += 1
          while i < lines.length && lines[i].include?("|")
            table_lines << lines[i]
            i += 1
          end
          output.concat(render_table(table_lines, max_width))
          next
        end

        # Regular paragraph
        para_lines = [line]
        i += 1
        while i < lines.length && !lines[i].strip.empty? && !lines[i].match?(/^[\#\-*+>\d`|]/)
          para_lines << lines[i]
          i += 1
        end
        output.concat(render_paragraph(para_lines.join(" "), max_width))
      end

      output
    end

    # Render a heading
    def render_heading(line, max_width)
      match = line.match(%r{^(\#{1,6})\s+(.*)})
      return [line] unless match

      level = match[1].length
      text = match[2]

      style = @styles[:"h#{level}"] || @styles[:h1]
      styled_text = apply_inline_styles(text)

      result = []

      # Add decorations based on level
      case level
      when 1
        border = style.render + ("=" * [text.length + 4, max_width].min) + "\e[0m"
        result << border
        result << style.render + "  #{styled_text}  " + "\e[0m"
        result << border
      when 2
        result << style.render + styled_text + "\e[0m"
        result << style.render + ("-" * [text.length, max_width].min) + "\e[0m"
      else
        prefix = "#" * level + " "
        result << style.render + prefix + styled_text + "\e[0m"
      end

      result << ""
      result
    end

    # Render horizontal rule
    def render_hr(max_width)
      @styles[:hr].render + ("─" * max_width) + "\e[0m"
    end

    # Render unordered list
    def render_unordered_list(lines, max_width)
      result = []
      indent = 0

      lines.each do |line|
        match = line.match(/^(\s*)([-*+])\s+(.*)/)
        next unless match

        spaces = match[1]
        content = match[3]

        # Calculate indent level
        indent = spaces.length / 2

        bullet_char = case indent
                      when 0 then "•"
                      when 1 then "◦"
                      else "▪"
                      end

        prefix = "  " * indent
        bullet = @styles[:bullet].render + bullet_char + "\e[0m "
        styled_content = apply_inline_styles(content)

        result << prefix + bullet + styled_content
      end

      result << ""
      result
    end

    # Render ordered list
    def render_ordered_list(lines, max_width)
      result = []
      counter = 0

      lines.each do |line|
        match = line.match(/^(\s*)(\d+)\.\s+(.*)/)
        next unless match

        spaces = match[1]
        counter += 1
        content = match[3]

        indent = spaces.length / 2
        prefix = "  " * indent
        num = @styles[:list_number].render + "#{counter}." + "\e[0m "
        styled_content = apply_inline_styles(content)

        result << prefix + num + styled_content
      end

      result << ""
      result
    end

    # Render blockquote
    def render_blockquote(lines, max_width)
      result = []
      border_style = @styles[:blockquote_border]
      text_style = @styles[:blockquote]

      lines.each do |line|
        content = line.sub(/^>\s*/, "")
        styled = text_style.render + apply_inline_styles(content) + "\e[0m"
        result << border_style.render + "│ " + "\e[0m" + styled
      end

      result << ""
      result
    end

    # Render code block
    def render_code_block(code, language, max_width)
      result = []
      indent = " " * @code_indent
      style = @styles[:code_block]

      # Header with language
      if language && !language.empty?
        lang_display = "  #{language}  "
        result << @styles[:code_border].render + "┌" + ("─" * (max_width - 2)) + "┐" + "\e[0m"
        result << @styles[:code_border].render + "│" + "\e[0m" + " " + lang_display.ljust(max_width - 4) + @styles[:code_border].render + " │" + "\e[0m"
        result << @styles[:code_border].render + "├" + ("─" * (max_width - 2)) + "┤" + "\e[0m"
      else
        result << @styles[:code_border].render + "┌" + ("─" * (max_width - 2)) + "┐" + "\e[0m"
      end

      # Code lines
      code.each_line do |line|
        line = line.chomp
        padded = line.ljust(max_width - 4)
        result << @styles[:code_border].render + "│ " + "\e[0m" + style.render + padded + "\e[0m" + @styles[:code_border].render + " │" + "\e[0m"
      end

      # Footer
      result << @styles[:code_border].render + "└" + ("─" * (max_width - 2)) + "┘" + "\e[0m"
      result << ""

      result
    end

    # Render table
    def render_table(lines, max_width)
      return [] if lines.empty?

      # Parse table
      rows = lines.map do |line|
        line.split("|").map(&:strip).reject(&:empty?)
      end

      return [] if rows.empty?

      # Skip separator row
      rows.reject! { |row| row.all? { |cell| cell.match?(/^[-:]+$/) } }
      return [] if rows.empty?

      header = rows.first
      body = rows[1..]

      # Calculate column widths
      col_widths = header.map(&:length)
      body&.each do |row|
        row.each_with_index do |cell, i|
          col_widths[i] = [col_widths[i] || 0, cell.length].max
        end
      end

      result = []
      border_style = @styles[:table_border]
      header_style = @styles[:table_header]

      # Top border
      top = col_widths.map { |w| "─" * (w + 2) }.join("┬")
      result << border_style.render + "┌" + top + "┐" + "\e[0m"

      # Header row
      header_cells = header.each_with_index.map do |cell, i|
        " " + header_style.render + cell.ljust(col_widths[i]) + "\e[0m" + " "
      end
      result << border_style.render + "│" + "\e[0m" + header_cells.join(border_style.render + "│" + "\e[0m") + border_style.render + "│" + "\e[0m"

      # Header separator
      sep = col_widths.map { |w| "━" * (w + 2) }.join("┿")
      result << border_style.render + "┝" + sep + "┥" + "\e[0m"

      # Body rows
      body&.each do |row|
        cells = row.each_with_index.map do |cell, i|
          width = col_widths[i] || cell.length
          " " + apply_inline_styles(cell).ljust(width) + " "
        end
        # Pad missing cells
        while cells.length < col_widths.length
          cells << " " * (col_widths[cells.length] + 2)
        end
        result << border_style.render + "│" + "\e[0m" + cells.join(border_style.render + "│" + "\e[0m") + border_style.render + "│" + "\e[0m"
      end

      # Bottom border
      bottom = col_widths.map { |w| "─" * (w + 2) }.join("┴")
      result << border_style.render + "└" + bottom + "┘" + "\e[0m"

      result << ""
      result
    end

    # Render paragraph
    def render_paragraph(text, max_width)
      styled = apply_inline_styles(text)

      # Word wrap
      words = styled.split(/(\s+)/)
      lines = []
      current_line = ""
      current_width = 0

      words.each do |word|
        word_width = Cells.cell_len(Control.strip_ansi(word))

        if current_width + word_width > max_width && !current_line.empty?
          lines << current_line.rstrip
          current_line = ""
          current_width = 0
        end

        current_line += word
        current_width += word_width
      end

      lines << current_line.rstrip unless current_line.empty?
      lines << ""

      lines
    end

    # Apply inline styles (bold, italic, code, links)
    def apply_inline_styles(text)
      result = text.dup

      # Bold italic (***text*** or ___text___)
      result.gsub!(/(\*\*\*|___)([^*_]+)\1/) do
        @styles[:bold_italic].render + ::Regexp.last_match(2) + "\e[0m"
      end

      # Bold (**text** or __text__)
      result.gsub!(/(\*\*|__)([^*_]+)\1/) do
        @styles[:bold].render + ::Regexp.last_match(2) + "\e[0m"
      end

      # Italic (*text* or _text_)
      result.gsub!(/(\*|_)([^*_]+)\1/) do
        @styles[:italic].render + ::Regexp.last_match(2) + "\e[0m"
      end

      # Strikethrough (~~text~~)
      result.gsub!(/~~([^~]+)~~/) do
        @styles[:strikethrough].render + ::Regexp.last_match(1) + "\e[0m"
      end

      # Inline code (`code`)
      result.gsub!(/`([^`]+)`/) do
        @styles[:code_inline].render + ::Regexp.last_match(1) + "\e[0m"
      end

      # Links [text](url)
      result.gsub!(/\[([^\]]+)\]\(([^)]+)\)/) do
        text_part = ::Regexp.last_match(1)
        url = ::Regexp.last_match(2)

        if @hyperlinks
          @styles[:link].render + Control.hyperlink(url, text_part) + "\e[0m"
        else
          @styles[:link].render + text_part + "\e[0m" + " (" + @styles[:link_url].render + url + "\e[0m" + ")"
        end
      end

      result
    end
  end
end
