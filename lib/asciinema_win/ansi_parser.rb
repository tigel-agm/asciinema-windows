# frozen_string_literal: true

module AsciinemaWin
  # ANSI escape sequence parser for rendering colored output
  #
  # Parses ANSI SGR (Select Graphic Rendition) codes and converts
  # terminal output into structured data for SVG/HTML rendering.
  class AnsiParser
    # Character with style information
    StyledChar = Data.define(:char, :fg, :bg, :bold, :italic, :underline, :strikethrough) do
      # Check if this character has default styling
      #
      # @return [Boolean] True if no special styling applied
      def default_style?
        fg.nil? && bg.nil? && !bold && !italic && !underline && !strikethrough
      end

      # Check if style matches another character
      #
      # @param other [StyledChar] Other character to compare
      # @return [Boolean] True if styles match
      def same_style?(other)
        fg == other.fg &&
          bg == other.bg &&
          bold == other.bold &&
          italic == other.italic &&
          underline == other.underline &&
          strikethrough == other.strikethrough
      end
    end

    # Current text style state
    class StyleState
      # @return [Integer, nil] Foreground color (ANSI code or 256-color index)
      attr_accessor :fg

      # @return [Integer, nil] Background color (ANSI code or 256-color index)
      attr_accessor :bg

      # @return [Boolean] Bold/bright text
      attr_accessor :bold

      # @return [Boolean] Italic text
      attr_accessor :italic

      # @return [Boolean] Underlined text
      attr_accessor :underline

      # @return [Boolean] Strikethrough text
      attr_accessor :strikethrough

      # @return [String, nil] RGB foreground (#rrggbb)
      attr_accessor :fg_rgb

      # @return [String, nil] RGB background (#rrggbb)
      attr_accessor :bg_rgb

      def initialize
        reset
      end

      # Reset all attributes to default
      #
      # @return [void]
      def reset
        @fg = nil
        @bg = nil
        @bold = false
        @italic = false
        @underline = false
        @strikethrough = false
        @fg_rgb = nil
        @bg_rgb = nil
      end

      # Get effective foreground color
      #
      # @return [Integer, String, nil] Color value
      def effective_fg
        fg_rgb || fg
      end

      # Get effective background color
      #
      # @return [Integer, String, nil] Color value
      def effective_bg
        bg_rgb || bg
      end

      # Create a StyledChar from current state
      #
      # @param char [String] Character
      # @return [StyledChar] Styled character
      def to_styled_char(char)
        StyledChar.new(
          char: char,
          fg: effective_fg,
          bg: effective_bg,
          bold: @bold,
          italic: @italic,
          underline: @underline,
          strikethrough: @strikethrough
        )
      end
    end

    # Parsed line of styled characters
    ParsedLine = Data.define(:chars, :line_number)

    # @return [Array<ParsedLine>] Parsed lines
    attr_reader :lines

    # @return [Integer] Terminal width
    attr_reader :width

    # @return [Integer] Terminal height
    attr_reader :height

    # Initialize parser with terminal dimensions
    #
    # @param width [Integer] Terminal width in characters
    # @param height [Integer] Terminal height in lines
    def initialize(width:, height:)
      @width = width
      @height = height
      @lines = []
      @current_line = []
      @cursor_x = 0
      @cursor_y = 0
      @state = StyleState.new
    end

    # Parse ANSI content and build styled character grid
    #
    # @param content [String] Raw ANSI content
    # @return [Array<ParsedLine>] Parsed lines
    def parse(content)
      # Initialize empty grid
      @height.times do |y|
        @lines[y] = ParsedLine.new(
          chars: Array.new(@width) { @state.to_styled_char(" ") },
          line_number: y
        )
      end

      pos = 0
      while pos < content.length
        if content[pos] == "\e" && content[pos + 1] == "["
          # ANSI escape sequence
          end_pos = find_sequence_end(content, pos + 2)
          if end_pos
            sequence = content[pos + 2...end_pos]
            command = content[end_pos]
            process_escape(sequence, command)
            pos = end_pos + 1
          else
            pos += 1
          end
        elsif content[pos] == "\r"
          @cursor_x = 0
          pos += 1
        elsif content[pos] == "\n"
          @cursor_x = 0
          @cursor_y += 1
          scroll_if_needed
          pos += 1
        elsif content[pos] == "\t"
          # Tab - move to next 8-column boundary
          spaces = 8 - (@cursor_x % 8)
          spaces.times { write_char(" ") }
          pos += 1
        elsif content[pos] == "\b"
          # Backspace
          @cursor_x = [@cursor_x - 1, 0].max
          pos += 1
        elsif content[pos].ord >= 32 || content[pos].ord == 0
          write_char(content[pos])
          pos += 1
        else
          pos += 1
        end
      end

      @lines
    end

    private

    # Find end of ANSI escape sequence
    #
    # @param content [String] Content string
    # @param start [Integer] Start position
    # @return [Integer, nil] End position or nil
    def find_sequence_end(content, start)
      pos = start
      while pos < content.length
        char = content[pos]
        if char.match?(/[A-Za-z]/)
          return pos
        elsif char.match?(/[0-9;:?]/)
          pos += 1
        else
          return nil
        end
      end
      nil
    end

    # Process ANSI escape sequence
    #
    # @param sequence [String] Sequence parameters
    # @param command [String] Command character
    # @return [void]
    def process_escape(sequence, command)
      case command
      when "m"
        process_sgr(sequence)
      when "H", "f"
        # Cursor position
        parts = sequence.split(";")
        row = (parts[0] || "1").to_i - 1
        col = (parts[1] || "1").to_i - 1
        @cursor_y = [[row, 0].max, @height - 1].min
        @cursor_x = [[col, 0].max, @width - 1].min
      when "A"
        # Cursor up
        n = (sequence.empty? ? 1 : sequence.to_i)
        @cursor_y = [@cursor_y - n, 0].max
      when "B"
        # Cursor down
        n = (sequence.empty? ? 1 : sequence.to_i)
        @cursor_y = [@cursor_y + n, @height - 1].min
      when "C"
        # Cursor forward
        n = (sequence.empty? ? 1 : sequence.to_i)
        @cursor_x = [@cursor_x + n, @width - 1].min
      when "D"
        # Cursor back
        n = (sequence.empty? ? 1 : sequence.to_i)
        @cursor_x = [@cursor_x - n, 0].max
      when "J"
        # Erase in display
        n = sequence.empty? ? 0 : sequence.to_i
        erase_display(n)
      when "K"
        # Erase in line
        n = sequence.empty? ? 0 : sequence.to_i
        erase_line(n)
      when "G"
        # Cursor horizontal absolute
        col = (sequence.empty? ? 1 : sequence.to_i) - 1
        @cursor_x = [[col, 0].max, @width - 1].min
      end
    end

    # Process SGR (Select Graphic Rendition) codes
    #
    # @param sequence [String] Semicolon-separated codes
    # @return [void]
    def process_sgr(sequence)
      return @state.reset if sequence.empty?

      codes = sequence.split(";").map(&:to_i)
      i = 0

      while i < codes.length
        code = codes[i]

        case code
        when 0
          @state.reset
        when 1
          @state.bold = true
        when 3
          @state.italic = true
        when 4
          @state.underline = true
        when 9
          @state.strikethrough = true
        when 22
          @state.bold = false
        when 23
          @state.italic = false
        when 24
          @state.underline = false
        when 29
          @state.strikethrough = false
        when 30..37
          @state.fg = code
          @state.fg_rgb = nil
        when 38
          # Extended foreground color
          if codes[i + 1] == 5 && codes[i + 2]
            # 256 color
            @state.fg = codes[i + 2]
            @state.fg_rgb = nil
            i += 2
          elsif codes[i + 1] == 2 && codes[i + 4]
            # 24-bit RGB
            r = codes[i + 2]
            g = codes[i + 3]
            b = codes[i + 4]
            @state.fg_rgb = format("#%02x%02x%02x", r, g, b)
            @state.fg = nil
            i += 4
          end
        when 39
          @state.fg = nil
          @state.fg_rgb = nil
        when 40..47
          @state.bg = code
          @state.bg_rgb = nil
        when 48
          # Extended background color
          if codes[i + 1] == 5 && codes[i + 2]
            # 256 color
            @state.bg = codes[i + 2]
            @state.bg_rgb = nil
            i += 2
          elsif codes[i + 1] == 2 && codes[i + 4]
            # 24-bit RGB
            r = codes[i + 2]
            g = codes[i + 3]
            b = codes[i + 4]
            @state.bg_rgb = format("#%02x%02x%02x", r, g, b)
            @state.bg = nil
            i += 4
          end
        when 49
          @state.bg = nil
          @state.bg_rgb = nil
        when 90..97
          @state.fg = code
          @state.fg_rgb = nil
        when 100..107
          @state.bg = code
          @state.bg_rgb = nil
        end

        i += 1
      end
    end

    # Write character at current cursor position
    #
    # @param char [String] Character to write
    # @return [void]
    def write_char(char)
      return if @cursor_y >= @height

      if @cursor_x < @width
        # Update the character at current position
        old_line = @lines[@cursor_y]
        new_chars = old_line.chars.dup
        new_chars[@cursor_x] = @state.to_styled_char(char)
        @lines[@cursor_y] = ParsedLine.new(chars: new_chars, line_number: @cursor_y)
        @cursor_x += 1
      end

      # Handle line wrap
      if @cursor_x >= @width
        @cursor_x = 0
        @cursor_y += 1
        scroll_if_needed
      end
    end

    # Scroll screen if cursor goes past bottom
    #
    # @return [void]
    def scroll_if_needed
      return unless @cursor_y >= @height

      # Scroll up by one line
      @lines.shift
      @lines << ParsedLine.new(
        chars: Array.new(@width) { @state.to_styled_char(" ") },
        line_number: @height - 1
      )
      @cursor_y = @height - 1
    end

    # Erase in display
    #
    # @param mode [Integer] 0=cursor to end, 1=start to cursor, 2=entire
    # @return [void]
    def erase_display(mode)
      blank = @state.to_styled_char(" ")

      case mode
      when 0
        # Cursor to end
        erase_line(0)
        ((@cursor_y + 1)...@height).each do |y|
          @lines[y] = ParsedLine.new(chars: Array.new(@width) { blank }, line_number: y)
        end
      when 1
        # Start to cursor
        (0...@cursor_y).each do |y|
          @lines[y] = ParsedLine.new(chars: Array.new(@width) { blank }, line_number: y)
        end
        erase_line(1)
      when 2, 3
        # Entire screen
        @height.times do |y|
          @lines[y] = ParsedLine.new(chars: Array.new(@width) { blank }, line_number: y)
        end
      end
    end

    # Erase in line
    #
    # @param mode [Integer] 0=cursor to end, 1=start to cursor, 2=entire line
    # @return [void]
    def erase_line(mode)
      return if @cursor_y >= @height

      blank = @state.to_styled_char(" ")
      old_line = @lines[@cursor_y]
      new_chars = old_line.chars.dup

      case mode
      when 0
        # Cursor to end of line
        (@cursor_x...@width).each { |x| new_chars[x] = blank }
      when 1
        # Start of line to cursor
        (0..@cursor_x).each { |x| new_chars[x] = blank }
      when 2
        # Entire line
        @width.times { |x| new_chars[x] = blank }
      end

      @lines[@cursor_y] = ParsedLine.new(chars: new_chars, line_number: @cursor_y)
    end
  end
end
