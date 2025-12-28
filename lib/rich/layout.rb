# frozen_string_literal: true

require_relative "segment"
require_relative "cells"
require_relative "style"

module Rich
  # Display content side by side in columns
  class Columns
    # @return [Array] Items to display
    attr_reader :items

    # @return [Integer, nil] Column count
    attr_reader :column_count

    # @return [Integer] Padding between columns
    attr_reader :padding

    # @return [Boolean] Equal width columns
    attr_reader :equal

    # @return [Boolean] Expand to fill width
    attr_reader :expand

    def initialize(
      items = [],
      column_count: nil,
      padding: 1,
      equal: false,
      expand: true
    )
      @items = items.to_a
      @column_count = column_count
      @padding = padding
      @equal = equal
      @expand = expand
    end

    # Add an item
    # @param item [Object] Item to add
    # @return [self]
    def add(item)
      @items << item
      self
    end

    # Render to segments
    # @param max_width [Integer] Maximum width
    # @return [Array<Segment>]
    def to_segments(max_width: 80)
      return [] if @items.empty?

      segments = []

      # Calculate column count if not specified
      num_columns = @column_count || calculate_column_count(max_width)
      num_columns = [num_columns, @items.length].min

      # Calculate column widths
      col_widths = calculate_widths(max_width, num_columns)

      # Render items in rows
      @items.each_slice(num_columns) do |row_items|
        row_items.each_with_index do |item, col_index|
          content = item.to_s
          width = col_widths[col_index]

          # Render content
          content_width = Cells.cell_len(content)
          if content_width > width
            content = truncate(content, width)
            content_width = Cells.cell_len(content)
          end

          segments << Segment.new(content)
          segments << Segment.new(" " * (width - content_width))

          # Padding between columns (not after last)
          if col_index < row_items.length - 1
            segments << Segment.new(" " * @padding)
          end
        end

        segments << Segment.new("\n")
      end

      segments
    end

    # Render to string
    # @param max_width [Integer] Maximum width
    # @param color_system [Symbol] Color system
    # @return [String]
    def render(max_width: 80, color_system: ColorSystem::TRUECOLOR)
      Segment.render(to_segments(max_width: max_width), color_system: color_system)
    end

    private

    def calculate_column_count(max_width)
      return 1 if @items.empty?

      # Calculate based on average item width
      avg_width = @items.map { |i| Cells.cell_len(i.to_s) }.sum / @items.length
      min_col_width = [avg_width, 10].max

      ((max_width + @padding) / (min_col_width + @padding)).clamp(1, 10)
    end

    def calculate_widths(max_width, num_columns)
      available = max_width - (@padding * (num_columns - 1))

      if @equal
        width = available / num_columns
        Array.new(num_columns, width)
      else
        # Calculate based on content
        widths = Array.new(num_columns, 0)

        @items.each_with_index do |item, index|
          col = index % num_columns
          item_width = Cells.cell_len(item.to_s)
          widths[col] = [widths[col], item_width].max
        end

        # Scale if total exceeds available
        total = widths.sum
        if total > available
          ratio = available.to_f / total
          widths.map! { |w| [( w * ratio).to_i, 5].max }
        elsif @expand
          extra = (available - total) / num_columns
          widths.map! { |w| w + extra }
        end

        widths
      end
    end

    def truncate(text, max_width)
      result = +""
      current = 0

      text.each_char do |char|
        char_width = Cells.char_width(char)
        break if current + char_width > max_width

        result << char
        current += char_width
      end

      result
    end
  end

  # Live updating display
  class Live
    # @return [Console] Console for output
    attr_reader :console

    # @return [Float] Refresh rate
    attr_reader :refresh_rate

    # @return [Boolean] Transient (clear on exit)
    attr_reader :transient

    # Default refresh rate (Windows is slower)
    DEFAULT_REFRESH = Gem.win_platform? ? 0.2 : 0.1

    def initialize(
      console: nil,
      refresh_rate: DEFAULT_REFRESH,
      transient: false
    )
      @console = console || Console.new
      @refresh_rate = refresh_rate
      @transient = transient
      @renderable = nil
      @started = false
      @lines_rendered = 0
      @last_render = nil
    end

    # Update the renderable content
    # @param renderable [Object] Content to display
    def update(renderable)
      @renderable = renderable
      refresh
    end

    # Start live display
    # @yield Block to execute with live updates
    def start
      @started = true
      @console.hide_cursor

      if block_given?
        begin
          yield self
        ensure
          stop
        end
      end
    end

    # Stop live display
    def stop
      return unless @started

      if @transient && @lines_rendered > 0
        # Clear rendered content
        @console.write("\e[#{@lines_rendered}A\e[J")
      end

      @console.show_cursor
      @started = false
    end

    # Refresh display if needed
    def refresh
      return unless @started
      return unless @renderable

      now = Time.now
      return if @last_render && now - @last_render < @refresh_rate

      render_update
      @last_render = now
    end

    private

    def render_update
      # Clear previous output
      if @lines_rendered > 0
        @console.write("\e[#{@lines_rendered}A\e[J")
      end

      # Render new content
      output = render_content(@renderable)
      @console.write(output)

      # Count lines
      @lines_rendered = output.count("\n")
    end

    def render_content(obj)
      case obj
      when Panel, Table, Tree
        obj.render(max_width: @console.width, color_system: @console.color_system)
      else
        "#{obj}\n"
      end
    end
  end

  # Status display with spinner
  class Status
    # @return [Spinner] Spinner animation
    attr_reader :spinner

    # @return [String] Status message
    attr_accessor :message

    # @return [Console] Console
    attr_reader :console

    def initialize(message = "", console: nil, spinner: nil)
      @message = message
      @console = console || Console.new
      @spinner = spinner || Spinner.new
      @started = false
    end

    # Start status display
    # @yield Block to execute
    def start
      @started = true
      @console.hide_cursor

      if block_given?
        begin
          yield self
        ensure
          stop
        end
      end
    end

    # Stop status display
    def stop
      return unless @started

      @console.write("\r\e[K")
      @console.show_cursor
      @started = false
    end

    # Update message
    # @param new_message [String] New message
    def update(new_message)
      @message = new_message
      refresh
    end

    # Refresh display
    def refresh
      return unless @started

      @spinner.update
      @console.write("\r\e[K#{@spinner.frame} #{@message}")
    end
  end
end
