# frozen_string_literal: true

require_relative "color_triplet"
require_relative "_palettes"

module Rich
  # Terminal color theme configuration.
  # Defines the actual RGB values for ANSI colors as rendered by a terminal.
  class TerminalTheme
    # @return [ColorTriplet] Default foreground color
    attr_reader :foreground

    # @return [ColorTriplet] Default background color
    attr_reader :background

    # @return [Array<ColorTriplet>] 16 ANSI colors (indices 0-15)
    attr_reader :ansi_colors

    # Create a new terminal theme
    # @param foreground [ColorTriplet] Default foreground color
    # @param background [ColorTriplet] Default background color
    # @param ansi_colors [Array<ColorTriplet>] 16 ANSI colors
    def initialize(foreground:, background:, ansi_colors:)
      raise ArgumentError, "ansi_colors must have exactly 16 colors" unless ansi_colors.length == 16

      @foreground = foreground
      @background = background
      @ansi_colors = ansi_colors.freeze
      freeze
    end

    # Check equality with another theme
    def ==(other)
      return false unless other.is_a?(TerminalTheme)

      @foreground == other.foreground &&
        @background == other.background &&
        @ansi_colors == other.ansi_colors
    end

    alias eql? ==

    def hash
      [@foreground, @background, @ansi_colors].hash
    end
  end

  # Default terminal theme (based on typical dark terminal)
  DEFAULT_TERMINAL_THEME = TerminalTheme.new(
    foreground: ColorTriplet.new(230, 230, 230),
    background: ColorTriplet.new(12, 12, 12),
    ansi_colors: [
      ColorTriplet.new(12, 12, 12),     # 0: Black
      ColorTriplet.new(205, 49, 49),    # 1: Red
      ColorTriplet.new(13, 188, 121),   # 2: Green
      ColorTriplet.new(229, 229, 16),   # 3: Yellow
      ColorTriplet.new(36, 114, 200),   # 4: Blue
      ColorTriplet.new(188, 63, 188),   # 5: Magenta
      ColorTriplet.new(17, 168, 205),   # 6: Cyan
      ColorTriplet.new(229, 229, 229),  # 7: White
      ColorTriplet.new(102, 102, 102),  # 8: Bright Black
      ColorTriplet.new(241, 76, 76),    # 9: Bright Red
      ColorTriplet.new(35, 209, 139),   # 10: Bright Green
      ColorTriplet.new(245, 245, 67),   # 11: Bright Yellow
      ColorTriplet.new(59, 142, 234),   # 12: Bright Blue
      ColorTriplet.new(214, 112, 214),  # 13: Bright Magenta
      ColorTriplet.new(41, 184, 219),   # 14: Bright Cyan
      ColorTriplet.new(255, 255, 255)   # 15: Bright White
    ]
  )

  # Monokai-inspired theme
  MONOKAI_THEME = TerminalTheme.new(
    foreground: ColorTriplet.new(248, 248, 242),
    background: ColorTriplet.new(39, 40, 34),
    ansi_colors: [
      ColorTriplet.new(39, 40, 34),     # 0: Black
      ColorTriplet.new(249, 38, 114),   # 1: Red
      ColorTriplet.new(166, 226, 46),   # 2: Green
      ColorTriplet.new(244, 191, 117),  # 3: Yellow
      ColorTriplet.new(102, 217, 239),  # 4: Blue
      ColorTriplet.new(174, 129, 255),  # 5: Magenta
      ColorTriplet.new(161, 239, 228),  # 6: Cyan
      ColorTriplet.new(248, 248, 242),  # 7: White
      ColorTriplet.new(117, 113, 94),   # 8: Bright Black
      ColorTriplet.new(249, 38, 114),   # 9: Bright Red
      ColorTriplet.new(166, 226, 46),   # 10: Bright Green
      ColorTriplet.new(244, 191, 117),  # 11: Bright Yellow
      ColorTriplet.new(102, 217, 239),  # 12: Bright Blue
      ColorTriplet.new(174, 129, 255),  # 13: Bright Magenta
      ColorTriplet.new(161, 239, 228),  # 14: Bright Cyan
      ColorTriplet.new(248, 248, 242)   # 15: Bright White
    ]
  )

  # Dimmed Monokai for SVG/HTML export
  SVG_EXPORT_THEME = TerminalTheme.new(
    foreground: ColorTriplet.new(248, 248, 242),
    background: ColorTriplet.new(50, 48, 47),
    ansi_colors: [
      ColorTriplet.new(50, 48, 47),     # 0: Black
      ColorTriplet.new(255, 98, 134),   # 1: Red
      ColorTriplet.new(164, 238, 92),   # 2: Green
      ColorTriplet.new(255, 216, 102),  # 3: Yellow
      ColorTriplet.new(98, 209, 255),   # 4: Blue
      ColorTriplet.new(189, 147, 249),  # 5: Magenta
      ColorTriplet.new(128, 255, 234),  # 6: Cyan
      ColorTriplet.new(248, 248, 242),  # 7: White
      ColorTriplet.new(98, 94, 76),     # 8: Bright Black
      ColorTriplet.new(255, 98, 134),   # 9: Bright Red
      ColorTriplet.new(164, 238, 92),   # 10: Bright Green
      ColorTriplet.new(255, 216, 102),  # 11: Bright Yellow
      ColorTriplet.new(98, 209, 255),   # 12: Bright Blue
      ColorTriplet.new(189, 147, 249),  # 13: Bright Magenta
      ColorTriplet.new(128, 255, 234),  # 14: Bright Cyan
      ColorTriplet.new(248, 248, 242)   # 15: Bright White
    ]
  )

  # Windows Terminal default theme
  WINDOWS_TERMINAL_THEME = TerminalTheme.new(
    foreground: ColorTriplet.new(204, 204, 204),
    background: ColorTriplet.new(12, 12, 12),
    ansi_colors: Palettes::WINDOWS_PALETTE.dup
  )
end
