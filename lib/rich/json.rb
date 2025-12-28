# frozen_string_literal: true

require "json"
require_relative "style"
require_relative "segment"

module Rich
  # JSON syntax highlighting and formatting
  module JSON
    # Default styles for JSON elements
    DEFAULT_STYLES = {
      key: "cyan",
      string: "green",
      number: "yellow",
      boolean: "italic magenta",
      null: "dim",
      brace: "bold",
      bracket: "bold",
      comma: "dim",
      colon: "dim"
    }.freeze

    class << self
      # Render JSON with syntax highlighting
      # @param data [Object] Data to render as JSON
      # @param indent [Integer] Indentation size
      # @param styles [Hash] Style overrides
      # @return [Array<Segment>]
      def render(data, indent: 2, styles: {})
        merged_styles = DEFAULT_STYLES.merge(styles)
        json_str = ::JSON.pretty_generate(data, indent: " " * indent)

        segments = []
        tokenize(json_str, merged_styles, segments)
        segments
      end

      # Render to string with ANSI codes
      # @param data [Object] Data to render
      # @param indent [Integer] Indentation
      # @param color_system [Symbol] Color system
      # @return [String]
      def to_s(data, indent: 2, color_system: ColorSystem::TRUECOLOR)
        segments = render(data, indent: indent)
        Segment.render(segments, color_system: color_system)
      end

      # Parse and render a JSON string
      # @param json_str [String] JSON string
      # @param styles [Hash] Style overrides
      # @return [Array<Segment>]
      def highlight(json_str, styles: {})
        merged_styles = DEFAULT_STYLES.merge(styles)
        segments = []
        tokenize(json_str, merged_styles, segments)
        segments
      end

      private

      def tokenize(json_str, styles, segments)
        pos = 0

        while pos < json_str.length
          char = json_str[pos]

          case char
          when "{"
            segments << Segment.new("{", style: parse_style(styles[:brace]))
            pos += 1
          when "}"
            segments << Segment.new("}", style: parse_style(styles[:brace]))
            pos += 1
          when "["
            segments << Segment.new("[", style: parse_style(styles[:bracket]))
            pos += 1
          when "]"
            segments << Segment.new("]", style: parse_style(styles[:bracket]))
            pos += 1
          when ","
            segments << Segment.new(",", style: parse_style(styles[:comma]))
            pos += 1
          when ":"
            segments << Segment.new(":", style: parse_style(styles[:colon]))
            pos += 1
          when '"'
            # String - check if it's a key (followed by :)
            str_end = find_string_end(json_str, pos)
            str_content = json_str[pos..str_end]

            # Look ahead to see if this is a key
            look_ahead = json_str[str_end + 1..].lstrip
            is_key = look_ahead.start_with?(":")

            style = is_key ? styles[:key] : styles[:string]
            segments << Segment.new(str_content, style: parse_style(style))
            pos = str_end + 1
          when /[0-9\-]/
            # Number
            num_end = pos
            while num_end < json_str.length && json_str[num_end].match?(/[0-9eE.\-+]/)
              num_end += 1
            end
            num_content = json_str[pos...num_end]
            segments << Segment.new(num_content, style: parse_style(styles[:number]))
            pos = num_end
          when /[tfn]/
            # Boolean or null
            if json_str[pos, 4] == "true"
              segments << Segment.new("true", style: parse_style(styles[:boolean]))
              pos += 4
            elsif json_str[pos, 5] == "false"
              segments << Segment.new("false", style: parse_style(styles[:boolean]))
              pos += 5
            elsif json_str[pos, 4] == "null"
              segments << Segment.new("null", style: parse_style(styles[:null]))
              pos += 4
            else
              segments << Segment.new(char)
              pos += 1
            end
          when /\s/
            # Whitespace
            ws_end = pos
            while ws_end < json_str.length && json_str[ws_end].match?(/\s/)
              ws_end += 1
            end
            segments << Segment.new(json_str[pos...ws_end])
            pos = ws_end
          else
            segments << Segment.new(char)
            pos += 1
          end
        end
      end

      def find_string_end(str, start_pos)
        pos = start_pos + 1
        while pos < str.length
          if str[pos] == '"' && str[pos - 1] != '\\'
            return pos
          end
          pos += 1
        end
        str.length - 1
      end

      def parse_style(style)
        return nil if style.nil?
        return style if style.is_a?(Style)

        Style.parse(style)
      end
    end
  end

  # Pretty printing of Ruby objects
  module Pretty
    class << self
      # Pretty print a Ruby object
      # @param obj [Object] Object to print
      # @param indent [Integer] Indentation
      # @return [Array<Segment>]
      def render(obj, indent: 2)
        segments = []
        render_object(obj, 0, indent, segments)
        segments
      end

      # Render to string
      # @param obj [Object] Object to render
      # @param color_system [Symbol] Color system
      # @return [String]
      def to_s(obj, color_system: ColorSystem::TRUECOLOR)
        Segment.render(render(obj), color_system: color_system)
      end

      private

      def render_object(obj, depth, indent, segments)
        case obj
        when NilClass
          segments << Segment.new("nil", style: Style.parse("dim"))
        when TrueClass, FalseClass
          segments << Segment.new(obj.to_s, style: Style.parse("italic magenta"))
        when Integer, Float
          segments << Segment.new(obj.to_s, style: Style.parse("yellow"))
        when String
          segments << Segment.new(obj.inspect, style: Style.parse("green"))
        when Symbol
          segments << Segment.new(":#{obj}", style: Style.parse("cyan bold"))
        when Array
          render_array(obj, depth, indent, segments)
        when Hash
          render_hash(obj, depth, indent, segments)
        else
          segments << Segment.new(obj.inspect, style: Style.parse("white"))
        end
      end

      def render_array(arr, depth, indent, segments)
        if arr.empty?
          segments << Segment.new("[]", style: Style.parse("bold"))
          return
        end

        segments << Segment.new("[", style: Style.parse("bold"))
        segments << Segment.new("\n")

        arr.each_with_index do |item, index|
          segments << Segment.new(" " * ((depth + 1) * indent))
          render_object(item, depth + 1, indent, segments)
          segments << Segment.new(",") if index < arr.length - 1
          segments << Segment.new("\n")
        end

        segments << Segment.new(" " * (depth * indent))
        segments << Segment.new("]", style: Style.parse("bold"))
      end

      def render_hash(hash, depth, indent, segments)
        if hash.empty?
          segments << Segment.new("{}", style: Style.parse("bold"))
          return
        end

        segments << Segment.new("{", style: Style.parse("bold"))
        segments << Segment.new("\n")

        entries = hash.to_a
        entries.each_with_index do |(key, value), index|
          segments << Segment.new(" " * ((depth + 1) * indent))

          # Key
          if key.is_a?(Symbol)
            segments << Segment.new(":#{key}", style: Style.parse("cyan"))
          else
            segments << Segment.new(key.inspect, style: Style.parse("cyan"))
          end

          segments << Segment.new(" => ", style: Style.parse("dim"))

          # Value
          render_object(value, depth + 1, indent, segments)
          segments << Segment.new(",") if index < entries.length - 1
          segments << Segment.new("\n")
        end

        segments << Segment.new(" " * (depth * indent))
        segments << Segment.new("}", style: Style.parse("bold"))
      end
    end
  end
end
