# frozen_string_literal: true

# Windows Console API bindings using Ruby's built-in Fiddle
# This module provides low-level access to Windows Console functions
# for terminal manipulation, ANSI support detection, and cursor control.
#
# Only loaded and functional on Windows platforms.

require "fiddle"
require "fiddle/import"

module Rich
  module Win32Console
    extend Fiddle::Importer

    # Standard handle constants
    STD_INPUT_HANDLE  = -10
    STD_OUTPUT_HANDLE = -11
    STD_ERROR_HANDLE  = -12

    # Console mode flags
    ENABLE_PROCESSED_INPUT        = 0x0001
    ENABLE_LINE_INPUT             = 0x0002
    ENABLE_ECHO_INPUT             = 0x0004
    ENABLE_WINDOW_INPUT           = 0x0008
    ENABLE_MOUSE_INPUT            = 0x0010
    ENABLE_INSERT_MODE            = 0x0020
    ENABLE_QUICK_EDIT_MODE        = 0x0040
    ENABLE_EXTENDED_FLAGS         = 0x0080
    ENABLE_AUTO_POSITION          = 0x0100
    ENABLE_VIRTUAL_TERMINAL_INPUT = 0x0200

    # Output mode flags
    ENABLE_PROCESSED_OUTPUT            = 0x0001
    ENABLE_WRAP_AT_EOL_OUTPUT          = 0x0002
    ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004
    DISABLE_NEWLINE_AUTO_RETURN        = 0x0008
    ENABLE_LVB_GRID_WORLDWIDE          = 0x0010

    # Console text attributes (foreground colors)
    FOREGROUND_BLUE      = 0x0001
    FOREGROUND_GREEN     = 0x0002
    FOREGROUND_RED       = 0x0004
    FOREGROUND_INTENSITY = 0x0008

    # Console text attributes (background colors)
    BACKGROUND_BLUE      = 0x0010
    BACKGROUND_GREEN     = 0x0020
    BACKGROUND_RED       = 0x0040
    BACKGROUND_INTENSITY = 0x0080

    # Additional text attributes
    COMMON_LVB_LEADING_BYTE    = 0x0100
    COMMON_LVB_TRAILING_BYTE   = 0x0200
    COMMON_LVB_GRID_HORIZONTAL = 0x0400
    COMMON_LVB_GRID_LVERTICAL  = 0x0800
    COMMON_LVB_GRID_RVERTICAL  = 0x1000
    COMMON_LVB_REVERSE_VIDEO   = 0x4000
    COMMON_LVB_UNDERSCORE      = 0x8000

    # ANSI color number to Windows console attribute mapping
    # Maps ANSI color indices (0-15) to Windows FOREGROUND/BACKGROUND values
    ANSI_TO_WINDOWS_FG = [
      0,                                                              # 0: Black
      FOREGROUND_RED,                                                 # 1: Red
      FOREGROUND_GREEN,                                               # 2: Green
      FOREGROUND_RED | FOREGROUND_GREEN,                              # 3: Yellow
      FOREGROUND_BLUE,                                                # 4: Blue
      FOREGROUND_RED | FOREGROUND_BLUE,                               # 5: Magenta
      FOREGROUND_GREEN | FOREGROUND_BLUE,                             # 6: Cyan
      FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE,            # 7: White
      FOREGROUND_INTENSITY,                                           # 8: Bright Black (Gray)
      FOREGROUND_RED | FOREGROUND_INTENSITY,                          # 9: Bright Red
      FOREGROUND_GREEN | FOREGROUND_INTENSITY,                        # 10: Bright Green
      FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_INTENSITY,       # 11: Bright Yellow
      FOREGROUND_BLUE | FOREGROUND_INTENSITY,                         # 12: Bright Blue
      FOREGROUND_RED | FOREGROUND_BLUE | FOREGROUND_INTENSITY,        # 13: Bright Magenta
      FOREGROUND_GREEN | FOREGROUND_BLUE | FOREGROUND_INTENSITY,      # 14: Bright Cyan
      FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE | FOREGROUND_INTENSITY # 15: Bright White
    ].freeze

    ANSI_TO_WINDOWS_BG = [
      0,                                                              # 0: Black
      BACKGROUND_RED,                                                 # 1: Red
      BACKGROUND_GREEN,                                               # 2: Green
      BACKGROUND_RED | BACKGROUND_GREEN,                              # 3: Yellow
      BACKGROUND_BLUE,                                                # 4: Blue
      BACKGROUND_RED | BACKGROUND_BLUE,                               # 5: Magenta
      BACKGROUND_GREEN | BACKGROUND_BLUE,                             # 6: Cyan
      BACKGROUND_RED | BACKGROUND_GREEN | BACKGROUND_BLUE,            # 7: White
      BACKGROUND_INTENSITY,                                           # 8: Bright Black (Gray)
      BACKGROUND_RED | BACKGROUND_INTENSITY,                          # 9: Bright Red
      BACKGROUND_GREEN | BACKGROUND_INTENSITY,                        # 10: Bright Green
      BACKGROUND_RED | BACKGROUND_GREEN | BACKGROUND_INTENSITY,       # 11: Bright Yellow
      BACKGROUND_BLUE | BACKGROUND_INTENSITY,                         # 12: Bright Blue
      BACKGROUND_RED | BACKGROUND_BLUE | BACKGROUND_INTENSITY,        # 13: Bright Magenta
      BACKGROUND_GREEN | BACKGROUND_BLUE | BACKGROUND_INTENSITY,      # 14: Bright Cyan
      BACKGROUND_RED | BACKGROUND_GREEN | BACKGROUND_BLUE | BACKGROUND_INTENSITY # 15: Bright White
    ].freeze

    if Gem.win_platform?
      dlload "kernel32.dll"

      # HANDLE WINAPI GetStdHandle(DWORD nStdHandle)
      extern "void* GetStdHandle(unsigned long)"

      # BOOL WINAPI GetConsoleMode(HANDLE hConsoleHandle, LPDWORD lpMode)
      extern "int GetConsoleMode(void*, unsigned long*)"

      # BOOL WINAPI SetConsoleMode(HANDLE hConsoleHandle, DWORD dwMode)
      extern "int SetConsoleMode(void*, unsigned long)"

      # BOOL WINAPI GetConsoleScreenBufferInfo(HANDLE hConsoleOutput, PCONSOLE_SCREEN_BUFFER_INFO lpConsoleScreenBufferInfo)
      extern "int GetConsoleScreenBufferInfo(void*, void*)"

      # BOOL WINAPI SetConsoleCursorPosition(HANDLE hConsoleOutput, COORD dwCursorPosition)
      extern "int SetConsoleCursorPosition(void*, unsigned long)"

      # BOOL WINAPI SetConsoleTextAttribute(HANDLE hConsoleOutput, WORD wAttributes)
      extern "int SetConsoleTextAttribute(void*, unsigned short)"

      # BOOL WINAPI FillConsoleOutputCharacterW(HANDLE hConsoleOutput, WCHAR cCharacter, DWORD nLength, COORD dwWriteCoord, LPDWORD lpNumberOfCharsWritten)
      extern "int FillConsoleOutputCharacterW(void*, unsigned short, unsigned long, unsigned long, unsigned long*)"

      # BOOL WINAPI FillConsoleOutputAttribute(HANDLE hConsoleOutput, WORD wAttribute, DWORD nLength, COORD dwWriteCoord, LPDWORD lpNumberOfAttrsWritten)
      extern "int FillConsoleOutputAttribute(void*, unsigned short, unsigned long, unsigned long, unsigned long*)"

      # BOOL WINAPI SetConsoleTitleW(LPCWSTR lpConsoleTitle)
      extern "int SetConsoleTitleW(void*)"

      # BOOL WINAPI GetConsoleCursorInfo(HANDLE hConsoleOutput, PCONSOLE_CURSOR_INFO lpConsoleCursorInfo)
      extern "int GetConsoleCursorInfo(void*, void*)"

      # BOOL WINAPI SetConsoleCursorInfo(HANDLE hConsoleOutput, PCONSOLE_CURSOR_INFO lpConsoleCursorInfo)
      extern "int SetConsoleCursorInfo(void*, void*)"

      # BOOL WINAPI WriteConsoleW(HANDLE hConsoleOutput, CONST VOID* lpBuffer, DWORD nNumberOfCharsToWrite, LPDWORD lpNumberOfCharsWritten, LPVOID lpReserved)
      extern "int WriteConsoleW(void*, void*, unsigned long, unsigned long*, void*)"

      # BOOL WINAPI FlushConsoleInputBuffer(HANDLE hConsoleInput)
      extern "int FlushConsoleInputBuffer(void*)"

      # Screen buffer capture APIs for terminal recording
      #
      # BOOL WINAPI ReadConsoleOutputW(
      #   HANDLE hConsoleOutput, PCHAR_INFO lpBuffer, COORD dwBufferSize,
      #   COORD dwBufferCoord, PSMALL_RECT lpReadRegion)
      extern "int ReadConsoleOutputW(void*, void*, unsigned long, unsigned long, void*)"

      # BOOL WINAPI ReadConsoleOutputCharacterW(
      #   HANDLE hConsoleOutput, LPWSTR lpCharacter, DWORD nLength,
      #   COORD dwReadCoord, LPDWORD lpNumberOfCharsRead)
      extern "int ReadConsoleOutputCharacterW(void*, void*, unsigned long, unsigned long, unsigned long*)"

      # BOOL WINAPI ReadConsoleOutputAttribute(
      #   HANDLE hConsoleOutput, LPWORD lpAttribute, DWORD nLength,
      #   COORD dwReadCoord, LPDWORD lpNumberOfAttrsRead)
      extern "int ReadConsoleOutputAttribute(void*, void*, unsigned long, unsigned long, unsigned long*)"
    end

    # CONSOLE_SCREEN_BUFFER_INFO structure layout:
    # typedef struct _CONSOLE_SCREEN_BUFFER_INFO {
    #   COORD      dwSize;           // 4 bytes (2x SHORT)
    #   COORD      dwCursorPosition; // 4 bytes (2x SHORT)
    #   WORD       wAttributes;      // 2 bytes
    #   SMALL_RECT srWindow;         // 8 bytes (4x SHORT)
    #   COORD      dwMaximumWindowSize; // 4 bytes (2x SHORT)
    # } CONSOLE_SCREEN_BUFFER_INFO;
    # Total: 22 bytes
    CONSOLE_SCREEN_BUFFER_INFO_SIZE = 22

    # CONSOLE_CURSOR_INFO structure layout:
    # typedef struct _CONSOLE_CURSOR_INFO {
    #   DWORD dwSize;    // 4 bytes
    #   BOOL  bVisible;  // 4 bytes
    # } CONSOLE_CURSOR_INFO;
    # Total: 8 bytes
    CONSOLE_CURSOR_INFO_SIZE = 8

    class << self
      # @return [Boolean] Whether the current platform is Windows
      def windows?
        Gem.win_platform?
      end

      # @return [Integer] Handle to stdout
      def stdout_handle
        return nil unless windows?
        @stdout_handle ||= GetStdHandle(STD_OUTPUT_HANDLE)
      end

      # @return [Integer] Handle to stdin
      def stdin_handle
        return nil unless windows?
        @stdin_handle ||= GetStdHandle(STD_INPUT_HANDLE)
      end

      # @return [Integer] Handle to stderr
      def stderr_handle
        return nil unless windows?
        @stderr_handle ||= GetStdHandle(STD_ERROR_HANDLE)
      end

      # Get the current console mode for a handle
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Integer, nil] Console mode flags or nil on failure
      def get_console_mode(handle = stdout_handle)
        return nil unless windows? && handle

        mode_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_LONG, Fiddle::RUBY_FREE)
        result = GetConsoleMode(handle, mode_ptr)
        return nil if result == 0

        mode_ptr[0, Fiddle::SIZEOF_LONG].unpack1("L")
      end

      # Set the console mode for a handle
      # @param mode [Integer] Console mode flags
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Boolean] Success status
      def set_console_mode(mode, handle = stdout_handle)
        return false unless windows? && handle

        SetConsoleMode(handle, mode) != 0
      end

      # Check if virtual terminal (ANSI) processing is supported
      # @return [Boolean] True if ANSI escape sequences are supported
      def supports_ansi?
        return @supports_ansi if defined?(@supports_ansi)

        unless windows?
          @supports_ansi = true  # Unix terminals support ANSI
          return @supports_ansi
        end

        mode = get_console_mode
        return @supports_ansi = false if mode.nil?

        @supports_ansi = (mode & ENABLE_VIRTUAL_TERMINAL_PROCESSING) != 0
      end

      # Enable virtual terminal (ANSI) processing
      # @return [Boolean] True if ANSI mode was successfully enabled
      def enable_ansi!
        return true unless windows?  # Already supported on Unix

        handle = stdout_handle
        return false unless handle

        current_mode = get_console_mode(handle)
        return false unless current_mode

        new_mode = current_mode | ENABLE_VIRTUAL_TERMINAL_PROCESSING
        result = set_console_mode(new_mode, handle)

        # Update cached value
        @supports_ansi = result
        result
      end

      # Disable virtual terminal (ANSI) processing
      # @return [Boolean] True if ANSI mode was successfully disabled
      def disable_ansi!
        return false unless windows?

        handle = stdout_handle
        return false unless handle

        current_mode = get_console_mode(handle)
        return false unless current_mode

        new_mode = current_mode & ~ENABLE_VIRTUAL_TERMINAL_PROCESSING
        result = set_console_mode(new_mode, handle)

        @supports_ansi = !result if result
        result
      end

      # Get console screen buffer info
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Hash, nil] Screen buffer info or nil on failure
      def get_screen_buffer_info(handle = stdout_handle)
        return nil unless windows? && handle

        buffer = Fiddle::Pointer.malloc(CONSOLE_SCREEN_BUFFER_INFO_SIZE, Fiddle::RUBY_FREE)
        result = GetConsoleScreenBufferInfo(handle, buffer)
        return nil if result == 0

        data = buffer[0, CONSOLE_SCREEN_BUFFER_INFO_SIZE]

        # Unpack the structure
        values = data.unpack("s2 s2 S s4 s2")

        {
          size: { width: values[0], height: values[1] },
          cursor_position: { x: values[2], y: values[3] },
          attributes: values[4],
          window: {
            left: values[5],
            top: values[6],
            right: values[7],
            bottom: values[8]
          },
          max_window_size: { width: values[9], height: values[10] }
        }
      end

      # Get the console window dimensions
      # @return [Array<Integer>, nil] [width, height] or nil on failure
      def get_size
        return nil unless windows?

        info = get_screen_buffer_info
        return nil unless info

        width = info[:window][:right] - info[:window][:left] + 1
        height = info[:window][:bottom] - info[:window][:top] + 1

        [width, height]
      end

      # Get current cursor position
      # @return [Array<Integer>, nil] [x, y] or nil on failure
      def get_cursor_position
        return nil unless windows?

        info = get_screen_buffer_info
        return nil unless info

        [info[:cursor_position][:x], info[:cursor_position][:y]]
      end

      # Set cursor position
      # @param x [Integer] Column (0-indexed)
      # @param y [Integer] Row (0-indexed)
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Boolean] Success status
      def set_cursor_position(x, y, handle = stdout_handle)
        return false unless windows? && handle

        # Pack COORD structure as DWORD (low word = X, high word = Y)
        coord = (y << 16) | (x & 0xFFFF)
        SetConsoleCursorPosition(handle, coord) != 0
      end

      # Set console text attributes (foreground/background colors)
      # @param attributes [Integer] Attribute flags
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Boolean] Success status
      def set_text_attribute(attributes, handle = stdout_handle)
        return false unless windows? && handle

        SetConsoleTextAttribute(handle, attributes) != 0
      end

      # Get current text attributes
      # @return [Integer, nil] Current attributes or nil on failure
      def get_text_attributes
        return nil unless windows?

        info = get_screen_buffer_info
        return nil unless info

        info[:attributes]
      end

      # Fill console output with a character
      # @param char [String] Character to fill with
      # @param length [Integer] Number of cells to fill
      # @param x [Integer] Starting column
      # @param y [Integer] Starting row
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Integer, nil] Number of characters written or nil on failure
      def fill_output_character(char, length, x, y, handle = stdout_handle)
        return nil unless windows? && handle

        coord = (y << 16) | (x & 0xFFFF)
        written_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_LONG, Fiddle::RUBY_FREE)

        char_code = char.ord
        result = FillConsoleOutputCharacterW(handle, char_code, length, coord, written_ptr)
        return nil if result == 0

        written_ptr[0, Fiddle::SIZEOF_LONG].unpack1("L")
      end

      # Fill console output with an attribute
      # @param attribute [Integer] Attribute to fill with
      # @param length [Integer] Number of cells to fill
      # @param x [Integer] Starting column
      # @param y [Integer] Starting row
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Integer, nil] Number of cells written or nil on failure
      def fill_output_attribute(attribute, length, x, y, handle = stdout_handle)
        return nil unless windows? && handle

        coord = (y << 16) | (x & 0xFFFF)
        written_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_LONG, Fiddle::RUBY_FREE)

        result = FillConsoleOutputAttribute(handle, attribute, length, coord, written_ptr)
        return nil if result == 0

        written_ptr[0, Fiddle::SIZEOF_LONG].unpack1("L")
      end

      # Set console window title
      # @param title [String] New window title
      # @return [Boolean] Success status
      def set_title(title)
        return false unless windows?

        # Convert to UTF-16LE with null terminator
        wide_title = (title + "\0").encode("UTF-16LE")
        SetConsoleTitleW(Fiddle::Pointer[wide_title]) != 0
      end

      # Show the cursor
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Boolean] Success status
      def show_cursor(handle = stdout_handle)
        set_cursor_visibility(true, handle)
      end

      # Hide the cursor
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Boolean] Success status
      def hide_cursor(handle = stdout_handle)
        set_cursor_visibility(false, handle)
      end

      # Set cursor visibility
      # @param visible [Boolean] Whether cursor should be visible
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Boolean] Success status
      def set_cursor_visibility(visible, handle = stdout_handle)
        return false unless windows? && handle

        # Get current cursor info
        buffer = Fiddle::Pointer.malloc(CONSOLE_CURSOR_INFO_SIZE, Fiddle::RUBY_FREE)
        result = GetConsoleCursorInfo(handle, buffer)
        return false if result == 0

        # Modify visibility
        data = buffer[0, CONSOLE_CURSOR_INFO_SIZE].unpack("L L")
        cursor_size = data[0]
        buffer[0, CONSOLE_CURSOR_INFO_SIZE] = [cursor_size, visible ? 1 : 0].pack("L L")

        SetConsoleCursorInfo(handle, buffer) != 0
      end

      # Write text to console (bypassing Ruby's IO buffering)
      # @param text [String] Text to write
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Integer, nil] Number of characters written or nil on failure
      def write_console(text, handle = stdout_handle)
        return nil unless windows? && handle

        wide_text = text.encode("UTF-16LE")
        char_count = text.length
        written_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_LONG, Fiddle::RUBY_FREE)

        result = WriteConsoleW(handle, Fiddle::Pointer[wide_text], char_count, written_ptr, nil)
        return nil if result == 0

        written_ptr[0, Fiddle::SIZEOF_LONG].unpack1("L")
      end

      # Clear the entire screen
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Boolean] Success status
      def clear_screen(handle = stdout_handle)
        return false unless windows? && handle

        info = get_screen_buffer_info(handle)
        return false unless info

        size = info[:size][:width] * info[:size][:height]
        attributes = info[:attributes]

        fill_output_character(" ", size, 0, 0, handle)
        fill_output_attribute(attributes, size, 0, 0, handle)
        set_cursor_position(0, 0, handle)

        true
      end

      # Erase from cursor to end of line
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Boolean] Success status
      def erase_line(handle = stdout_handle)
        return false unless windows? && handle

        info = get_screen_buffer_info(handle)
        return false unless info

        x = info[:cursor_position][:x]
        y = info[:cursor_position][:y]
        length = info[:size][:width] - x
        attributes = info[:attributes]

        fill_output_character(" ", length, x, y, handle)
        fill_output_attribute(attributes, length, x, y, handle)

        true
      end

      # Move cursor up
      # @param lines [Integer] Number of lines to move up
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Boolean] Success status
      def cursor_up(lines = 1, handle = stdout_handle)
        return false unless windows?

        pos = get_cursor_position
        return false unless pos

        new_y = [pos[1] - lines, 0].max
        set_cursor_position(pos[0], new_y, handle)
      end

      # Move cursor down
      # @param lines [Integer] Number of lines to move down
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Boolean] Success status
      def cursor_down(lines = 1, handle = stdout_handle)
        return false unless windows?

        info = get_screen_buffer_info(handle)
        return false unless info

        pos = get_cursor_position
        return false unless pos

        max_y = info[:size][:height] - 1
        new_y = [pos[1] + lines, max_y].min
        set_cursor_position(pos[0], new_y, handle)
      end

      # Move cursor forward (right)
      # @param columns [Integer] Number of columns to move
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Boolean] Success status
      def cursor_forward(columns = 1, handle = stdout_handle)
        return false unless windows?

        info = get_screen_buffer_info(handle)
        return false unless info

        pos = get_cursor_position
        return false unless pos

        max_x = info[:size][:width] - 1
        new_x = [pos[0] + columns, max_x].min
        set_cursor_position(new_x, pos[1], handle)
      end

      # Move cursor backward (left)
      # @param columns [Integer] Number of columns to move
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Boolean] Success status
      def cursor_backward(columns = 1, handle = stdout_handle)
        return false unless windows?

        pos = get_cursor_position
        return false unless pos

        new_x = [pos[0] - columns, 0].max
        set_cursor_position(new_x, pos[1], handle)
      end

      # Move cursor to the beginning of the line
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Boolean] Success status
      def cursor_to_column(column = 0, handle = stdout_handle)
        return false unless windows?

        pos = get_cursor_position
        return false unless pos

        set_cursor_position(column, pos[1], handle)
      end

      # Convert ANSI color number to Windows console attributes
      # @param foreground [Integer, nil] ANSI foreground color (0-15)
      # @param background [Integer, nil] ANSI background color (0-15)
      # @return [Integer] Windows console attribute value
      def ansi_to_windows_attributes(foreground: nil, background: nil)
        attributes = 0
        attributes |= ANSI_TO_WINDOWS_FG[foreground] if foreground && foreground < 16
        attributes |= ANSI_TO_WINDOWS_BG[background] if background && background < 16
        attributes
      end

      # =========================================================================
      # Screen Buffer Capture Methods (for terminal recording)
      # =========================================================================

      # CHAR_INFO structure:
      # typedef struct _CHAR_INFO {
      #   union { WCHAR UnicodeChar; CHAR AsciiChar; } Char;  // 2 bytes
      #   WORD Attributes;                                     // 2 bytes
      # } CHAR_INFO;
      CHAR_INFO_SIZE = 4

      # SMALL_RECT structure for region specification
      SMALL_RECT_SIZE = 8

      # Mapping from Windows console foreground attributes to ANSI color numbers
      WINDOWS_FG_TO_ANSI = {
        0 => 30,                                                              # Black
        FOREGROUND_RED => 31,                                                 # Red
        FOREGROUND_GREEN => 32,                                               # Green
        (FOREGROUND_RED | FOREGROUND_GREEN) => 33,                            # Yellow
        FOREGROUND_BLUE => 34,                                                # Blue
        (FOREGROUND_RED | FOREGROUND_BLUE) => 35,                             # Magenta
        (FOREGROUND_GREEN | FOREGROUND_BLUE) => 36,                           # Cyan
        (FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE) => 37           # White
      }.freeze

      # Mapping from Windows console background attributes to ANSI color numbers
      WINDOWS_BG_TO_ANSI = {
        0 => 40,                                                              # Black
        BACKGROUND_RED => 41,                                                 # Red
        BACKGROUND_GREEN => 42,                                               # Green
        (BACKGROUND_RED | BACKGROUND_GREEN) => 43,                            # Yellow
        BACKGROUND_BLUE => 44,                                                # Blue
        (BACKGROUND_RED | BACKGROUND_BLUE) => 45,                             # Magenta
        (BACKGROUND_GREEN | BACKGROUND_BLUE) => 46,                           # Cyan
        (BACKGROUND_RED | BACKGROUND_GREEN | BACKGROUND_BLUE) => 47           # White
      }.freeze

      # Read characters from a line in the screen buffer
      #
      # @param row [Integer] Row number (0-indexed)
      # @param start_col [Integer] Starting column (0-indexed)
      # @param length [Integer] Number of characters to read
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [String, nil] Characters read or nil on failure
      def read_line_characters(row, start_col, length, handle = stdout_handle)
        return nil unless windows? && handle

        # Allocate buffer for UTF-16LE characters (2 bytes per char)
        buffer = Fiddle::Pointer.malloc(length * 2, Fiddle::RUBY_FREE)
        chars_read_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_LONG, Fiddle::RUBY_FREE)

        # Pack COORD as DWORD (low word = X, high word = Y)
        coord = (row << 16) | (start_col & 0xFFFF)

        result = ReadConsoleOutputCharacterW(handle, buffer, length, coord, chars_read_ptr)
        return nil if result == 0

        chars_read = chars_read_ptr[0, Fiddle::SIZEOF_LONG].unpack1("L")
        return "" if chars_read == 0

        # Convert UTF-16LE to Ruby string
        buffer[0, chars_read * 2].force_encoding("UTF-16LE").encode("UTF-8")
      end

      # Read attributes from a line in the screen buffer
      #
      # @param row [Integer] Row number (0-indexed)
      # @param start_col [Integer] Starting column (0-indexed)
      # @param length [Integer] Number of attributes to read
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Array<Integer>, nil] Attribute values or nil on failure
      def read_line_attributes(row, start_col, length, handle = stdout_handle)
        return nil unless windows? && handle

        # Allocate buffer for WORD attributes (2 bytes each)
        buffer = Fiddle::Pointer.malloc(length * 2, Fiddle::RUBY_FREE)
        attrs_read_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_LONG, Fiddle::RUBY_FREE)

        # Pack COORD as DWORD
        coord = (row << 16) | (start_col & 0xFFFF)

        result = ReadConsoleOutputAttribute(handle, buffer, length, coord, attrs_read_ptr)
        return nil if result == 0

        attrs_read = attrs_read_ptr[0, Fiddle::SIZEOF_LONG].unpack1("L")
        return [] if attrs_read == 0

        # Unpack as array of unsigned shorts
        buffer[0, attrs_read * 2].unpack("S*")
      end

      # Read a rectangular region from the screen buffer
      #
      # @param left [Integer] Left column (0-indexed)
      # @param top [Integer] Top row (0-indexed)
      # @param right [Integer] Right column (0-indexed, inclusive)
      # @param bottom [Integer] Bottom row (0-indexed, inclusive)
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Array<Array<Hash>>, nil] 2D array of {char:, attributes:} or nil on failure
      def read_screen_region(left, top, right, bottom, handle = stdout_handle)
        return nil unless windows? && handle

        width = right - left + 1
        height = bottom - top + 1
        total_cells = width * height

        # Allocate CHAR_INFO buffer
        buffer = Fiddle::Pointer.malloc(total_cells * CHAR_INFO_SIZE, Fiddle::RUBY_FREE)

        # Pack buffer size COORD (width, height)
        buffer_size = (height << 16) | (width & 0xFFFF)

        # Pack buffer coord (0, 0) - start of destination buffer
        buffer_coord = 0

        # Pack SMALL_RECT (left, top, right, bottom)
        region_buffer = Fiddle::Pointer.malloc(SMALL_RECT_SIZE, Fiddle::RUBY_FREE)
        region_buffer[0, SMALL_RECT_SIZE] = [left, top, right, bottom].pack("s4")

        result = ReadConsoleOutputW(handle, buffer, buffer_size, buffer_coord, region_buffer)
        return nil if result == 0

        # Parse CHAR_INFO structures into 2D array
        cells = []
        height.times do |row|
          row_cells = []
          width.times do |col|
            offset = (row * width + col) * CHAR_INFO_SIZE
            char_data = buffer[offset, CHAR_INFO_SIZE]

            # CHAR_INFO: 2 bytes unicode char, 2 bytes attributes
            unicode_char, attributes = char_data.unpack("S S")

            row_cells << {
              char: [unicode_char].pack("U*"),
              attributes: attributes
            }
          end
          cells << row_cells
        end

        cells
      end

      # Capture the entire visible screen buffer
      #
      # @param handle [Integer] Console handle (defaults to stdout)
      # @return [Hash, nil] Screen buffer data or nil on failure
      #   - :width [Integer] Screen width
      #   - :height [Integer] Screen height
      #   - :cursor_x [Integer] Cursor X position
      #   - :cursor_y [Integer] Cursor Y position
      #   - :lines [Array<Hash>] Array of line data
      #     - :chars [String] Characters in the line
      #     - :attributes [Array<Integer>] Attribute for each character
      def capture_screen_buffer(handle = stdout_handle)
        return nil unless windows? && handle

        info = get_screen_buffer_info(handle)
        return nil unless info

        window = info[:window]
        width = window[:right] - window[:left] + 1
        height = window[:bottom] - window[:top] + 1

        lines = []
        height.times do |row|
          actual_row = window[:top] + row
          chars = read_line_characters(actual_row, window[:left], width, handle)
          attributes = read_line_attributes(actual_row, window[:left], width, handle)

          lines << {
            chars: chars || "",
            attributes: attributes || []
          }
        end

        {
          width: width,
          height: height,
          cursor_x: info[:cursor_position][:x] - window[:left],
          cursor_y: info[:cursor_position][:y] - window[:top],
          lines: lines
        }
      end

      # Convert Windows console attributes to ANSI SGR codes
      #
      # @param attributes [Integer] Windows console attribute value
      # @return [String] ANSI escape sequence for the given attributes
      def windows_attr_to_ansi(attributes)
        codes = []

        # Extract foreground color (bits 0-3)
        fg_color = attributes & 0x0F
        fg_intense = (fg_color & FOREGROUND_INTENSITY) != 0
        fg_base = fg_color & 0x07

        # Map to ANSI foreground color
        ansi_fg = WINDOWS_FG_TO_ANSI[fg_base]
        ansi_fg += 60 if fg_intense && ansi_fg  # Bright variant (90-97)
        codes << ansi_fg if ansi_fg

        # Extract background color (bits 4-7)
        bg_color = (attributes >> 4) & 0x0F
        bg_intense = (bg_color & 0x08) != 0
        bg_base = (bg_color & 0x07) << 4  # Shift back to match WINDOWS_BG_TO_ANSI keys

        # Map to ANSI background color
        ansi_bg = WINDOWS_BG_TO_ANSI[bg_base]
        ansi_bg += 60 if bg_intense && ansi_bg  # Bright variant (100-107)
        codes << ansi_bg if ansi_bg

        # Handle other attributes
        codes << 4 if (attributes & COMMON_LVB_UNDERSCORE) != 0    # Underline
        codes << 7 if (attributes & COMMON_LVB_REVERSE_VIDEO) != 0 # Reverse

        return "" if codes.empty?

        "\e[#{codes.join(";")}m"
      end

      # Convert screen buffer capture to ANSI escape sequence string
      #
      # @param buffer_data [Hash] Data from capture_screen_buffer
      # @return [String] ANSI escape sequence string representing the screen content
      def buffer_to_ansi(buffer_data)
        return "" unless buffer_data

        output = StringIO.new

        buffer_data[:lines].each_with_index do |line, row|
          chars = line[:chars]
          attributes = line[:attributes]

          last_attr = nil
          chars.each_char.with_index do |char, col|
            attr = attributes[col] || 0

            # Emit ANSI code if attributes changed
            if attr != last_attr
              output << "\e[0m" if last_attr  # Reset first
              ansi = windows_attr_to_ansi(attr)
              output << ansi unless ansi.empty?
              last_attr = attr
            end

            output << char
          end

          # Reset and newline (except for last line)
          output << "\e[0m" if last_attr
          output << "\r\n" if row < buffer_data[:lines].length - 1
        end

        output.string
      end
    end

    # Auto-enable ANSI on Windows when this module is loaded
    enable_ansi! if windows?
  end
end

