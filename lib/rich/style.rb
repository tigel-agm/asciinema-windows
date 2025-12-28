# frozen_string_literal: true

require_relative "color"

module Rich
  # Style attributes represented as bit flags
  module StyleAttribute
    BOLD          = 1 << 0   # 1
    DIM           = 1 << 1   # 2
    ITALIC        = 1 << 2   # 4
    UNDERLINE     = 1 << 3   # 8
    BLINK         = 1 << 4   # 16
    BLINK2        = 1 << 5   # 32 (rapid blink)
    REVERSE       = 1 << 6   # 64
    CONCEAL       = 1 << 7   # 128
    STRIKE        = 1 << 8   # 256
    UNDERLINE2    = 1 << 9   # 512 (double underline)
    FRAME         = 1 << 10  # 1024
    ENCIRCLE      = 1 << 11  # 2048
    OVERLINE      = 1 << 12  # 4096

    ALL = {
      bold: BOLD,
      dim: DIM,
      italic: ITALIC,
      underline: UNDERLINE,
      blink: BLINK,
      blink2: BLINK2,
      reverse: REVERSE,
      conceal: CONCEAL,
      strike: STRIKE,
      underline2: UNDERLINE2,
      frame: FRAME,
      encircle: ENCIRCLE,
      overline: OVERLINE
    }.freeze

    NAMES = ALL.keys.freeze
  end

  # Represents a terminal style with colors and text attributes.
  # Styles are immutable and can be combined using the + operator.
  class Style
    # ANSI reset and attribute codes
    ANSI_CODES = {
      bold: "1",
      dim: "2",
      italic: "3",
      underline: "4",
      blink: "5",
      blink2: "6",
      reverse: "7",
      conceal: "8",
      strike: "9",
      underline2: "21",
      frame: "51",
      encircle: "52",
      overline: "53"
    }.freeze

    # Regex for parsing style definitions
    STYLE_REGEX = /
      (?<not>not\s+)?
      (?<attr>bold|dim|italic|underline2?|blink2?|reverse|conceal|strike|frame|encircle|overline)|
      (?<link>link\s+(?<url>\S+))|
      (?<on>on\s+)?(?<color>\S+)
    /x

    # @return [Color, nil] Foreground color
    attr_reader :color

    # @return [Color, nil] Background color
    attr_reader :bgcolor

    # @return [Integer] Attributes that are explicitly set
    attr_reader :set_attributes

    # @return [Integer] Attribute values (0 = off, 1 = on)
    attr_reader :attributes

    # @return [String, nil] Hyperlink URL
    attr_reader :link

    # @return [Hash, nil] Meta information
    attr_reader :meta

    # Cache for parsed styles
    @parse_cache = {}
    @parse_cache_mutex = Mutex.new

    # Create a new style
    # @param color [Color, String, nil] Foreground color
    # @param bgcolor [Color, String, nil] Background color
    # @param bold [Boolean, nil] Bold attribute
    # @param dim [Boolean, nil] Dim attribute
    # @param italic [Boolean, nil] Italic attribute
    # @param underline [Boolean, nil] Underline attribute
    # @param blink [Boolean, nil] Blink attribute
    # @param blink2 [Boolean, nil] Rapid blink attribute
    # @param reverse [Boolean, nil] Reverse video attribute
    # @param conceal [Boolean, nil] Conceal attribute
    # @param strike [Boolean, nil] Strikethrough attribute
    # @param underline2 [Boolean, nil] Double underline attribute
    # @param frame [Boolean, nil] Frame attribute
    # @param encircle [Boolean, nil] Encircle attribute
    # @param overline [Boolean, nil] Overline attribute
    # @param link [String, nil] Hyperlink URL
    # @param meta [Hash, nil] Meta information
    def initialize(
      color: nil,
      bgcolor: nil,
      bold: nil,
      dim: nil,
      italic: nil,
      underline: nil,
      blink: nil,
      blink2: nil,
      reverse: nil,
      conceal: nil,
      strike: nil,
      underline2: nil,
      frame: nil,
      encircle: nil,
      overline: nil,
      link: nil,
      meta: nil
    )
      @color = parse_color(color)
      @bgcolor = parse_color(bgcolor)
      @link = link&.freeze
      @meta = meta&.freeze

      # Build attribute masks
      @set_attributes = 0
      @attributes = 0

      attrs = {
        bold: bold, dim: dim, italic: italic, underline: underline,
        blink: blink, blink2: blink2, reverse: reverse, conceal: conceal,
        strike: strike, underline2: underline2, frame: frame,
        encircle: encircle, overline: overline
      }

      attrs.each do |name, value|
        next if value.nil?

        bit = StyleAttribute::ALL[name]
        @set_attributes |= bit
        @attributes |= bit if value
      end

      freeze
    end

    # Check if any attributes, colors, or link are set
    # @return [Boolean]
    def blank?
      @color.nil? && @bgcolor.nil? && @set_attributes == 0 && @link.nil?
    end

    # @return [Boolean] False if blank
    def present?
      !blank?
    end

    # Get a specific attribute value
    # @param name [Symbol] Attribute name
    # @return [Boolean, nil] Attribute value or nil if not set
    def [](name)
      bit = StyleAttribute::ALL[name]
      return nil unless bit

      return nil if (@set_attributes & bit) == 0

      (@attributes & bit) != 0
    end

    # Attribute accessor methods
    StyleAttribute::NAMES.each do |attr_name|
      define_method(attr_name) { self[attr_name] }
      define_method("#{attr_name}?") { self[attr_name] == true }
    end

    # Generate ANSI escape codes for this style
    # @param color_system [Symbol] Target color system
    # @return [String] ANSI escape sequence
    def render(color_system: ColorSystem::TRUECOLOR)
      codes = []

      # Add attribute codes
      StyleAttribute::NAMES.each do |name|
        value = self[name]
        next if value.nil?

        if value
          codes << ANSI_CODES[name]
        end
      end

      # Add color codes
      if @color
        target_color = @color.downgrade(color_system)
        codes.concat(target_color.ansi_codes(foreground: true))
      end

      if @bgcolor
        target_color = @bgcolor.downgrade(color_system)
        codes.concat(target_color.ansi_codes(foreground: false))
      end

      return "" if codes.empty?

      "\e[#{codes.join(';')}m"
    end

    # Generate the style definition string
    # @return [String]
    def to_s
      parts = []

      StyleAttribute::NAMES.each do |name|
        value = self[name]
        next if value.nil?

        parts << (value ? name.to_s : "not #{name}")
      end

      parts << @color.name if @color
      parts << "on #{@bgcolor.name}" if @bgcolor
      parts << "link #{@link}" if @link

      parts.join(" ")
    end

    def inspect
      attrs = []
      attrs << "color=#{@color.name}" if @color
      attrs << "bgcolor=#{@bgcolor.name}" if @bgcolor

      StyleAttribute::NAMES.each do |name|
        value = self[name]
        attrs << "#{name}=#{value}" unless value.nil?
      end

      attrs << "link=#{@link.inspect}" if @link

      "#<Rich::Style #{attrs.join(' ')}>"
    end

    # Combine two styles (right-hand style takes precedence)
    # @param other [Style] Style to combine with
    # @return [Style] Combined style
    def +(other)
      return self if other.nil? || other.blank?
      return other if blank?

      new_color = other.color || @color
      new_bgcolor = other.bgcolor || @bgcolor
      new_link = other.link || @link
      new_meta = @meta || other.meta ? (@meta || {}).merge(other.meta || {}) : nil

      # Merge attributes
      new_set = @set_attributes | other.set_attributes
      new_attrs = (@attributes & ~other.set_attributes) | (other.attributes & other.set_attributes)

      Style.combine(
        color: new_color,
        bgcolor: new_bgcolor,
        link: new_link,
        meta: new_meta,
        set_attributes: new_set,
        attributes: new_attrs
      )
    end

    # Get style with no colors
    # @return [Style]
    def without_color
      Style.combine(
        color: nil,
        bgcolor: nil,
        link: @link,
        meta: @meta,
        set_attributes: @set_attributes,
        attributes: @attributes
      )
    end

    # Get background-only style
    # @return [Style]
    def background_style
      Style.new(bgcolor: @bgcolor)
    end

    def ==(other)
      return false unless other.is_a?(Style)

      @color == other.color &&
        @bgcolor == other.bgcolor &&
        @set_attributes == other.set_attributes &&
        @attributes == other.attributes &&
        @link == other.link
    end

    alias eql? ==

    def hash
      [@color, @bgcolor, @set_attributes, @attributes, @link].hash
    end

    class << self
      # Parse a style definition string
      # @param style [String, Style, nil] Style definition
      # @return [Style]
      def parse(style)
        return null if style.nil? || (style.is_a?(String) && style.empty?)
        return style if style.is_a?(Style)

        style = style.to_s

        @parse_cache_mutex.synchronize do
          return @parse_cache[style] if @parse_cache.key?(style)
        end

        result = parse_uncached(style)

        @parse_cache_mutex.synchronize do
          @parse_cache[style] = result
        end

        result
      end

      # Create a null (empty) style
      # @return [Style]
      def null
        @null ||= new
      end

      # Create a combined style with explicit attributes (internal use)
      # @param color [Color, nil] Foreground color
      # @param bgcolor [Color, nil] Background color
      # @param link [String, nil] Hyperlink
      # @param meta [Hash, nil] Meta info
      # @param set_attributes [Integer] Set attributes bitmask
      # @param attributes [Integer] Attribute values bitmask
      # @return [Style]
      def combine(color:, bgcolor:, link:, meta:, set_attributes:, attributes:)
        style = allocate
        style.instance_variable_set(:@color, color)
        style.instance_variable_set(:@bgcolor, bgcolor)
        style.instance_variable_set(:@link, link&.freeze)
        style.instance_variable_set(:@meta, meta&.freeze)
        style.instance_variable_set(:@set_attributes, set_attributes)
        style.instance_variable_set(:@attributes, attributes)
        style.freeze
        style
      end

      # Create a style from just colors
      # @param color [Color, String, nil] Foreground color
      # @param bgcolor [Color, String, nil] Background color
      # @return [Style]
      def from_color(color: nil, bgcolor: nil)
        new(color: color, bgcolor: bgcolor)
      end

      # Create a style with meta information
      # @param meta [Hash] Meta data
      # @return [Style]
      def from_meta(meta)
        new(meta: meta)
      end

      # Normalize a style definition
      # @param style [String] Style definition
      # @return [String] Normalized style definition
      def normalize(style)
        parse(style).to_s
      end

      private

      def parse_uncached(style_str)
        attrs = {}
        color = nil
        bgcolor = nil
        link = nil

        style_str.scan(STYLE_REGEX) do
          match = Regexp.last_match

          if match[:attr]
            attr_name = match[:attr].to_sym
            attrs[attr_name] = match[:not].nil?
          elsif match[:link]
            link = match[:url]
          elsif match[:color]
            color_name = match[:color]
            begin
              parsed_color = Color.parse(color_name)
              if match[:on]
                bgcolor = parsed_color
              else
                color = parsed_color
              end
            rescue ColorParseError
              # Ignore invalid colors
            end
          end
        end

        new(
          color: color,
          bgcolor: bgcolor,
          link: link,
          **attrs
        )
      end
    end

    private

    def parse_color(color)
      return nil if color.nil?
      return color if color.is_a?(Color)

      Color.parse(color)
    rescue ColorParseError
      nil
    end
  end
end
