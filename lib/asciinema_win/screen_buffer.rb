# frozen_string_literal: true

require "stringio"

module AsciinemaWin
  # Represents a captured screen buffer state with delta detection capabilities
  #
  # This class captures the terminal screen buffer including:
  # - Character content for each cell
  # - Color/attribute information for each cell
  # - Cursor position
  # - Terminal dimensions
  #
  # @example Capture and compare screen states
  #   buffer1 = ScreenBuffer.capture
  #   # ... terminal content changes ...
  #   buffer2 = ScreenBuffer.capture
  #   diff = buffer2.diff(buffer1)
  #   puts diff  # ANSI escape sequences to transform buffer1 to buffer2
  class ScreenBuffer
    # Cell data structure representing a single character cell
    # @!attribute [r] char
    #   @return [String] The character in this cell
    # @!attribute [r] foreground
    #   @return [Integer] Foreground color (ANSI color number 0-15 or 256-color/RGB)
    # @!attribute [r] background
    #   @return [Integer] Background color (ANSI color number 0-15 or 256-color/RGB)
    # @!attribute [r] attributes
    #   @return [Integer] Windows console attribute value (raw)
    Cell = Data.define(:char, :foreground, :background, :attributes) do
      # @return [Boolean] True if cell is empty (space with default colors)
      def empty?
        (char == " " || char == "\0") && foreground == 7 && background == 0
      end

      # @return [Boolean] True if this cell equals another
      def ==(other)
        return false unless other.is_a?(Cell)

        char == other.char &&
          foreground == other.foreground &&
          background == other.background
      end

      alias eql? ==

      # @return [Integer] Hash code for this cell
      def hash
        [char, foreground, background].hash
      end
    end

    # @return [Integer] Screen width in characters
    attr_reader :width

    # @return [Integer] Screen height in characters
    attr_reader :height

    # @return [Integer] Cursor X position (0-indexed)
    attr_reader :cursor_x

    # @return [Integer] Cursor Y position (0-indexed)
    attr_reader :cursor_y

    # @return [Float] Timestamp when this buffer was captured (monotonic clock)
    attr_reader :timestamp

    # @return [Array<Array<Cell>>] 2D array of cells [row][col]
    attr_reader :cells

    # Create a new ScreenBuffer with the given dimensions
    #
    # @param width [Integer] Screen width
    # @param height [Integer] Screen height
    # @param cursor_x [Integer] Cursor X position
    # @param cursor_y [Integer] Cursor Y position
    # @param timestamp [Float, nil] Capture timestamp (defaults to current time)
    def initialize(width:, height:, cursor_x: 0, cursor_y: 0, timestamp: nil)
      @width = width
      @height = height
      @cursor_x = cursor_x
      @cursor_y = cursor_y
      @timestamp = timestamp || Process.clock_gettime(Process::CLOCK_MONOTONIC)
      @cells = Array.new(height) { Array.new(width) { empty_cell } }
    end

    # Capture the current screen buffer state from the Windows console
    #
    # @return [ScreenBuffer, nil] Captured buffer or nil if capture fails
    # @raise [PlatformError] If not running on Windows
    def self.capture
      unless Gem.win_platform?
        raise PlatformError, "Screen buffer capture requires Windows"
      end

      unless defined?(Rich::Win32Console)
        require_relative "../rich/win32_console"
      end

      buffer_data = Rich::Win32Console.capture_screen_buffer
      return nil unless buffer_data

      from_win32_data(buffer_data)
    end

    # Create a ScreenBuffer from Win32Console capture data
    #
    # @param data [Hash] Data from Win32Console.capture_screen_buffer
    # @return [ScreenBuffer]
    def self.from_win32_data(data)
      buffer = new(
        width: data[:width],
        height: data[:height],
        cursor_x: data[:cursor_x],
        cursor_y: data[:cursor_y]
      )

      data[:lines].each_with_index do |line, row|
        chars = line[:chars]
        attributes = line[:attributes]

        chars.each_char.with_index do |char, col|
          break if col >= buffer.width

          attr = attributes[col] || 0
          fg, bg = parse_windows_attributes(attr)

          buffer.set_cell(row, col, Cell.new(
            char: char,
            foreground: fg,
            background: bg,
            attributes: attr
          ))
        end
      end

      buffer
    end

    # Parse Windows console attributes into foreground and background colors
    #
    # @param attributes [Integer] Windows console attribute value
    # @return [Array<Integer, Integer>] [foreground, background] ANSI color numbers
    def self.parse_windows_attributes(attributes)
      # Extract foreground (bits 0-3)
      fg = attributes & 0x0F

      # Extract background (bits 4-7)
      bg = (attributes >> 4) & 0x0F

      [fg, bg]
    end

    # Set a cell at the given position
    #
    # @param row [Integer] Row index (0-indexed)
    # @param col [Integer] Column index (0-indexed)
    # @param cell [Cell] Cell to set
    # @return [void]
    def set_cell(row, col, cell)
      return if row < 0 || row >= @height || col < 0 || col >= @width

      @cells[row][col] = cell
    end

    # Get a cell at the given position
    #
    # @param row [Integer] Row index (0-indexed)
    # @param col [Integer] Column index (0-indexed)
    # @return [Cell, nil] Cell at position or nil if out of bounds
    def get_cell(row, col)
      return nil if row < 0 || row >= @height || col < 0 || col >= @width

      @cells[row][col]
    end

    # Compare this buffer with another and generate ANSI diff
    #
    # Produces the minimal ANSI escape sequence needed to transform
    # the other buffer's display into this buffer's display.
    #
    # @param other [ScreenBuffer, nil] Previous buffer state (nil = empty screen)
    # @return [String] ANSI escape sequences to apply the changes
    def diff(other = nil)
      output = StringIO.new

      # If no previous buffer, render everything
      if other.nil?
        output << to_ansi
        return output.string
      end

      # Track what needs to be updated
      changes = []

      @height.times do |row|
        @width.times do |col|
          current = get_cell(row, col)
          previous = other.get_cell(row, col)

          # Only emit changes
          if current != previous
            changes << { row: row, col: col, cell: current }
          end
        end
      end

      # If more than 50% changed, just redraw the whole screen
      total_cells = @width * @height
      if changes.length > total_cells / 2
        output << "\e[H"  # Move to home
        output << to_ansi
        return output.string
      end

      # Apply incremental changes
      last_row = -1
      last_col = -1
      last_fg = nil
      last_bg = nil

      changes.each do |change|
        row = change[:row]
        col = change[:col]
        cell = change[:cell]

        # Move cursor if needed
        if row != last_row || col != last_col + 1
          output << "\e[#{row + 1};#{col + 1}H"
        end

        # Set colors if changed
        if cell.foreground != last_fg || cell.background != last_bg
          output << ansi_color_code(cell.foreground, cell.background)
          last_fg = cell.foreground
          last_bg = cell.background
        end

        output << cell.char

        last_row = row
        last_col = col
      end

      # Handle cursor position change
      if @cursor_x != other.cursor_x || @cursor_y != other.cursor_y
        output << "\e[#{@cursor_y + 1};#{@cursor_x + 1}H"
      end

      output.string
    end

    # Convert entire buffer to ANSI escape sequence string
    #
    # @return [String] Full ANSI representation of the screen buffer
    def to_ansi
      output = StringIO.new
      last_fg = nil
      last_bg = nil

      @cells.each_with_index do |row_cells, row|
        row_cells.each do |cell|
          # Set colors if changed
          if cell.foreground != last_fg || cell.background != last_bg
            output << "\e[0m" if last_fg || last_bg  # Reset first
            output << ansi_color_code(cell.foreground, cell.background)
            last_fg = cell.foreground
            last_bg = cell.background
          end

          output << cell.char
        end

        # Newline between rows (except last)
        if row < @height - 1
          output << "\e[0m" if last_fg || last_bg  # Reset before newline
          output << "\r\n"
          last_fg = nil
          last_bg = nil
        end
      end

      # Final reset
      output << "\e[0m"

      output.string
    end

    # Convert buffer to plain text (no color codes)
    #
    # @return [String] Plain text content of the buffer
    def to_text
      @cells.map { |row| row.map(&:char).join.rstrip }.join("\n").rstrip
    end

    # Check if this buffer equals another (content-wise)
    #
    # @param other [ScreenBuffer] Buffer to compare
    # @return [Boolean] True if buffers have identical content
    def ==(other)
      return false unless other.is_a?(ScreenBuffer)
      return false if @width != other.width || @height != other.height

      @cells.each_with_index do |row_cells, row|
        row_cells.each_with_index do |cell, col|
          return false unless cell == other.get_cell(row, col)
        end
      end

      true
    end

    alias eql? ==

    # @return [Integer] Hash code for this buffer
    def hash
      [@width, @height, @cells].hash
    end

    # Check if buffer content has changed from another
    #
    # @param other [ScreenBuffer] Buffer to compare
    # @return [Boolean] True if any content differs
    def changed?(other)
      self != other
    end

    private

    # Create an empty cell with default colors
    #
    # @return [Cell] Empty cell
    def empty_cell
      Cell.new(char: " ", foreground: 7, background: 0, attributes: 7)
    end

    # Generate ANSI color code for foreground and background
    #
    # @param fg [Integer] Foreground color (0-15)
    # @param bg [Integer] Background color (0-15)
    # @return [String] ANSI escape sequence
    def ansi_color_code(fg, bg)
      codes = []

      # Map Windows color to ANSI (0-7 standard, 8-15 bright)
      if fg < 8
        codes << (30 + WINDOWS_TO_ANSI_COLOR[fg])
      else
        codes << (90 + WINDOWS_TO_ANSI_COLOR[fg - 8])
      end

      if bg < 8
        codes << (40 + WINDOWS_TO_ANSI_COLOR[bg])
      else
        codes << (100 + WINDOWS_TO_ANSI_COLOR[bg - 8])
      end

      "\e[#{codes.join(";")}m"
    end

    # Windows console colors use different bit ordering than ANSI
    # Windows: BGR (Blue=1, Green=2, Red=4)
    # ANSI: RGB (Red=1, Green=2, Blue=4)
    WINDOWS_TO_ANSI_COLOR = [
      0,  # 0: Black -> 0
      4,  # 1: Blue -> 4
      2,  # 2: Green -> 2
      6,  # 3: Cyan -> 6
      1,  # 4: Red -> 1
      5,  # 5: Magenta -> 5
      3,  # 6: Yellow -> 3
      7   # 7: White -> 7
    ].freeze
  end
end
