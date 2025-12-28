# frozen_string_literal: true

require_relative "box"
require_relative "style"
require_relative "segment"
require_relative "cells"
require_relative "text"

module Rich
  # A bordered panel container for content
  class Panel
    # @return [Object] Content to display
    attr_reader :content

    # @return [String, nil] Panel title
    attr_reader :title

    # @return [String, nil] Panel subtitle
    attr_reader :subtitle

    # @return [Box] Box style
    attr_reader :box

    # @return [Style, nil] Border style
    attr_reader :border_style

    # @return [Style, nil] Title style
    attr_reader :title_style

    # @return [Style, nil] Subtitle style
    attr_reader :subtitle_style

    # @return [Boolean] Expand to fill width
    attr_reader :expand

    # @return [Integer] Padding inside panel
    attr_reader :padding

    # @return [Integer, nil] Fixed width
    attr_reader :width

    # @return [Symbol] Title alignment
    attr_reader :title_align

    def initialize(
      content,
      title: nil,
      subtitle: nil,
      box: Box::ROUNDED,
      border_style: nil,
      title_style: nil,
      subtitle_style: nil,
      expand: true,
      padding: 1,
      width: nil,
      title_align: :center
    )
      @content = content
      @title = title
      @subtitle = subtitle
      @box = box
      @border_style = border_style.is_a?(String) ? Style.parse(border_style) : border_style
      @title_style = title_style.is_a?(String) ? Style.parse(title_style) : title_style
      @subtitle_style = subtitle_style.is_a?(String) ? Style.parse(subtitle_style) : subtitle_style
      @expand = expand
      @padding = padding
      @width = width
      @title_align = title_align
    end

    # Render panel to segments
    # @param max_width [Integer] Maximum width
    # @return [Array<Segment>]
    def to_segments(max_width: 80)
      segments = []
      inner_width = calculate_inner_width(max_width)
      content_width = inner_width - @padding * 2

      # Render content to lines
      content_lines = render_content(content_width)

      # Top border with title
      segments.concat(render_top_border(inner_width))
      segments << Segment.new("\n")

      # Padding top
      @padding.times do
        segments.concat(render_empty_row(inner_width))
        segments << Segment.new("\n")
      end

      # Content rows
      content_lines.each do |line|
        segments.concat(render_content_row(line, inner_width))
        segments << Segment.new("\n")
      end

      # Padding bottom
      @padding.times do
        segments.concat(render_empty_row(inner_width))
        segments << Segment.new("\n")
      end

      # Bottom border with subtitle
      segments.concat(render_bottom_border(inner_width))

      segments
    end

    # Render panel to string with ANSI codes
    # @param max_width [Integer] Maximum width
    # @param color_system [Symbol] Color system
    # @return [String]
    def render(max_width: 80, color_system: ColorSystem::TRUECOLOR)
      Segment.render(to_segments(max_width: max_width), color_system: color_system)
    end

    # Print panel to console
    # @param console [Console] Console to print to
    def print_to(console)
      rendered = render(max_width: console.width, color_system: console.color_system)
      console.write(rendered)
      console.write("\n")
    end

    class << self
      # Create a simple panel
      # @param content [String] Content
      # @param title [String, nil] Title
      # @return [Panel]
      def fit(content, title: nil)
        new(content, title: title, expand: false)
      end
    end

    private

    def calculate_inner_width(max_width)
      if @width
        @width - 2 # Subtract borders
      elsif @expand
        max_width - 2
      else
        content_width = measure_content_width + @padding * 2
        [content_width, max_width - 2].min
      end
    end

    def measure_content_width
      case @content
      when String
        Cells.cell_len(@content)
      when Text
        @content.cell_length
      else
        Cells.cell_len(@content.to_s)
      end
    end

    def render_content(width)
      case @content
      when String
        wrap_text(@content, width)
      when Text
        @content.wrap(width).map { |t| t.to_segments }
      else
        wrap_text(@content.to_s, width)
      end
    end

    def wrap_text(text, width)
      lines = []
      text.split("\n").each do |line|
        if Cells.cell_len(line) <= width
          lines << [Segment.new(line)]
        else
          # Simple wrapping
          current_line = +""
          current_width = 0

          line.each_char do |char|
            char_width = Cells.char_width(char)
            if current_width + char_width > width
              lines << [Segment.new(current_line)]
              current_line = +char
              current_width = char_width
            else
              current_line << char
              current_width += char_width
            end
          end

          lines << [Segment.new(current_line)] unless current_line.empty?
        end
      end
      lines
    end

    def render_top_border(inner_width)
      segments = []

      if @title
        title_text = " #{@title} "
        title_width = Cells.cell_len(title_text)

        if title_width < inner_width
          remaining = inner_width - title_width
          case @title_align
          when :left
            left = 2
            right = remaining - 2
          when :right
            left = remaining - 2
            right = 2
          else # :center
            left = remaining / 2
            right = remaining - left
          end

          segments << Segment.new(@box.top_left, style: @border_style)
          segments << Segment.new(@box.horizontal * left, style: @border_style)
          segments << Segment.new(title_text, style: @title_style || @border_style)
          segments << Segment.new(@box.horizontal * right, style: @border_style)
          segments << Segment.new(@box.top_right, style: @border_style)
        else
          segments << Segment.new(@box.top_edge(inner_width), style: @border_style)
        end
      else
        segments << Segment.new(@box.top_left, style: @border_style)
        segments << Segment.new(@box.horizontal * inner_width, style: @border_style)
        segments << Segment.new(@box.top_right, style: @border_style)
      end

      segments
    end

    def render_bottom_border(inner_width)
      segments = []

      if @subtitle
        sub_text = " #{@subtitle} "
        sub_width = Cells.cell_len(sub_text)

        if sub_width < inner_width
          remaining = inner_width - sub_width
          case @title_align
          when :left
            left = 2
            right = remaining - 2
          when :right
            left = remaining - 2
            right = 2
          else # :center
            left = remaining / 2
            right = remaining - left
          end

          segments << Segment.new(@box.bottom_left, style: @border_style)
          segments << Segment.new(@box.horizontal * left, style: @border_style)
          segments << Segment.new(sub_text, style: @subtitle_style || @border_style)
          segments << Segment.new(@box.horizontal * right, style: @border_style)
          segments << Segment.new(@box.bottom_right, style: @border_style)
        else
          segments << Segment.new(@box.bottom_edge(inner_width), style: @border_style)
        end
      else
        segments << Segment.new(@box.bottom_left, style: @border_style)
        segments << Segment.new(@box.horizontal * inner_width, style: @border_style)
        segments << Segment.new(@box.bottom_right, style: @border_style)
      end

      segments
    end

    def render_content_row(content_segments, inner_width)
      segments = []

      # Left border
      segments << Segment.new(@box.vertical, style: @border_style)

      # Left padding
      segments << Segment.new(" " * @padding)

      # Content
      content_width = content_segments.sum(&:cell_length)
      segments.concat(content_segments)

      # Right padding (fill to width)
      remaining = inner_width - @padding * 2 - content_width
      segments << Segment.new(" " * [remaining, 0].max)

      # Right padding
      segments << Segment.new(" " * @padding)

      # Right border
      segments << Segment.new(@box.vertical, style: @border_style)

      segments
    end

    def render_empty_row(inner_width)
      segments = []

      segments << Segment.new(@box.vertical, style: @border_style)
      segments << Segment.new(" " * inner_width)
      segments << Segment.new(@box.vertical, style: @border_style)

      segments
    end
  end
end
