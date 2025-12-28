# frozen_string_literal: true

module Rich
  # Represents an RGB color triplet with values from 0-255.
  # This is an immutable value object used for true color representation.
  class ColorTriplet
    # @return [Integer] Red component (0-255)
    attr_reader :red

    # @return [Integer] Green component (0-255)
    attr_reader :green

    # @return [Integer] Blue component (0-255)
    attr_reader :blue

    # Create a new color triplet
    # @param red [Integer] Red component (0-255)
    # @param green [Integer] Green component (0-255)
    # @param blue [Integer] Blue component (0-255)
    def initialize(red, green, blue)
      @red = clamp_component(red)
      @green = clamp_component(green)
      @blue = clamp_component(blue)
      freeze
    end

    # @return [String] Hexadecimal representation (e.g., "#ff0000")
    def hex
      format("%02x%02x%02x", @red, @green, @blue)
    end

    # @return [String] RGB string representation (e.g., "rgb(255, 0, 0)")
    def rgb
      "rgb(#{@red}, #{@green}, #{@blue})"
    end

    # @return [Array<Float>] Normalized components (0.0-1.0)
    def normalized
      [@red / 255.0, @green / 255.0, @blue / 255.0]
    end

    # @return [Array<Integer>] Components as array [red, green, blue]
    def to_a
      [@red, @green, @blue]
    end

    # @return [Hash] Components as hash
    def to_h
      { red: @red, green: @green, blue: @blue }
    end

    # Check equality with another triplet
    # @param other [ColorTriplet, Object] Object to compare
    # @return [Boolean]
    def ==(other)
      return false unless other.is_a?(ColorTriplet)

      @red == other.red && @green == other.green && @blue == other.blue
    end

    alias eql? ==

    # @return [Integer] Hash code for use in hash tables
    def hash
      [@red, @green, @blue].hash
    end

    # @return [String] String representation
    def to_s
      hex
    end

    # @return [String] Inspect representation
    def inspect
      "#<Rich::ColorTriplet #{hex} (#{@red}, #{@green}, #{@blue})>"
    end

    # Deconstruct for pattern matching
    # @return [Array<Integer>]
    def deconstruct
      to_a
    end

    # Deconstruct for pattern matching with keys
    # @param keys [Array<Symbol>]
    # @return [Hash]
    def deconstruct_keys(keys)
      to_h.slice(*(keys || [:red, :green, :blue]))
    end

    # Calculate the perceived luminance of the color
    # Uses the formula for relative luminance from WCAG 2.0
    # @return [Float] Luminance value (0.0-1.0)
    def luminance
      r, g, b = normalized.map do |c|
        c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055)**2.4
      end
      0.2126 * r + 0.7152 * g + 0.0722 * b
    end

    # Check if this is a "dark" color based on luminance
    # @return [Boolean]
    def dark?
      luminance < 0.5
    end

    # Check if this is a "light" color based on luminance
    # @return [Boolean]
    def light?
      !dark?
    end

    # Blend this color with another
    # @param other [ColorTriplet] Color to blend with
    # @param factor [Float] Blend factor (0.0 = this color, 1.0 = other color)
    # @return [ColorTriplet] Blended color
    def blend(other, factor = 0.5)
      factor = [[factor, 0.0].max, 1.0].min

      new_r = (@red + (other.red - @red) * factor).round
      new_g = (@green + (other.green - @green) * factor).round
      new_b = (@blue + (other.blue - @blue) * factor).round

      ColorTriplet.new(new_r, new_g, new_b)
    end

    # Calculate color distance (Euclidean in RGB space)
    # @param other [ColorTriplet] Color to compare
    # @return [Float] Distance value
    def distance(other)
      dr = @red - other.red
      dg = @green - other.green
      db = @blue - other.blue
      Math.sqrt(dr * dr + dg * dg + db * db)
    end

    # Calculate weighted color distance (better perceptual accuracy)
    # Uses weighted Euclidean distance based on human color perception
    # @param other [ColorTriplet] Color to compare
    # @return [Float] Weighted distance value
    def weighted_distance(other)
      dr = @red - other.red
      dg = @green - other.green
      db = @blue - other.blue

      # Weighted by perceptual importance (red-green component is most important)
      r_mean = (@red + other.red) / 2.0
      weight_r = 2.0 + r_mean / 256.0
      weight_g = 4.0
      weight_b = 2.0 + (255.0 - r_mean) / 256.0

      Math.sqrt(weight_r * dr * dr + weight_g * dg * dg + weight_b * db * db)
    end

    class << self
      # Create from hex string
      # @param hex_str [String] Hex color string (e.g., "#ff0000" or "ff0000")
      # @return [ColorTriplet]
      def from_hex(hex_str)
        hex_str = hex_str.delete_prefix("#")
        raise ArgumentError, "Invalid hex color: #{hex_str}" unless hex_str.match?(/\A[0-9a-fA-F]{6}\z/)

        r = hex_str[0, 2].to_i(16)
        g = hex_str[2, 2].to_i(16)
        b = hex_str[4, 2].to_i(16)

        new(r, g, b)
      end

      # Create from normalized values (0.0-1.0)
      # @param r [Float] Red component (0.0-1.0)
      # @param g [Float] Green component (0.0-1.0)
      # @param b [Float] Blue component (0.0-1.0)
      # @return [ColorTriplet]
      def from_normalized(r, g, b)
        new(
          (r * 255).round,
          (g * 255).round,
          (b * 255).round
        )
      end

      # Create from HSL values
      # @param h [Float] Hue (0-360)
      # @param s [Float] Saturation (0-100)
      # @param l [Float] Lightness (0-100)
      # @return [ColorTriplet]
      def from_hsl(h, s, l)
        h = h % 360
        s = s / 100.0
        l = l / 100.0

        c = (1 - (2 * l - 1).abs) * s
        x = c * (1 - ((h / 60.0) % 2 - 1).abs)
        m = l - c / 2.0

        r, g, b = case (h / 60).floor
                  when 0 then [c, x, 0]
                  when 1 then [x, c, 0]
                  when 2 then [0, c, x]
                  when 3 then [0, x, c]
                  when 4 then [x, 0, c]
                  else [c, 0, x]
                  end

        new(
          ((r + m) * 255).round,
          ((g + m) * 255).round,
          ((b + m) * 255).round
        )
      end
    end

    private

    def clamp_component(value)
      [[value.to_i, 0].max, 255].min
    end
  end
end
