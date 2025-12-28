# frozen_string_literal: true

require_relative "color_triplet"
require_relative "_palettes"

module Rich
  # Color systems supported by terminals
  module ColorSystem
    STANDARD  = :standard   # 16 colors (4-bit)
    EIGHT_BIT = :eight_bit  # 256 colors (8-bit)
    TRUECOLOR = :truecolor  # 16 million colors (24-bit)
    WINDOWS   = :windows    # Windows Console legacy colors

    ALL = [STANDARD, EIGHT_BIT, TRUECOLOR, WINDOWS].freeze

    class << self
      # @param system [Symbol] Color system
      # @return [Boolean] Whether the color system is valid
      def valid?(system)
        ALL.include?(system)
      end
    end
  end

  # Types of color values
  module ColorType
    DEFAULT   = :default    # Terminal default color
    STANDARD  = :standard   # 16 ANSI colors (0-15)
    EIGHT_BIT = :eight_bit  # 256 colors (0-255)
    TRUECOLOR = :truecolor  # RGB color
    WINDOWS   = :windows    # Windows console color

    ALL = [DEFAULT, STANDARD, EIGHT_BIT, TRUECOLOR, WINDOWS].freeze
  end

  # ANSI color name to number mapping
  ANSI_COLOR_NAMES = {
    "black" => 0,
    "red" => 1,
    "green" => 2,
    "yellow" => 3,
    "blue" => 4,
    "magenta" => 5,
    "cyan" => 6,
    "white" => 7,
    "bright_black" => 8,
    "bright_red" => 9,
    "bright_green" => 10,
    "bright_yellow" => 11,
    "bright_blue" => 12,
    "bright_magenta" => 13,
    "bright_cyan" => 14,
    "bright_white" => 15,
    "grey0" => 16,
    "gray0" => 16,
    "navy_blue" => 17,
    "dark_blue" => 18,
    "blue3" => 20,
    "blue1" => 21,
    "dark_green" => 22,
    "deep_sky_blue4" => 25,
    "dodger_blue3" => 26,
    "dodger_blue2" => 27,
    "green4" => 28,
    "spring_green4" => 29,
    "turquoise4" => 30,
    "deep_sky_blue3" => 32,
    "dodger_blue1" => 33,
    "green3" => 40,
    "spring_green3" => 41,
    "dark_cyan" => 36,
    "light_sea_green" => 37,
    "deep_sky_blue2" => 38,
    "deep_sky_blue1" => 39,
    "spring_green2" => 47,
    "cyan3" => 43,
    "dark_turquoise" => 44,
    "turquoise2" => 45,
    "green1" => 46,
    "spring_green1" => 48,
    "medium_spring_green" => 49,
    "cyan2" => 50,
    "cyan1" => 51,
    "dark_red" => 88,
    "deep_pink4" => 125,
    "purple4" => 55,
    "purple3" => 56,
    "blue_violet" => 57,
    "orange4" => 94,
    "grey37" => 59,
    "gray37" => 59,
    "medium_purple4" => 60,
    "slate_blue3" => 62,
    "royal_blue1" => 63,
    "chartreuse4" => 64,
    "dark_sea_green4" => 71,
    "pale_turquoise4" => 66,
    "steel_blue" => 67,
    "steel_blue3" => 68,
    "cornflower_blue" => 69,
    "chartreuse3" => 76,
    "cadet_blue" => 73,
    "sky_blue3" => 74,
    "steel_blue1" => 81,
    "pale_green3" => 114,
    "sea_green3" => 78,
    "aquamarine3" => 79,
    "medium_turquoise" => 80,
    "chartreuse2" => 112,
    "sea_green2" => 83,
    "sea_green1" => 85,
    "aquamarine1" => 122,
    "dark_slate_gray2" => 87,
    "dark_magenta" => 91,
    "dark_violet" => 128,
    "purple" => 129,
    "light_pink4" => 95,
    "plum4" => 96,
    "medium_purple3" => 98,
    "slate_blue1" => 99,
    "yellow4" => 106,
    "wheat4" => 101,
    "grey53" => 102,
    "gray53" => 102,
    "light_slate_grey" => 103,
    "light_slate_gray" => 103,
    "medium_purple" => 104,
    "light_slate_blue" => 105,
    "dark_olive_green3" => 149,
    "dark_sea_green" => 108,
    "light_sky_blue3" => 110,
    "sky_blue2" => 111,
    "dark_sea_green3" => 150,
    "dark_slate_gray3" => 116,
    "sky_blue1" => 117,
    "chartreuse1" => 118,
    "light_green" => 120,
    "pale_green1" => 156,
    "dark_slate_gray1" => 123,
    "red3" => 160,
    "medium_violet_red" => 126,
    "magenta3" => 164,
    "dark_orange3" => 166,
    "indian_red" => 167,
    "hot_pink3" => 168,
    "medium_orchid3" => 133,
    "medium_orchid" => 134,
    "medium_purple2" => 140,
    "dark_goldenrod" => 136,
    "light_salmon3" => 173,
    "rosy_brown" => 138,
    "grey63" => 139,
    "gray63" => 139,
    "medium_purple1" => 141,
    "gold3" => 178,
    "dark_khaki" => 143,
    "navajo_white3" => 144,
    "grey69" => 145,
    "gray69" => 145,
    "light_steel_blue3" => 146,
    "light_steel_blue" => 147,
    "yellow3" => 184,
    "dark_sea_green2" => 157,
    "light_cyan3" => 152,
    "light_sky_blue1" => 153,
    "green_yellow" => 154,
    "dark_olive_green2" => 155,
    "dark_sea_green1" => 193,
    "pale_turquoise1" => 159,
    "deep_pink3" => 162,
    "magenta2" => 200,
    "hot_pink2" => 169,
    "orchid" => 170,
    "medium_orchid1" => 207,
    "orange3" => 172,
    "light_pink3" => 174,
    "pink3" => 175,
    "plum3" => 176,
    "violet" => 177,
    "light_goldenrod3" => 179,
    "tan" => 180,
    "misty_rose3" => 181,
    "thistle3" => 182,
    "plum2" => 183,
    "khaki3" => 185,
    "light_goldenrod2" => 222,
    "light_yellow3" => 187,
    "grey84" => 188,
    "gray84" => 188,
    "light_steel_blue1" => 189,
    "yellow2" => 190,
    "dark_olive_green1" => 192,
    "honeydew2" => 194,
    "light_cyan1" => 195,
    "red1" => 196,
    "deep_pink2" => 197,
    "deep_pink1" => 199,
    "magenta1" => 201,
    "orange_red1" => 202,
    "indian_red1" => 204,
    "hot_pink" => 206,
    "dark_orange" => 208,
    "salmon1" => 209,
    "light_coral" => 210,
    "pale_violet_red1" => 211,
    "orchid2" => 212,
    "orchid1" => 213,
    "orange1" => 214,
    "sandy_brown" => 215,
    "light_salmon1" => 216,
    "light_pink1" => 217,
    "pink1" => 218,
    "plum1" => 219,
    "gold1" => 220,
    "navajo_white1" => 223,
    "misty_rose1" => 224,
    "thistle1" => 225,
    "yellow1" => 226,
    "light_goldenrod1" => 227,
    "khaki1" => 228,
    "wheat1" => 229,
    "cornsilk1" => 230,
    "grey100" => 231,
    "gray100" => 231,
    "grey3" => 232,
    "gray3" => 232,
    "grey7" => 233,
    "gray7" => 233,
    "grey11" => 234,
    "gray11" => 234,
    "grey15" => 235,
    "gray15" => 235,
    "grey19" => 236,
    "gray19" => 236,
    "grey23" => 237,
    "gray23" => 237,
    "grey27" => 238,
    "gray27" => 238,
    "grey30" => 239,
    "gray30" => 239,
    "grey35" => 240,
    "gray35" => 240,
    "grey39" => 241,
    "gray39" => 241,
    "grey42" => 242,
    "gray42" => 242,
    "grey46" => 243,
    "gray46" => 243,
    "grey50" => 244,
    "gray50" => 244,
    "grey54" => 245,
    "gray54" => 245,
    "grey58" => 246,
    "gray58" => 246,
    "grey62" => 247,
    "gray62" => 247,
    "grey66" => 248,
    "gray66" => 248,
    "grey70" => 249,
    "gray70" => 249,
    "grey74" => 250,
    "gray74" => 250,
    "grey78" => 251,
    "gray78" => 251,
    "grey82" => 252,
    "gray82" => 252,
    "grey85" => 253,
    "gray85" => 253,
    "grey89" => 254,
    "gray89" => 254,
    "grey93" => 255,
    "gray93" => 255
  }.freeze

  # Reverse mapping from number to canonical name
  COLOR_NUMBER_TO_NAME = ANSI_COLOR_NAMES.each_with_object({}) do |(name, number), hash|
    hash[number] ||= name
  end.freeze

  # Error raised when a color definition cannot be parsed
  class ColorParseError < StandardError
  end

  # Represents a terminal color.
  # Supports default colors, standard ANSI colors (0-15), 8-bit colors (0-255),
  # and true color (24-bit RGB).
  class Color
    # Regex for parsing color definitions
    COLOR_REGEX = /\A
      (?:\#(?<hex>[0-9a-fA-F]{6}))|
      (?:color\((?<color8>\d{1,3})\))|
      (?:rgb\((?<rgb>[\d\s,]+)\))
    \z/x

    # @return [String] Original color name or definition
    attr_reader :name

    # @return [Symbol] Color type (see ColorType)
    attr_reader :type

    # @return [Integer, nil] Color number for standard/8-bit colors
    attr_reader :number

    # @return [ColorTriplet, nil] RGB triplet for truecolor
    attr_reader :triplet

    # Cache for parsed colors
    @parse_cache = {}
    @parse_cache_mutex = Mutex.new

    # Cache for downgraded colors
    @downgrade_cache = {}
    @downgrade_cache_mutex = Mutex.new

    # Create a new color
    # @param name [String] Color name or definition
    # @param type [Symbol] Color type (see ColorType)
    # @param number [Integer, nil] Color number
    # @param triplet [ColorTriplet, nil] RGB triplet
    def initialize(name, type:, number: nil, triplet: nil)
      @name = name.freeze
      @type = type
      @number = number
      @triplet = triplet
      freeze
    end

    # @return [Symbol] Native color system for this color
    def system
      case @type
      when ColorType::DEFAULT
        ColorSystem::STANDARD
      when ColorType::STANDARD
        ColorSystem::STANDARD
      when ColorType::EIGHT_BIT
        ColorSystem::EIGHT_BIT
      when ColorType::TRUECOLOR
        ColorSystem::TRUECOLOR
      when ColorType::WINDOWS
        ColorSystem::WINDOWS
      end
    end

    # @return [Boolean] True if color is system-defined (may vary by terminal)
    def system_defined?
      [ColorType::DEFAULT, ColorType::STANDARD].include?(@type)
    end

    # @return [Boolean] True if this is the default color
    def default?
      @type == ColorType::DEFAULT
    end

    # Get the RGB triplet for this color
    # @param theme [TerminalTheme, nil] Terminal theme for system colors
    # @param foreground [Boolean] True for foreground, false for background
    # @return [ColorTriplet] RGB color value
    def get_truecolor(theme: nil, foreground: true)
      case @type
      when ColorType::TRUECOLOR
        @triplet
      when ColorType::EIGHT_BIT
        Palettes.get_eight_bit(@number)
      when ColorType::STANDARD
        if theme
          theme.ansi_colors[@number]
        else
          Palettes.get_standard(@number)
        end
      when ColorType::WINDOWS
        Palettes.get_windows(@number)
      when ColorType::DEFAULT
        if theme
          foreground ? theme.foreground : theme.background
        else
          foreground ? ColorTriplet.new(255, 255, 255) : ColorTriplet.new(0, 0, 0)
        end
      end
    end

    # Get ANSI escape codes for this color
    # @param foreground [Boolean] True for foreground, false for background
    # @return [Array<String>] ANSI code components
    def ansi_codes(foreground: true)
      case @type
      when ColorType::DEFAULT
        [foreground ? "39" : "49"]
      when ColorType::STANDARD
        base = foreground ? 30 : 40
        offset = @number < 8 ? @number : (@number - 8 + 60)
        [(base + (@number < 8 ? @number : @number - 8 + 60)).to_s]
      when ColorType::EIGHT_BIT
        [foreground ? "38" : "48", "5", @number.to_s]
      when ColorType::TRUECOLOR
        [foreground ? "38" : "48", "2", @triplet.red.to_s, @triplet.green.to_s, @triplet.blue.to_s]
      when ColorType::WINDOWS
        base = @number < 8 ? (foreground ? 30 : 40) : (foreground ? 90 : 100)
        [(base + @number % 8).to_s]
      else
        []
      end
    end

    # Downgrade color to a simpler color system
    # @param target_system [Symbol] Target color system
    # @return [Color] Downgraded color (may be self if no downgrade needed)
    def downgrade(target_system)
      return self if @type == ColorType::DEFAULT
      return self if target_system == system

      cache_key = [@type, @number, @triplet&.to_a, target_system]

      self.class.instance_variable_get(:@downgrade_cache_mutex).synchronize do
        cache = self.class.instance_variable_get(:@downgrade_cache)
        return cache[cache_key] if cache.key?(cache_key)

        result = compute_downgrade(target_system)
        cache[cache_key] = result
        result
      end
    end

    # Check equality with another color
    def ==(other)
      return false unless other.is_a?(Color)

      @type == other.type && @number == other.number && @triplet == other.triplet
    end

    alias eql? ==

    def hash
      [@type, @number, @triplet].hash
    end

    def to_s
      @name
    end

    def inspect
      case @type
      when ColorType::DEFAULT
        "#<Rich::Color default>"
      when ColorType::TRUECOLOR
        "#<Rich::Color #{@name} (#{@triplet.hex})>"
      else
        "#<Rich::Color #{@name} (#{@type}:#{@number})>"
      end
    end

    class << self
      # Parse a color definition string
      # @param color [String] Color definition
      # @return [Color] Parsed color
      # @raise [ColorParseError] If color cannot be parsed
      def parse(color)
        return color if color.is_a?(Color)

        @parse_cache_mutex.synchronize do
          return @parse_cache[color] if @parse_cache.key?(color)
        end

        result = parse_uncached(color)

        @parse_cache_mutex.synchronize do
          @parse_cache[color] = result
        end

        result
      end

      # Create a default color
      # @return [Color]
      def default
        @default ||= new("default", type: ColorType::DEFAULT)
      end

      # Create a color from ANSI number
      # @param number [Integer] Color number (0-255)
      # @return [Color]
      def from_ansi(number)
        number = number.clamp(0, 255)
        type = number < 16 ? ColorType::STANDARD : ColorType::EIGHT_BIT
        name = COLOR_NUMBER_TO_NAME[number] || "color(#{number})"
        new(name, type: type, number: number)
      end

      # Create a color from RGB triplet
      # @param triplet [ColorTriplet] RGB triplet
      # @return [Color]
      def from_triplet(triplet)
        new(triplet.hex, type: ColorType::TRUECOLOR, triplet: triplet)
      end

      # Create a color from RGB values
      # @param red [Integer] Red (0-255)
      # @param green [Integer] Green (0-255)
      # @param blue [Integer] Blue (0-255)
      # @return [Color]
      def from_rgb(red, green, blue)
        from_triplet(ColorTriplet.new(red, green, blue))
      end

      private

      def parse_uncached(color)
        original = color
        color = color.to_s.strip.downcase

        return default if color == "default"

        # Check named colors
        if ANSI_COLOR_NAMES.key?(color)
          number = ANSI_COLOR_NAMES[color]
          type = number < 16 ? ColorType::STANDARD : ColorType::EIGHT_BIT
          return new(color, type: type, number: number)
        end

        # Try regex patterns
        match = COLOR_REGEX.match(color)
        raise ColorParseError, "'#{original}' is not a valid color" unless match

        if match[:hex]
          triplet = ColorTriplet.from_hex(match[:hex])
          return new(color, type: ColorType::TRUECOLOR, triplet: triplet)
        end

        if match[:color8]
          number = match[:color8].to_i
          raise ColorParseError, "Color number must be <= 255 in '#{original}'" if number > 255

          type = number < 16 ? ColorType::STANDARD : ColorType::EIGHT_BIT
          return new(color, type: type, number: number)
        end

        if match[:rgb]
          parts = match[:rgb].split(",").map(&:strip).map(&:to_i)
          raise ColorParseError, "Expected 3 RGB components in '#{original}'" unless parts.length == 3
          raise ColorParseError, "Color components must be <= 255 in '#{original}'" if parts.any? { |p| p > 255 }

          triplet = ColorTriplet.new(*parts)
          return new(color, type: ColorType::TRUECOLOR, triplet: triplet)
        end

        raise ColorParseError, "'#{original}' is not a valid color"
      end
    end

    private

    def compute_downgrade(target_system)
      triplet = get_truecolor

      case target_system
      when ColorSystem::EIGHT_BIT
        return self if @type == ColorType::EIGHT_BIT

        # Convert to grayscale if low saturation
        r, g, b = triplet.normalized
        _h, l, s = rgb_to_hls(r, g, b)

        if s < 0.15
          gray = (l * 25.0).round
          color_number = if gray == 0
                           16
                         elsif gray == 25
                           231
                         else
                           231 + gray
                         end
          return Color.new(@name, type: ColorType::EIGHT_BIT, number: color_number)
        end

        # Map to 6x6x6 color cube
        six_red = triplet.red < 95 ? triplet.red / 95.0 : 1 + (triplet.red - 95) / 40.0
        six_green = triplet.green < 95 ? triplet.green / 95.0 : 1 + (triplet.green - 95) / 40.0
        six_blue = triplet.blue < 95 ? triplet.blue / 95.0 : 1 + (triplet.blue - 95) / 40.0

        color_number = 16 + 36 * six_red.round + 6 * six_green.round + six_blue.round
        Color.new(@name, type: ColorType::EIGHT_BIT, number: color_number.to_i)

      when ColorSystem::STANDARD
        number = Palettes.match_standard(triplet)
        Color.new(@name, type: ColorType::STANDARD, number: number)

      when ColorSystem::WINDOWS
        if @type == ColorType::EIGHT_BIT && @number < 16
          return Color.new(@name, type: ColorType::WINDOWS, number: @number)
        end

        number = Palettes.match_windows(triplet)
        Color.new(@name, type: ColorType::WINDOWS, number: number)

      else
        self
      end
    end

    def rgb_to_hls(r, g, b)
      max_c = [r, g, b].max
      min_c = [r, g, b].min
      l = (max_c + min_c) / 2.0

      return [0.0, l, 0.0] if max_c == min_c

      s = if l <= 0.5
            (max_c - min_c) / (max_c + min_c)
          else
            (max_c - min_c) / (2.0 - max_c - min_c)
          end

      rc = (max_c - r) / (max_c - min_c)
      gc = (max_c - g) / (max_c - min_c)
      bc = (max_c - b) / (max_c - min_c)

      h = if r == max_c
            bc - gc
          elsif g == max_c
            2.0 + rc - bc
          else
            4.0 + gc - rc
          end

      h = (h / 6.0) % 1.0
      [h, l, s]
    end
  end
end
