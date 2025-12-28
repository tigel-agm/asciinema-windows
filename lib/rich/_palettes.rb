# frozen_string_literal: true

require_relative "color_triplet"

module Rich
  # Color palette definitions for terminal color systems.
  # Provides lookup tables for standard 16-color, 256-color (8-bit),
  # and Windows console color palettes.
  module Palettes
    # Standard 16-color ANSI palette (colors 0-15)
    # These are the typical default colors, but terminals may customize them
    STANDARD_PALETTE = [
      ColorTriplet.new(0, 0, 0),        # 0: Black
      ColorTriplet.new(128, 0, 0),      # 1: Red
      ColorTriplet.new(0, 128, 0),      # 2: Green
      ColorTriplet.new(128, 128, 0),    # 3: Yellow
      ColorTriplet.new(0, 0, 128),      # 4: Blue
      ColorTriplet.new(128, 0, 128),    # 5: Magenta
      ColorTriplet.new(0, 128, 128),    # 6: Cyan
      ColorTriplet.new(192, 192, 192),  # 7: White
      ColorTriplet.new(128, 128, 128),  # 8: Bright Black (Gray)
      ColorTriplet.new(255, 0, 0),      # 9: Bright Red
      ColorTriplet.new(0, 255, 0),      # 10: Bright Green
      ColorTriplet.new(255, 255, 0),    # 11: Bright Yellow
      ColorTriplet.new(0, 0, 255),      # 12: Bright Blue
      ColorTriplet.new(255, 0, 255),    # 13: Bright Magenta
      ColorTriplet.new(0, 255, 255),    # 14: Bright Cyan
      ColorTriplet.new(255, 255, 255)   # 15: Bright White
    ].freeze

    # Windows Console palette (slightly different from ANSI standard)
    WINDOWS_PALETTE = [
      ColorTriplet.new(12, 12, 12),     # 0: Black
      ColorTriplet.new(197, 15, 31),    # 1: Red
      ColorTriplet.new(19, 161, 14),    # 2: Green
      ColorTriplet.new(193, 156, 0),    # 3: Yellow
      ColorTriplet.new(0, 55, 218),     # 4: Blue
      ColorTriplet.new(136, 23, 152),   # 5: Magenta
      ColorTriplet.new(58, 150, 221),   # 6: Cyan
      ColorTriplet.new(204, 204, 204),  # 7: White
      ColorTriplet.new(118, 118, 118),  # 8: Bright Black (Gray)
      ColorTriplet.new(231, 72, 86),    # 9: Bright Red
      ColorTriplet.new(22, 198, 12),    # 10: Bright Green
      ColorTriplet.new(249, 241, 165),  # 11: Bright Yellow
      ColorTriplet.new(59, 120, 255),   # 12: Bright Blue
      ColorTriplet.new(180, 0, 158),    # 13: Bright Magenta
      ColorTriplet.new(97, 214, 214),   # 14: Bright Cyan
      ColorTriplet.new(242, 242, 242)   # 15: Bright White
    ].freeze

    # Generate the 256-color (8-bit) palette
    # Colors 0-15: Standard colors
    # Colors 16-231: 6x6x6 color cube
    # Colors 232-255: Grayscale ramp
    EIGHT_BIT_PALETTE = begin
      palette = []

      # Colors 0-15: Standard palette
      STANDARD_PALETTE.each { |color| palette << color }

      # Colors 16-231: 6x6x6 color cube
      # Each component can be 0, 95, 135, 175, 215, or 255
      cube_values = [0, 95, 135, 175, 215, 255]
      (0...6).each do |r|
        (0...6).each do |g|
          (0...6).each do |b|
            palette << ColorTriplet.new(cube_values[r], cube_values[g], cube_values[b])
          end
        end
      end

      # Colors 232-255: Grayscale ramp (24 shades, excluding black and white)
      (0...24).each do |i|
        gray = 8 + i * 10
        palette << ColorTriplet.new(gray, gray, gray)
      end

      palette.freeze
    end

    class << self
      # Find the closest color in a palette
      # @param triplet [ColorTriplet] Color to match
      # @param palette [Array<ColorTriplet>] Palette to search
      # @param start_index [Integer] Starting index in palette
      # @param end_index [Integer] Ending index in palette (exclusive)
      # @return [Integer] Index of closest matching color
      def match_color(triplet, palette: EIGHT_BIT_PALETTE, start_index: 0, end_index: nil)
        end_index ||= palette.length

        best_index = start_index
        best_distance = Float::INFINITY

        (start_index...end_index).each do |i|
          distance = triplet.weighted_distance(palette[i])
          if distance < best_distance
            best_distance = distance
            best_index = i
          end
        end

        best_index
      end

      # Match to standard 16-color palette
      # @param triplet [ColorTriplet] Color to match
      # @return [Integer] Standard color index (0-15)
      def match_standard(triplet)
        match_color(triplet, palette: STANDARD_PALETTE, start_index: 0, end_index: 16)
      end

      # Match to 8-bit palette (256 colors)
      # @param triplet [ColorTriplet] Color to match
      # @return [Integer] 8-bit color index (0-255)
      def match_eight_bit(triplet)
        match_color(triplet, palette: EIGHT_BIT_PALETTE, start_index: 0, end_index: 256)
      end

      # Match to Windows console palette
      # @param triplet [ColorTriplet] Color to match
      # @return [Integer] Windows color index (0-15)
      def match_windows(triplet)
        match_color(triplet, palette: WINDOWS_PALETTE, start_index: 0, end_index: 16)
      end

      # Get a color from the 8-bit palette
      # @param index [Integer] Color index (0-255)
      # @return [ColorTriplet]
      def get_eight_bit(index)
        EIGHT_BIT_PALETTE[index.clamp(0, 255)]
      end

      # Get a color from the standard palette
      # @param index [Integer] Color index (0-15)
      # @return [ColorTriplet]
      def get_standard(index)
        STANDARD_PALETTE[index.clamp(0, 15)]
      end

      # Get a color from the Windows palette
      # @param index [Integer] Color index (0-15)
      # @return [ColorTriplet]
      def get_windows(index)
        WINDOWS_PALETTE[index.clamp(0, 15)]
      end
    end
  end
end
