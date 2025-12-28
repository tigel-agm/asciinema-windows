# frozen_string_literal: true

require_relative "box"
require_relative "style"
require_relative "segment"
require_relative "cells"
require_relative "text"

module Rich
  # Column definition for a Table
  class Column
    # @return [String] Column header
    attr_reader :header

    # @return [String, nil] Column footer
    attr_reader :footer

    # @return [Style, nil] Header style
    attr_reader :header_style

    # @return [Style, nil] Cell style
    attr_reader :style

    # @return [Style, nil] Footer style
    attr_reader :footer_style

    # @return [Symbol] Justification (:left, :center, :right)
    attr_reader :justify

    # @return [Integer, nil] Minimum width
    attr_reader :min_width

    # @return [Integer, nil] Maximum width
    attr_reader :max_width

    # @return [Boolean] No wrap
    attr_reader :no_wrap

    # @return [Symbol] Overflow handling (:fold, :crop, :ellipsis)
    attr_reader :overflow

    # @return [Integer] Ratio for flexible sizing
    attr_reader :ratio

    def initialize(
      header = "",
      footer: nil,
      header_style: nil,
      style: nil,
      footer_style: nil,
      justify: :left,
      min_width: nil,
      max_width: nil,
      no_wrap: false,
      overflow: :ellipsis,
      ratio: 1
    )
      @header = header.to_s
      @footer = footer
      @header_style = header_style.is_a?(String) ? Style.parse(header_style) : header_style
      @style = style.is_a?(String) ? Style.parse(style) : style
      @footer_style = footer_style.is_a?(String) ? Style.parse(footer_style) : footer_style
      @justify = justify
      @min_width = min_width
      @max_width = max_width
      @no_wrap = no_wrap
      @overflow = overflow
      @ratio = ratio
    end
  end

  # A table for displaying tabular data
  class Table
    # @return [String, nil] Table title
    attr_reader :title

    # @return [String, nil] Table caption
    attr_reader :caption

    # @return [Box] Box style
    attr_reader :box

    # @return [Style, nil] Border style
    attr_reader :border_style

    # @return [Style, nil] Header style
    attr_reader :header_style

    # @return [Style, nil] Title style
    attr_reader :title_style

    # @return [Style, nil] Caption style
    attr_reader :caption_style

    # @return [Style, nil] Row styles (alternating)
    attr_reader :row_styles

    # @return [Boolean] Show header
    attr_reader :show_header

    # @return [Boolean] Show footer
    attr_reader :show_footer

    # @return [Boolean] Show edge (outer border)
    attr_reader :show_edge

    # @return [Boolean] Show lines between rows
    attr_reader :show_lines

    # @return [Integer] Padding
    attr_reader :padding

    # @return [Boolean] Expand to full width
    attr_reader :expand

    # @return [Integer, nil] Fixed width
    attr_reader :width

    # @return [Array<Column>] Columns
    attr_reader :columns

    # @return [Array<Array<String>>] Rows
    attr_reader :rows

    def initialize(
      title: nil,
      caption: nil,
      box: Box::ROUNDED,
      border_style: nil,
      header_style: nil,
      title_style: nil,
      caption_style: nil,
      row_styles: nil,
      show_header: true,
      show_footer: false,
      show_edge: true,
      show_lines: false,
      padding: 1,
      expand: false,
      width: nil
    )
      @title = title
      @caption = caption
      @box = box
      @border_style = border_style.is_a?(String) ? Style.parse(border_style) : border_style
      @header_style = header_style.is_a?(String) ? Style.parse(header_style) : header_style
      @title_style = title_style.is_a?(String) ? Style.parse(title_style) : title_style
      @caption_style = caption_style.is_a?(String) ? Style.parse(caption_style) : caption_style
      @row_styles = row_styles
      @show_header = show_header
      @show_footer = show_footer
      @show_edge = show_edge
      @show_lines = show_lines
      @padding = padding
      @expand = expand
      @width = width

      @columns = []
      @rows = []
    end

    # Add a column
    # @param header [String] Column header
    # @param kwargs [Hash] Column options
    # @return [self]
    def add_column(header = "", **kwargs)
      @columns << Column.new(header, **kwargs)
      self
    end

    # Add a row
    # @param cells [Array] Cell contents
    # @return [self]
    def add_row(*cells)
      # Ensure we have enough columns
      while @columns.length < cells.length
        @columns << Column.new
      end

      @rows << cells.map(&:to_s)
      self
    end

    # @return [Integer] Number of columns
    def column_count
      @columns.length
    end

    # @return [Integer] Number of rows
    def row_count
      @rows.length
    end

    # Render table to segments
    # @param max_width [Integer] Maximum width
    # @return [Array<Segment>]
    def to_segments(max_width: 80)
      return [Segment.new("")] if @columns.empty?

      segments = []
      col_widths = calculate_column_widths(max_width)
      table_width = col_widths.sum + (@columns.length + 1) + @columns.length * @padding * 2

      # Title
      if @title && @show_edge
        segments.concat(render_title(table_width - 2))
        segments << Segment.new("\n")
      end

      # Top border
      if @show_edge
        segments.concat(render_top_border(col_widths))
        segments << Segment.new("\n")
      end

      # Header
      if @show_header
        segments.concat(render_header_row(col_widths))
        segments << Segment.new("\n")

        # Header separator
        segments.concat(render_header_separator(col_widths))
        segments << Segment.new("\n")
      end

      # Data rows
      @rows.each_with_index do |row, index|
        segments.concat(render_data_row(row, col_widths, index))
        segments << Segment.new("\n")

        # Row separator
        if @show_lines && index < @rows.length - 1
          segments.concat(render_row_separator(col_widths))
          segments << Segment.new("\n")
        end
      end

      # Footer
      if @show_footer && @columns.any? { |c| c.footer }
        segments.concat(render_footer_separator(col_widths))
        segments << Segment.new("\n")
        segments.concat(render_footer_row(col_widths))
        segments << Segment.new("\n")
      end

      # Bottom border
      if @show_edge
        segments.concat(render_bottom_border(col_widths))
        segments << Segment.new("\n")
      end

      # Caption
      if @caption && @show_edge
        segments.concat(render_caption(table_width - 2))
        segments << Segment.new("\n")
      end

      segments
    end

    # Render table to string
    # @param max_width [Integer] Maximum width
    # @param color_system [Symbol] Color system
    # @return [String]
    def render(max_width: 80, color_system: ColorSystem::TRUECOLOR)
      Segment.render(to_segments(max_width: max_width), color_system: color_system)
    end

    # Print table to console
    # @param console [Console] Console to print to
    def print_to(console)
      rendered = render(max_width: console.width, color_system: console.color_system)
      console.write(rendered)
    end

    private

    def calculate_column_widths(max_width)
      available = max_width - (@columns.length + 1) - @columns.length * @padding * 2

      # Calculate minimum width for each column
      widths = @columns.each_with_index.map do |col, i|
        header_width = Cells.cell_len(col.header)
        max_cell = @rows.map { |r| Cells.cell_len(r[i] || "") }.max || 0
        footer_width = col.footer ? Cells.cell_len(col.footer) : 0

        min = [header_width, max_cell, footer_width].max
        min = [min, col.min_width].max if col.min_width
        min = [min, col.max_width].min if col.max_width
        min
      end

      total = widths.sum
      if total > available && @expand
        # Need to shrink
        ratio = available.to_f / total
        widths = widths.map { |w| [(w * ratio).to_i, 3].max }
      elsif total < available && @expand
        # Distribute extra space
        extra = available - total
        per_col = extra / @columns.length
        widths = widths.map { |w| w + per_col }
      end

      widths
    end

    def render_title(width)
      segments = []
      title_width = Cells.cell_len(@title)
      padding = (width - title_width) / 2

      if @show_edge
        segments << Segment.new(@box.top_left, style: @border_style)
        segments << Segment.new(@box.horizontal * padding, style: @border_style)
        segments << Segment.new(" #{@title} ", style: @title_style)
        segments << Segment.new(@box.horizontal * (width - padding - title_width - 2), style: @border_style)
        segments << Segment.new(@box.top_right, style: @border_style)
      else
        segments << Segment.new(" " * padding + @title, style: @title_style)
      end

      segments
    end

    def render_caption(width)
      segments = []
      caption_width = Cells.cell_len(@caption)
      padding = (width - caption_width) / 2

      segments << Segment.new(" " * padding + @caption, style: @caption_style)
      segments
    end

    def render_top_border(col_widths)
      segments = []
      segments << Segment.new(@box.top_left, style: @border_style)

      col_widths.each_with_index do |w, i|
        cell_width = w + @padding * 2
        segments << Segment.new(@box.horizontal * cell_width, style: @border_style)
        if i < col_widths.length - 1
          segments << Segment.new(@box.top_t, style: @border_style)
        end
      end

      segments << Segment.new(@box.top_right, style: @border_style)
      segments
    end

    def render_bottom_border(col_widths)
      segments = []
      segments << Segment.new(@box.bottom_left, style: @border_style)

      col_widths.each_with_index do |w, i|
        cell_width = w + @padding * 2
        segments << Segment.new(@box.horizontal * cell_width, style: @border_style)
        if i < col_widths.length - 1
          segments << Segment.new(@box.bottom_t, style: @border_style)
        end
      end

      segments << Segment.new(@box.bottom_right, style: @border_style)
      segments
    end

    def render_row_separator(col_widths)
      segments = []
      segments << Segment.new(@box.left_t, style: @border_style)

      col_widths.each_with_index do |w, i|
        cell_width = w + @padding * 2
        segments << Segment.new(@box.horizontal * cell_width, style: @border_style)
        if i < col_widths.length - 1
          segments << Segment.new(@box.cross, style: @border_style)
        end
      end

      segments << Segment.new(@box.right_t, style: @border_style)
      segments
    end

    def render_header_separator(col_widths)
      segments = []
      segments << Segment.new(@box.thick_left_t, style: @border_style)

      col_widths.each_with_index do |w, i|
        cell_width = w + @padding * 2
        segments << Segment.new(@box.thick_horizontal * cell_width, style: @border_style)
        if i < col_widths.length - 1
          segments << Segment.new(@box.thick_cross, style: @border_style)
        end
      end

      segments << Segment.new(@box.thick_right_t, style: @border_style)
      segments
    end

    def render_footer_separator(col_widths)
      render_row_separator(col_widths)
    end

    def render_header_row(col_widths)
      segments = []
      segments << Segment.new(@box.vertical, style: @border_style)

      @columns.each_with_index do |col, i|
        width = col_widths[i]
        content = col.header
        cell_style = col.header_style || @header_style

        segments.concat(render_cell(content, width, col.justify, cell_style))

        segments << Segment.new(@box.vertical, style: @border_style)
      end

      segments
    end

    def render_footer_row(col_widths)
      segments = []
      segments << Segment.new(@box.vertical, style: @border_style)

      @columns.each_with_index do |col, i|
        width = col_widths[i]
        content = col.footer || ""
        cell_style = col.footer_style

        segments.concat(render_cell(content, width, col.justify, cell_style))

        segments << Segment.new(@box.vertical, style: @border_style)
      end

      segments
    end

    def render_data_row(row, col_widths, row_index)
      segments = []
      row_style = nil

      if @row_styles
        styles = @row_styles.is_a?(Array) ? @row_styles : [@row_styles]
        row_style = styles[row_index % styles.length]
        row_style = Style.parse(row_style) if row_style.is_a?(String)
      end

      segments << Segment.new(@box.vertical, style: @border_style)

      @columns.each_with_index do |col, i|
        width = col_widths[i]
        content = row[i] || ""
        cell_style = col.style || row_style

        segments.concat(render_cell(content, width, col.justify, cell_style))

        segments << Segment.new(@box.vertical, style: @border_style)
      end

      segments
    end

    def render_cell(content, width, justify, style)
      segments = []
      content_width = Cells.cell_len(content)

      # Truncate if needed
      if content_width > width
        case @columns.first&.overflow || :ellipsis
        when :ellipsis
          content = truncate_with_ellipsis(content, width)
          content_width = Cells.cell_len(content)
        when :crop
          content = truncate(content, width)
          content_width = Cells.cell_len(content)
        end
      end

      # Padding
      segments << Segment.new(" " * @padding)

      # Content with justification
      padding = width - content_width
      case justify
      when :right
        segments << Segment.new(" " * padding)
        segments << Segment.new(content, style: style)
      when :center
        left = padding / 2
        right = padding - left
        segments << Segment.new(" " * left)
        segments << Segment.new(content, style: style)
        segments << Segment.new(" " * right)
      else # :left
        segments << Segment.new(content, style: style)
        segments << Segment.new(" " * padding)
      end

      segments << Segment.new(" " * @padding)

      segments
    end

    def truncate(text, max_width)
      result = +""
      current_width = 0

      text.each_char do |char|
        char_width = Cells.char_width(char)
        break if current_width + char_width > max_width

        result << char
        current_width += char_width
      end

      result
    end

    def truncate_with_ellipsis(text, max_width)
      return text if Cells.cell_len(text) <= max_width
      return "…" if max_width <= 1

      truncate(text, max_width - 1) + "…"
    end
  end
end
