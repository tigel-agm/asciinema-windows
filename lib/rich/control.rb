# frozen_string_literal: true

module Rich
  # Terminal control codes and escape sequences.
  # Provides constants and methods for cursor movement, screen clearing,
  # and other terminal control operations.
  module Control
    # Control code types for segment rendering
    module ControlType
      BELL                  = :bell
      CARRIAGE_RETURN       = :carriage_return
      HOME                  = :home
      CLEAR                 = :clear
      SHOW_CURSOR           = :show_cursor
      HIDE_CURSOR           = :hide_cursor
      ENABLE_ALT_SCREEN     = :enable_alt_screen
      DISABLE_ALT_SCREEN    = :disable_alt_screen
      CURSOR_UP             = :cursor_up
      CURSOR_DOWN           = :cursor_down
      CURSOR_FORWARD        = :cursor_forward
      CURSOR_BACKWARD       = :cursor_backward
      CURSOR_MOVE_TO_COLUMN = :cursor_move_to_column
      CURSOR_MOVE_TO        = :cursor_move_to
      ERASE_IN_LINE         = :erase_in_line
      SET_WINDOW_TITLE      = :set_window_title
    end

    # ESC character for ANSI sequences
    ESC = "\e"

    # Control Sequence Introducer
    CSI = "\e["

    # Operating System Command
    OSC = "\e]"

    # String Terminator
    ST = "\e\\"

    # Bell character
    BEL = "\a"

    class << self
      # Generate bell/alert
      # @return [String]
      def bell
        BEL
      end

      # Carriage return (move to column 0)
      # @return [String]
      def carriage_return
        "\r"
      end

      # Move cursor to home position (1,1)
      # @return [String]
      def home
        "#{CSI}H"
      end

      # Clear the screen
      # @param mode [Integer] 0=cursor to end, 1=start to cursor, 2=entire screen
      # @return [String]
      def clear(mode = 2)
        "#{CSI}#{mode}J"
      end

      # Clear entire screen and move to home
      # @return [String]
      def clear_screen
        "#{CSI}2J#{CSI}H"
      end

      # Show the cursor
      # @return [String]
      def show_cursor
        "#{CSI}?25h"
      end

      # Hide the cursor
      # @return [String]
      def hide_cursor
        "#{CSI}?25l"
      end

      # Enable alternative screen buffer
      # @return [String]
      def enable_alt_screen
        "#{CSI}?1049h"
      end

      # Disable alternative screen buffer
      # @return [String]
      def disable_alt_screen
        "#{CSI}?1049l"
      end

      # Move cursor up
      # @param count [Integer] Number of rows
      # @return [String]
      def cursor_up(count = 1)
        return "" if count < 1

        "#{CSI}#{count}A"
      end

      # Move cursor down
      # @param count [Integer] Number of rows
      # @return [String]
      def cursor_down(count = 1)
        return "" if count < 1

        "#{CSI}#{count}B"
      end

      # Move cursor forward (right)
      # @param count [Integer] Number of columns
      # @return [String]
      def cursor_forward(count = 1)
        return "" if count < 1

        "#{CSI}#{count}C"
      end

      # Move cursor backward (left)
      # @param count [Integer] Number of columns
      # @return [String]
      def cursor_backward(count = 1)
        return "" if count < 1

        "#{CSI}#{count}D"
      end

      # Move cursor to next line
      # @param count [Integer] Number of lines
      # @return [String]
      def cursor_next_line(count = 1)
        return "" if count < 1

        "#{CSI}#{count}E"
      end

      # Move cursor to previous line
      # @param count [Integer] Number of lines
      # @return [String]
      def cursor_prev_line(count = 1)
        return "" if count < 1

        "#{CSI}#{count}F"
      end

      # Move cursor to column (1-based)
      # @param column [Integer] Column number (1-based)
      # @return [String]
      def cursor_move_to_column(column)
        "#{CSI}#{column}G"
      end

      # Move cursor to position (1-based coordinates)
      # @param row [Integer] Row (1-based)
      # @param column [Integer] Column (1-based)
      # @return [String]
      def cursor_move_to(row, column)
        "#{CSI}#{row};#{column}H"
      end

      # Save cursor position
      # @return [String]
      def save_cursor
        "#{CSI}s"
      end

      # Restore cursor position
      # @return [String]
      def restore_cursor
        "#{CSI}u"
      end

      # Erase in line
      # @param mode [Integer] 0=cursor to end, 1=start to cursor, 2=entire line
      # @return [String]
      def erase_line(mode = 2)
        "#{CSI}#{mode}K"
      end

      # Erase from cursor to end of line
      # @return [String]
      def erase_end_of_line
        "#{CSI}0K"
      end

      # Erase from start of line to cursor
      # @return [String]
      def erase_start_of_line
        "#{CSI}1K"
      end

      # Set window title
      # @param title [String] Window title
      # @return [String]
      def set_title(title)
        "#{OSC}2;#{title}#{ST}"
      end

      # Set icon name (some terminals)
      # @param name [String] Icon name
      # @return [String]
      def set_icon_name(name)
        "#{OSC}1;#{name}#{ST}"
      end

      # Set both icon name and window title
      # @param title [String] Title/name
      # @return [String]
      def set_icon_and_title(title)
        "#{OSC}0;#{title}#{ST}"
      end

      # Request cursor position (terminal will respond)
      # @return [String]
      def request_cursor_position
        "#{CSI}6n"
      end

      # Scroll up
      # @param count [Integer] Number of lines
      # @return [String]
      def scroll_up(count = 1)
        "#{CSI}#{count}S"
      end

      # Scroll down
      # @param count [Integer] Number of lines
      # @return [String]
      def scroll_down(count = 1)
        "#{CSI}#{count}T"
      end

      # Reset all attributes
      # @return [String]
      def reset
        "#{CSI}0m"
      end

      # Create a hyperlink
      # @param url [String] URL
      # @param text [String] Link text
      # @param id [String, nil] Optional link ID
      # @return [String]
      def hyperlink(url, text, id: nil)
        params = id ? "id=#{id}" : ""
        "#{OSC}8;#{params};#{url}#{ST}#{text}#{OSC}8;;#{ST}"
      end

      # Start hyperlink
      # @param url [String] URL
      # @param id [String, nil] Optional link ID
      # @return [String]
      def hyperlink_start(url, id: nil)
        params = id ? "id=#{id}" : ""
        "#{OSC}8;#{params};#{url}#{ST}"
      end

      # End hyperlink
      # @return [String]
      def hyperlink_end
        "#{OSC}8;;#{ST}"
      end

      # Strip ANSI escape sequences from text
      # @param text [String] Text to strip
      # @return [String] Text without ANSI sequences
      def strip_ansi(text)
        text.gsub(/\e\[[0-9;]*[A-Za-z]/, "")
            .gsub(/\e\][^\a\e]*(?:\a|\e\\)/, "")
            .gsub(/\e[()][\dAB]/, "")
      end

      # Check if text contains ANSI escape sequences
      # @param text [String] Text to check
      # @return [Boolean]
      def contains_ansi?(text)
        text.match?(/\e[\[\]()][^\a\e]*/)
      end

      # Generate control code for a control type
      # @param control_type [Symbol] Control type
      # @param param1 [Object] First parameter
      # @param param2 [Object] Second parameter
      # @return [String]
      def generate(control_type, param1 = nil, param2 = nil)
        case control_type
        when ControlType::BELL
          bell
        when ControlType::CARRIAGE_RETURN
          carriage_return
        when ControlType::HOME
          home
        when ControlType::CLEAR
          clear
        when ControlType::SHOW_CURSOR
          show_cursor
        when ControlType::HIDE_CURSOR
          hide_cursor
        when ControlType::ENABLE_ALT_SCREEN
          enable_alt_screen
        when ControlType::DISABLE_ALT_SCREEN
          disable_alt_screen
        when ControlType::CURSOR_UP
          cursor_up(param1 || 1)
        when ControlType::CURSOR_DOWN
          cursor_down(param1 || 1)
        when ControlType::CURSOR_FORWARD
          cursor_forward(param1 || 1)
        when ControlType::CURSOR_BACKWARD
          cursor_backward(param1 || 1)
        when ControlType::CURSOR_MOVE_TO_COLUMN
          cursor_move_to_column(param1 || 1)
        when ControlType::CURSOR_MOVE_TO
          cursor_move_to(param1 || 1, param2 || 1)
        when ControlType::ERASE_IN_LINE
          erase_line(param1 || 2)
        when ControlType::SET_WINDOW_TITLE
          set_title(param1.to_s)
        else
          ""
        end
      end
    end
  end
end
