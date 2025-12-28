# frozen_string_literal: true

module AsciinemaWin
  # Terminal color themes for SVG/HTML export
  #
  # Provides color palettes for rendering terminal output in various
  # popular themes like Dracula, Monokai, Solarized, etc.
  module Themes
    # Base theme structure
    # @!attribute [r] name
    #   @return [String] Theme name
    # @!attribute [r] background
    #   @return [String] Background color (hex)
    # @!attribute [r] foreground
    #   @return [String] Default foreground color (hex)
    # @!attribute [r] cursor
    #   @return [String] Cursor color (hex)
    # @!attribute [r] palette
    #   @return [Array<String>] 16-color palette (8 normal + 8 bright)
    Theme = Data.define(:name, :background, :foreground, :cursor, :palette) do
      # Get color for ANSI color index
      #
      # @param index [Integer] ANSI color index (0-15 for basic, 16-255 for extended)
      # @return [String] Hex color code
      def color(index)
        if index < 16
          palette[index]
        elsif index < 232
          # 216 color cube (6x6x6)
          index -= 16
          r = (index / 36) % 6
          g = (index / 6) % 6
          b = index % 6
          r_val = r == 0 ? 0 : 55 + r * 40
          g_val = g == 0 ? 0 : 55 + g * 40
          b_val = b == 0 ? 0 : 55 + b * 40
          format("#%02x%02x%02x", r_val, g_val, b_val)
        else
          # 24 grayscale colors
          gray = (index - 232) * 10 + 8
          format("#%02x%02x%02x", gray, gray, gray)
        end
      end

      # Get foreground color for ANSI code
      #
      # @param code [Integer] ANSI SGR foreground code (30-37, 90-97)
      # @return [String] Hex color code
      def fg_color(code)
        case code
        when 30..37 then palette[code - 30]
        when 90..97 then palette[code - 90 + 8]
        when 39 then foreground
        else foreground
        end
      end

      # Get background color for ANSI code
      #
      # @param code [Integer] ANSI SGR background code (40-47, 100-107)
      # @return [String] Hex color code
      def bg_color(code)
        case code
        when 40..47 then palette[code - 40]
        when 100..107 then palette[code - 100 + 8]
        when 49 then background
        else background
        end
      end
    end

    # Default asciinema theme
    ASCIINEMA = Theme.new(
      name: "asciinema",
      background: "#121314",
      foreground: "#cccccc",
      cursor: "#cccccc",
      palette: [
        "#000000", # Black
        "#dd3c69", # Red
        "#4ebf22", # Green
        "#ddaf3c", # Yellow
        "#26b0d7", # Blue
        "#b954e1", # Magenta
        "#54e1b9", # Cyan
        "#d9d9d9", # White
        "#4d4d4d", # Bright Black
        "#dd3c69", # Bright Red
        "#4ebf22", # Bright Green
        "#ddaf3c", # Bright Yellow
        "#26b0d7", # Bright Blue
        "#b954e1", # Bright Magenta
        "#54e1b9", # Bright Cyan
        "#ffffff"  # Bright White
      ]
    ).freeze

    # Dracula theme
    DRACULA = Theme.new(
      name: "dracula",
      background: "#282a36",
      foreground: "#f8f8f2",
      cursor: "#f8f8f2",
      palette: [
        "#21222c", # Black
        "#ff5555", # Red
        "#50fa7b", # Green
        "#f1fa8c", # Yellow
        "#bd93f9", # Blue
        "#ff79c6", # Magenta
        "#8be9fd", # Cyan
        "#f8f8f2", # White
        "#6272a4", # Bright Black
        "#ff6e6e", # Bright Red
        "#69ff94", # Bright Green
        "#ffffa5", # Bright Yellow
        "#d6acff", # Bright Blue
        "#ff92df", # Bright Magenta
        "#a4ffff", # Bright Cyan
        "#ffffff"  # Bright White
      ]
    ).freeze

    # Monokai theme
    MONOKAI = Theme.new(
      name: "monokai",
      background: "#272822",
      foreground: "#f8f8f2",
      cursor: "#f8f8f2",
      palette: [
        "#272822", # Black
        "#f92672", # Red
        "#a6e22e", # Green
        "#f4bf75", # Yellow
        "#66d9ef", # Blue
        "#ae81ff", # Magenta
        "#a1efe4", # Cyan
        "#f8f8f2", # White
        "#75715e", # Bright Black
        "#f92672", # Bright Red
        "#a6e22e", # Bright Green
        "#f4bf75", # Bright Yellow
        "#66d9ef", # Bright Blue
        "#ae81ff", # Bright Magenta
        "#a1efe4", # Bright Cyan
        "#f9f8f5"  # Bright White
      ]
    ).freeze

    # Solarized Dark theme
    SOLARIZED_DARK = Theme.new(
      name: "solarized-dark",
      background: "#002b36",
      foreground: "#839496",
      cursor: "#839496",
      palette: [
        "#073642", # Black
        "#dc322f", # Red
        "#859900", # Green
        "#b58900", # Yellow
        "#268bd2", # Blue
        "#d33682", # Magenta
        "#2aa198", # Cyan
        "#eee8d5", # White
        "#002b36", # Bright Black
        "#cb4b16", # Bright Red
        "#586e75", # Bright Green
        "#657b83", # Bright Yellow
        "#839496", # Bright Blue
        "#6c71c4", # Bright Magenta
        "#93a1a1", # Bright Cyan
        "#fdf6e3"  # Bright White
      ]
    ).freeze

    # Solarized Light theme
    SOLARIZED_LIGHT = Theme.new(
      name: "solarized-light",
      background: "#fdf6e3",
      foreground: "#657b83",
      cursor: "#657b83",
      palette: [
        "#073642", # Black
        "#dc322f", # Red
        "#859900", # Green
        "#b58900", # Yellow
        "#268bd2", # Blue
        "#d33682", # Magenta
        "#2aa198", # Cyan
        "#eee8d5", # White
        "#002b36", # Bright Black
        "#cb4b16", # Bright Red
        "#586e75", # Bright Green
        "#657b83", # Bright Yellow
        "#839496", # Bright Blue
        "#6c71c4", # Bright Magenta
        "#93a1a1", # Bright Cyan
        "#fdf6e3"  # Bright White
      ]
    ).freeze

    # Nord theme
    NORD = Theme.new(
      name: "nord",
      background: "#2e3440",
      foreground: "#d8dee9",
      cursor: "#d8dee9",
      palette: [
        "#3b4252", # Black
        "#bf616a", # Red
        "#a3be8c", # Green
        "#ebcb8b", # Yellow
        "#81a1c1", # Blue
        "#b48ead", # Magenta
        "#88c0d0", # Cyan
        "#e5e9f0", # White
        "#4c566a", # Bright Black
        "#bf616a", # Bright Red
        "#a3be8c", # Bright Green
        "#ebcb8b", # Bright Yellow
        "#81a1c1", # Bright Blue
        "#b48ead", # Bright Magenta
        "#8fbcbb", # Bright Cyan
        "#eceff4"  # Bright White
      ]
    ).freeze

    # One Dark theme (Atom)
    ONE_DARK = Theme.new(
      name: "one-dark",
      background: "#282c34",
      foreground: "#abb2bf",
      cursor: "#528bff",
      palette: [
        "#282c34", # Black
        "#e06c75", # Red
        "#98c379", # Green
        "#e5c07b", # Yellow
        "#61afef", # Blue
        "#c678dd", # Magenta
        "#56b6c2", # Cyan
        "#abb2bf", # White
        "#545862", # Bright Black
        "#e06c75", # Bright Red
        "#98c379", # Bright Green
        "#e5c07b", # Bright Yellow
        "#61afef", # Bright Blue
        "#c678dd", # Bright Magenta
        "#56b6c2", # Bright Cyan
        "#c8ccd4"  # Bright White
      ]
    ).freeze

    # GitHub Dark theme
    GITHUB_DARK = Theme.new(
      name: "github-dark",
      background: "#0d1117",
      foreground: "#c9d1d9",
      cursor: "#c9d1d9",
      palette: [
        "#484f58", # Black
        "#ff7b72", # Red
        "#3fb950", # Green
        "#d29922", # Yellow
        "#58a6ff", # Blue
        "#bc8cff", # Magenta
        "#39c5cf", # Cyan
        "#b1bac4", # White
        "#6e7681", # Bright Black
        "#ffa198", # Bright Red
        "#56d364", # Bright Green
        "#e3b341", # Bright Yellow
        "#79c0ff", # Bright Blue
        "#d2a8ff", # Bright Magenta
        "#56d4dd", # Bright Cyan
        "#f0f6fc"  # Bright White
      ]
    ).freeze

    # Tokyo Night theme
    TOKYO_NIGHT = Theme.new(
      name: "tokyo-night",
      background: "#1a1b26",
      foreground: "#a9b1d6",
      cursor: "#c0caf5",
      palette: [
        "#15161e", # Black
        "#f7768e", # Red
        "#9ece6a", # Green
        "#e0af68", # Yellow
        "#7aa2f7", # Blue
        "#bb9af7", # Magenta
        "#7dcfff", # Cyan
        "#a9b1d6", # White
        "#414868", # Bright Black
        "#f7768e", # Bright Red
        "#9ece6a", # Bright Green
        "#e0af68", # Bright Yellow
        "#7aa2f7", # Bright Blue
        "#bb9af7", # Bright Magenta
        "#7dcfff", # Bright Cyan
        "#c0caf5"  # Bright White
      ]
    ).freeze

    # All available themes
    ALL = {
      "asciinema" => ASCIINEMA,
      "dracula" => DRACULA,
      "monokai" => MONOKAI,
      "solarized-dark" => SOLARIZED_DARK,
      "solarized-light" => SOLARIZED_LIGHT,
      "nord" => NORD,
      "one-dark" => ONE_DARK,
      "github-dark" => GITHUB_DARK,
      "tokyo-night" => TOKYO_NIGHT
    }.freeze

    # Get theme by name
    #
    # @param name [String] Theme name
    # @return [Theme] Theme or default if not found
    def self.get(name)
      ALL[name.to_s.downcase] || ASCIINEMA
    end

    # List available theme names
    #
    # @return [Array<String>] Theme names
    def self.names
      ALL.keys
    end
  end
end
