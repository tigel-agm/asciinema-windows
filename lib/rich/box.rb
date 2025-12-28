# frozen_string_literal: true

module Rich
  # Box drawing character sets for borders and tables
  class Box
    # @return [String] Top-left corner
    attr_reader :top_left

    # @return [String] Top-right corner
    attr_reader :top_right

    # @return [String] Bottom-left corner
    attr_reader :bottom_left

    # @return [String] Bottom-right corner
    attr_reader :bottom_right

    # @return [String] Horizontal line
    attr_reader :horizontal

    # @return [String] Vertical line
    attr_reader :vertical

    # @return [String] Left T-junction
    attr_reader :left_t

    # @return [String] Right T-junction
    attr_reader :right_t

    # @return [String] Top T-junction
    attr_reader :top_t

    # @return [String] Bottom T-junction
    attr_reader :bottom_t

    # @return [String] Cross/plus junction
    attr_reader :cross

    # @return [String] Thick horizontal (for headers)
    attr_reader :thick_horizontal

    # @return [String] Thick left T-junction
    attr_reader :thick_left_t

    # @return [String] Thick right T-junction
    attr_reader :thick_right_t

    # @return [String] Thick cross
    attr_reader :thick_cross

    def initialize(
      top_left:,
      top_right:,
      bottom_left:,
      bottom_right:,
      horizontal:,
      vertical:,
      left_t: nil,
      right_t: nil,
      top_t: nil,
      bottom_t: nil,
      cross: nil,
      thick_horizontal: nil,
      thick_left_t: nil,
      thick_right_t: nil,
      thick_cross: nil
    )
      @top_left = top_left
      @top_right = top_right
      @bottom_left = bottom_left
      @bottom_right = bottom_right
      @horizontal = horizontal
      @vertical = vertical
      @left_t = left_t || vertical
      @right_t = right_t || vertical
      @top_t = top_t || horizontal
      @bottom_t = bottom_t || horizontal
      @cross = cross || "+"
      @thick_horizontal = thick_horizontal || horizontal
      @thick_left_t = thick_left_t || @left_t
      @thick_right_t = thick_right_t || @right_t
      @thick_cross = thick_cross || @cross
      freeze
    end

    # Get the top edge
    # @param width [Integer] Width of content
    # @return [String]
    def top_edge(width)
      "#{@top_left}#{@horizontal * [0, width - 2].max}#{@top_right}"
    end

    # Get the bottom edge
    # @param width [Integer] Width of content
    # @return [String]
    def bottom_edge(width)
      "#{@bottom_left}#{@horizontal * [0, width - 2].max}#{@bottom_right}"
    end

    # Get the row separator
    # @param width_or_cells [Integer, Array] Total width or array of cell contents
    # @param widths [Array<Integer>, nil] Array of column widths
    # @return [String]
    def row(width_or_cells, widths = nil)
      if widths
        # Table row separator with multiple columns
        parts = widths.map { |w| @horizontal * w }
        "#{@left_t}#{parts.join(@cross)}#{@right_t}"
      else
        # Single column separator
        width = width_or_cells.is_a?(Integer) ? width_or_cells : Cells.cell_len(width_or_cells.to_s)
        "#{@left_t}#{@horizontal * [0, width - 2].max}#{@right_t}"
      end
    end

    alias top top_edge
    alias bottom bottom_edge

    # Get a content row
    # @param content [String] Content
    # @param width [Integer] Width to pad to
    # @param align [Symbol] Alignment (:left, :center, :right)
    # @return [String]
    def content_row(content, width, align: :left)
      content_len = Cells.cell_len(content)
      padding = width - content_len

      case align
      when :center
        left_pad = padding / 2
        right_pad = padding - left_pad
        "#{@vertical}#{' ' * left_pad}#{content}#{' ' * right_pad}#{@vertical}"
      when :right
        "#{@vertical}#{' ' * padding}#{content}#{@vertical}"
      else # :left
        "#{@vertical}#{content}#{' ' * padding}#{@vertical}"
      end
    end

    # Get header separator (thicker line)
    # @param width [Integer] Width
    # @return [String]
    def header_separator(width)
      "#{@thick_left_t}#{@thick_horizontal * width}#{@thick_right_t}"
    end

    # Substitute ASCII characters for box characters
    # @return [Box]
    def to_ascii
      ASCII
    end

    # Check if this is the ASCII box
    # @return [Boolean]
    def ascii?
      self == ASCII
    end

    # Predefined box styles
    class << self
      # ASCII characters only
      def ascii
        ASCII
      end

      # Standard Unicode box drawing
      def square
        SQUARE
      end

      # Rounded corners
      def rounded
        ROUNDED
      end

      # Heavy/thick lines
      def heavy
        HEAVY
      end

      # Double lines
      def double
        DOUBLE
      end

      # Minimal (no corners)
      def minimal
        MINIMAL
      end

      # Simple horizontal lines only
      def simple
        SIMPLE
      end

      # No border
      def none
        NONE
      end
    end

    # ASCII box (works everywhere)
    ASCII = new(
      top_left: "+",
      top_right: "+",
      bottom_left: "+",
      bottom_right: "+",
      horizontal: "-",
      vertical: "|",
      left_t: "+",
      right_t: "+",
      top_t: "+",
      bottom_t: "+",
      cross: "+",
      thick_horizontal: "=",
      thick_left_t: "+",
      thick_right_t: "+",
      thick_cross: "+"
    )

    # Standard Unicode box
    SQUARE = new(
      top_left: "┌",
      top_right: "┐",
      bottom_left: "└",
      bottom_right: "┘",
      horizontal: "─",
      vertical: "│",
      left_t: "├",
      right_t: "┤",
      top_t: "┬",
      bottom_t: "┴",
      cross: "┼",
      thick_horizontal: "━",
      thick_left_t: "┝",
      thick_right_t: "┥",
      thick_cross: "┿"
    )

    # Rounded corners
    ROUNDED = new(
      top_left: "╭",
      top_right: "╮",
      bottom_left: "╰",
      bottom_right: "╯",
      horizontal: "─",
      vertical: "│",
      left_t: "├",
      right_t: "┤",
      top_t: "┬",
      bottom_t: "┴",
      cross: "┼",
      thick_horizontal: "━",
      thick_left_t: "┝",
      thick_right_t: "┥",
      thick_cross: "┿"
    )

    # Heavy/thick box
    HEAVY = new(
      top_left: "┏",
      top_right: "┓",
      bottom_left: "┗",
      bottom_right: "┛",
      horizontal: "━",
      vertical: "┃",
      left_t: "┣",
      right_t: "┫",
      top_t: "┳",
      bottom_t: "┻",
      cross: "╋",
      thick_horizontal: "━",
      thick_left_t: "┣",
      thick_right_t: "┫",
      thick_cross: "╋"
    )

    # Double line box
    DOUBLE = new(
      top_left: "╔",
      top_right: "╗",
      bottom_left: "╚",
      bottom_right: "╝",
      horizontal: "═",
      vertical: "║",
      left_t: "╠",
      right_t: "╣",
      top_t: "╦",
      bottom_t: "╩",
      cross: "╬",
      thick_horizontal: "═",
      thick_left_t: "╠",
      thick_right_t: "╣",
      thick_cross: "╬"
    )

    # Minimal (dashes, no corners)
    MINIMAL = new(
      top_left: " ",
      top_right: " ",
      bottom_left: " ",
      bottom_right: " ",
      horizontal: "─",
      vertical: " ",
      left_t: " ",
      right_t: " ",
      top_t: "─",
      bottom_t: "─",
      cross: "─"
    )

    # Simple (just horizontal lines)
    SIMPLE = new(
      top_left: "",
      top_right: "",
      bottom_left: "",
      bottom_right: "",
      horizontal: "─",
      vertical: "",
      left_t: "",
      right_t: "",
      top_t: "",
      bottom_t: "",
      cross: ""
    )

    # No border at all
    NONE = new(
      top_left: "",
      top_right: "",
      bottom_left: "",
      bottom_right: "",
      horizontal: "",
      vertical: "",
      left_t: "",
      right_t: "",
      top_t: "",
      bottom_t: "",
      cross: ""
    )
  end
end
