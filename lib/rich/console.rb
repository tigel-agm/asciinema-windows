# frozen_string_literal: true

require_relative "color"
require_relative "style"
require_relative "segment"
require_relative "control"
require_relative "cells"
require_relative "terminal_theme"
require_relative "win32_console" if Gem.win_platform?

module Rich
  # Console rendering options
  class ConsoleOptions
    # @return [Integer] Minimum width for rendering
    attr_reader :min_width

    # @return [Integer] Maximum width for rendering
    attr_reader :max_width

    # @return [Integer, nil] Height for rendering
    attr_reader :height

    # @return [Boolean] Legacy Windows console mode
    attr_reader :legacy_windows

    # @return [String] Output encoding
    attr_reader :encoding

    # @return [Boolean] Terminal output
    attr_reader :is_terminal

    # @return [Boolean] Enable highlighting
    attr_reader :highlight

    # @return [Boolean] Enable markup
    attr_reader :markup

    # @return [Boolean] No wrapping
    attr_reader :no_wrap

    def initialize(
      min_width: 1,
      max_width: 80,
      height: nil,
      legacy_windows: false,
      encoding: "utf-8",
      is_terminal: true,
      highlight: true,
      markup: true,
      no_wrap: false
    )
      @min_width = min_width
      @max_width = max_width
      @height = height
      @legacy_windows = legacy_windows
      @encoding = encoding
      @is_terminal = is_terminal
      @highlight = highlight
      @markup = markup
      @no_wrap = no_wrap
      freeze
    end

    # Update options, returning a new instance
    # @return [ConsoleOptions]
    def update(**kwargs)
      ConsoleOptions.new(
        min_width: kwargs.fetch(:min_width, @min_width),
        max_width: kwargs.fetch(:max_width, @max_width),
        height: kwargs.fetch(:height, @height),
        legacy_windows: kwargs.fetch(:legacy_windows, @legacy_windows),
        encoding: kwargs.fetch(:encoding, @encoding),
        is_terminal: kwargs.fetch(:is_terminal, @is_terminal),
        highlight: kwargs.fetch(:highlight, @highlight),
        markup: kwargs.fetch(:markup, @markup),
        no_wrap: kwargs.fetch(:no_wrap, @no_wrap)
      )
    end

    # Update width
    # @param width [Integer] New width
    # @return [ConsoleOptions]
    def update_width(width)
      update(min_width: width, max_width: width)
    end
  end

  # Main console class for terminal output
  class Console
    # @return [IO] Output file
    attr_reader :file

    # @return [Symbol] Color system
    attr_reader :color_system

    # @return [Boolean] Force terminal mode
    attr_reader :force_terminal

    # @return [Boolean] Enable markup
    attr_reader :markup

    # @return [Boolean] Enable highlighting
    attr_reader :highlight

    # @return [Integer, nil] Override width
    attr_reader :width_override

    # @return [Integer, nil] Override height
    attr_reader :height_override

    # @return [Style, nil] Default style
    attr_reader :style

    # @return [Boolean] Safe output (escape HTML)
    attr_reader :safe_box

    # @return [TerminalTheme] Terminal theme
    attr_reader :theme

    # Default refresh rate for progress/live (Hz)
    DEFAULT_REFRESH_RATE = Gem.win_platform? ? 5 : 10

    def initialize(
      file: $stdout,
      color_system: nil,
      force_terminal: nil,
      markup: true,
      highlight: true,
      width: nil,
      height: nil,
      style: nil,
      safe_box: true,
      theme: nil
    )
      @file = file
      @force_terminal = force_terminal
      @markup = markup
      @highlight = highlight
      @width_override = width
      @height_override = height
      @style = style.is_a?(String) ? Style.parse(style) : style
      @safe_box = safe_box
      @theme = theme || DEFAULT_TERMINAL_THEME

      @color_system = color_system || detect_color_system
      @legacy_windows = detect_legacy_windows

      # Enable ANSI on Windows if possible
      if Gem.win_platform? && defined?(Win32Console)
        Win32Console.enable_ansi!
      end
    end

    # @return [Boolean] Whether output is a terminal
    def is_terminal?
      return @force_terminal unless @force_terminal.nil?
      @file.respond_to?(:tty?) && @file.tty?
    end

    # @return [Boolean] Is output a terminal
    def terminal?
      return @force_terminal unless @force_terminal.nil?
      return false unless @file.respond_to?(:tty?)

      @file.tty?
    end

    # @return [Boolean] Is this a legacy Windows console
    def legacy_windows?
      @legacy_windows
    end

    # @return [Integer] Console width in characters
    def width
      return @width_override if @width_override

      detect_size[0]
    end

    # @return [Integer] Console height in characters
    def height
      return @height_override if @height_override

      detect_size[1]
    end

    # @return [Array<Integer>] [width, height]
    def size
      [width, height]
    end

    # Get console options for rendering
    # @return [ConsoleOptions]
    def options
      ConsoleOptions.new(
        min_width: 1,
        max_width: width,
        height: height,
        legacy_windows: @legacy_windows,
        encoding: encoding,
        is_terminal: terminal?,
        highlight: @highlight,
        markup: @markup
      )
    end

    # @return [String] Output encoding
    def encoding
      @file.respond_to?(:encoding) ? @file.encoding.to_s : "utf-8"
    end

    # Print objects to the console
    # @param objects [Array] Objects to print
    # @param sep [String] Separator
    # @param end_str [String] End string
    # @param style [String, Style, nil] Style
    # @param highlight [Boolean] Enable highlighting
    # @return [void]
    def print(*objects, sep: " ", end_str: "\n", style: nil, highlight: nil)
      highlight = @highlight if highlight.nil?

      text = objects.map do |obj|
        render_object(obj, highlight: highlight)
      end.join(sep)

      text += end_str

      if style
        applied_style = style.is_a?(String) ? Style.parse(style) : style
        write_styled(text, applied_style)
      else
        write(text)
      end
    end

    # Print with markup parsing
    # @param text [String] Text with markup
    # @return [void]
    def print_markup(text)
      segments = parse_markup(text)
      write_segments(segments)
    end

    # Print JSON with highlighting
    # @param json [String, nil] JSON string
    # @param data [Object] Data to convert
    # @param indent [Integer] Indentation
    # @return [void]
    def print_json(json = nil, data: nil, indent: 2)
      require "json"

      json_str = json || JSON.pretty_generate(data, indent: " " * indent)

      if @highlight
        # Colorize JSON
        highlighted = colorize_json(json_str)
        print(highlighted)
      else
        print(json_str)
      end
    end

    # Print a horizontal rule
    # @param title [String] Title
    # @param style [String] Style
    # @return [void]
    def rule(title = "", style: "rule.line")
      console_width = width
      rule_style = Style.parse(style)

      if title.empty?
        line = "─" * console_width
        write_styled(line + "\n", rule_style)
      else
        title_length = Cells.cell_len(title) + 2
        remaining = console_width - title_length

        if remaining > 0
          left_width = remaining / 2
          right_width = remaining - left_width
          line = "─" * left_width + " #{title} " + "─" * right_width
        else
          line = title
        end

        write_styled(line + "\n", rule_style)
      end
    end

    # Clear the screen
    # @return [void]
    def clear
      if @legacy_windows && defined?(Win32Console)
        Win32Console.clear_screen
      else
        write(Control.clear_screen)
      end
    end

    # Show the cursor
    # @return [void]
    def show_cursor
      if @legacy_windows && defined?(Win32Console)
        Win32Console.show_cursor
      else
        write(Control.show_cursor)
      end
    end

    # Hide the cursor
    # @return [void]
    def hide_cursor
      if @legacy_windows && defined?(Win32Console)
        Win32Console.hide_cursor
      else
        write(Control.hide_cursor)
      end
    end

    # Set window title
    # @param title [String] Window title
    # @return [void]
    def set_title(title)
      if @legacy_windows && defined?(Win32Console)
        Win32Console.set_title(title)
      else
        write(Control.set_title(title))
      end
    end

    # Write raw text
    # @param text [String] Text to write
    # @return [void]
    def write(text)
      @file.write(text)
      @file.flush if @file.respond_to?(:flush)
    end

    # Write styled text
    # @param text [String] Text to write
    # @param style [Style] Style to apply
    # @return [void]
    def write_styled(text, style)
      if @legacy_windows && defined?(Win32Console)
        write_styled_legacy(text, style)
      else
        rendered = style.render(color_system: @color_system)
        write("#{rendered}#{text}\e[0m")
      end
    end

    # Write segments to output
    # @param segments [Array<Segment>] Segments to write
    # @return [void]
    def write_segments(segments)
      rendered = Segment.render(segments, color_system: @color_system)
      write(rendered)
    end

    # Inspect an object
    # @param obj [Object] Object to inspect
    # @param title [String, nil] Title
    # @param methods [Boolean] Show methods
    # @param docs [Boolean] Show docs
    # @return [void]
    def inspect(obj, title: nil, methods: false, docs: true)
      title ||= obj.class.name

      rule(title, style: "bold")

      print("Class: #{obj.class}")
      print("Object ID: #{obj.object_id}")

      if obj.respond_to?(:instance_variables)
        ivars = obj.instance_variables
        unless ivars.empty?
          print("\nInstance Variables:")
          ivars.each do |ivar|
            value = obj.instance_variable_get(ivar)
            print("  #{ivar}: #{value.inspect}")
          end
        end
      end

      if methods && obj.respond_to?(:methods)
        obj_methods = (obj.methods - Object.methods).sort
        unless obj_methods.empty?
          print("\nMethods:")
          obj_methods.each do |method|
            print("  #{method}")
          end
        end
      end

      rule(style: "bold")
    end

    private

    def detect_color_system
      return ColorSystem::WINDOWS if Gem.win_platform? && !ansi_supported?

      # Check terminal capabilities
      term = ENV["TERM"] || ""
      colorterm = ENV["COLORTERM"] || ""

      if colorterm.downcase.include?("truecolor") || colorterm.downcase.include?("24bit")
        return ColorSystem::TRUECOLOR
      end

      if term.include?("256color") || ENV["TERM_PROGRAM"] == "iTerm.app"
        return ColorSystem::EIGHT_BIT
      end

      if %w[xterm vt100 screen].any? { |t| term.include?(t) }
        return ColorSystem::STANDARD
      end

      # Default to truecolor for modern terminals
      ColorSystem::TRUECOLOR
    end

    def detect_legacy_windows
      return false unless Gem.win_platform?
      return false if ansi_supported?

      true
    end

    def ansi_supported?
      return true unless Gem.win_platform?
      return true unless defined?(Win32Console)

      Win32Console.supports_ansi?
    end

    def detect_size
      # Try Ruby's built-in IO#winsize
      if @file.respond_to?(:winsize)
        begin
          height, width = @file.winsize
          return [width, height] if width > 0 && height > 0
        rescue StandardError
          # Fall through
        end
      end

      # Try Windows API
      if Gem.win_platform? && defined?(Win32Console)
        size = Win32Console.get_size
        return size if size
      end

      # Try environment variables
      cols = ENV["COLUMNS"]&.to_i
      rows = ENV["LINES"]&.to_i
      return [cols, rows] if cols && cols > 0 && rows && rows > 0

      # Default
      [80, 24]
    end

    def render_object(obj, highlight: true)
      case obj
      when String
        if @markup
          render_markup(obj)
        else
          obj
        end
      when Segment
        obj.text
      else
        obj.to_s
      end
    end

    def render_markup(text)
      # Simple markup rendering - just remove tags for now
      # Full implementation in markup.rb
      text.gsub(/\[\/?\w+[^\]]*\]/, "")
    end

    def parse_markup(text)
      # Simple markup parser - converts [style]text[/style] to segments
      segments = []
      style_stack = []
      pos = 0

      tag_regex = /\[(?<close>\/)?(?<style>[^\]]+)\]/

      text.scan(tag_regex) do
        match = Regexp.last_match
        match_start = match.begin(0)

        # Add text before tag
        if match_start > pos
          current_style = style_stack.empty? ? nil : style_stack.reduce { |a, b| a + b }
          segments << Segment.new(text[pos...match_start], style: current_style)
        end

        if match[:close]
          style_stack.pop
        else
          parsed_style = Style.parse(match[:style])
          style_stack.push(parsed_style)
        end

        pos = match.end(0)
      end

      # Add remaining text
      if pos < text.length
        current_style = style_stack.empty? ? nil : style_stack.reduce { |a, b| a + b }
        segments << Segment.new(text[pos..], style: current_style)
      end

      segments
    end

    def colorize_json(json_str)
      # Simple JSON colorization
      json_str
        .gsub(/"([^"]+)"(?=\s*:)/) { "[cyan]\"#{Regexp.last_match(1)}\"[/]" }  # Keys
        .gsub(/:\s*"([^"]*)"/) { ": [green]\"#{Regexp.last_match(1)}\"[/]" }   # String values
        .gsub(/:\s*(\d+\.?\d*)/) { ": [yellow]#{Regexp.last_match(1)}[/]" }    # Numbers
        .gsub(/:\s*(true|false)/) { ": [italic]#{Regexp.last_match(1)}[/]" }   # Booleans
        .gsub(/:\s*null/) { ": [dim]null[/]" }                                  # Null
    end

    def write_styled_legacy(text, style)
      return write(text) unless defined?(Win32Console)

      # Map style to Windows console attributes
      fg = style.color&.number || 7
      bg = style.bgcolor&.number || 0

      # Apply bold as bright
      fg |= 8 if style.bold?

      attributes = Win32Console.ansi_to_windows_attributes(foreground: fg, background: bg)
      original_attrs = Win32Console.get_text_attributes

      Win32Console.set_text_attribute(attributes)
      write(text)
      Win32Console.set_text_attribute(original_attrs) if original_attrs
    end
  end
end
