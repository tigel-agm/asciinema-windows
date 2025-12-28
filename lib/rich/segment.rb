# frozen_string_literal: true

require_relative "style"
require_relative "cells"
require_relative "control"

module Rich
  # A piece of text with associated style.
  # Segments are the fundamental unit produced by the rendering process
  # and are ultimately converted to strings for terminal output.
  class Segment
    # @return [String] Text content
    attr_reader :text

    # @return [Style, nil] Style for the text
    attr_reader :style

    # @return [Array, nil] Control codes (non-printable)
    attr_reader :control

    # Create a new segment
    # @param text [String] Text content
    # @param style [Style, nil] Style to apply
    # @param control [Array, nil] Control codes
    def initialize(text = "", style: nil, control: nil)
      @text = text.freeze
      @style = style
      @control = control&.freeze
      freeze
    end

    # @return [Integer] Display width in terminal cells
    def cell_length
      return 0 if control?

      Cells.cached_cell_len(@text)
    end

    # @return [Boolean] True if segment has text content
    def present?
      !@text.empty?
    end

    # @return [Boolean] True if segment is empty
    def empty?
      @text.empty?
    end

    # @return [Boolean] True if this is a control segment
    def control?
      !@control.nil?
    end

    # @return [Boolean] True if segment has text (used for truthiness)
    def to_bool
      present?
    end

    # Split segment at a cell position
    # @param cut [Integer] Cell position to split at
    # @return [Array<Segment>] Two segments [before, after]
    def split_cells(cut)
      return [self.class.new("", style: @style), self] if cut <= 0
      return [self, self.class.new("", style: @style)] if cut >= cell_length

      self.class.split_at_cell(@text, cut, @style)
    end

    # Get segment text with ANSI reset if needed
    # @return [String]
    def to_s
      @text
    end

    def inspect
      if control?
        "#<Rich::Segment control=#{@control.inspect}>"
      elsif @style
        "#<Rich::Segment #{@text.inspect} style=#{@style}>"
      else
        "#<Rich::Segment #{@text.inspect}>"
      end
    end

    def ==(other)
      return false unless other.is_a?(Segment)

      @text == other.text && @style == other.style && @control == other.control
    end

    alias eql? ==

    def hash
      [@text, @style, @control].hash
    end

    class << self
      # Create a newline segment
      # @return [Segment]
      def line
        @line ||= new("\n")
      end

      # Create a blank segment with specified cell width
      # @param cell_count [Integer] Width in cells
      # @param style [Style, nil] Optional style
      # @return [Segment]
      def blank(cell_count, style: nil)
        new(" " * cell_count, style: style)
      end

      # Create a control segment
      # @param control [Array] Control codes
      # @return [Segment]
      def control(control_codes)
        new("", control: control_codes)
      end

      # Apply style to an iterable of segments
      # @param segments [Enumerable<Segment>] Segments to style
      # @param style [Style, nil] Style to apply
      # @param post_style [Style, nil] Style to apply after segment style
      # @return [Enumerable<Segment>]
      def apply_style(segments, style: nil, post_style: nil)
        return segments if style.nil? && post_style.nil?

        segments.map do |segment|
          next segment if segment.control?

          new_style = if segment.style
                        if style && post_style
                          style + segment.style + post_style
                        elsif style
                          style + segment.style
                        else
                          segment.style + post_style
                        end
                      else
                        style || post_style
                      end

          new(segment.text, style: new_style, control: segment.control)
        end
      end

      # Filter segments by control status
      # @param segments [Enumerable<Segment>] Segments to filter
      # @param is_control [Boolean] Filter for control segments
      # @return [Enumerable<Segment>]
      def filter_control(segments, is_control: false)
        segments.select { |s| s.control? == is_control }
      end

      # Split segments into lines
      # @param segments [Enumerable<Segment>] Segments to split
      # @return [Array<Array<Segment>>] Array of lines
      def split_lines(segments)
        lines = []
        current_line = []

        segments.each do |segment|
          if segment.text.include?("\n")
            parts = segment.text.split("\n", -1)
            parts.each_with_index do |part, index|
              current_line << new(part, style: segment.style) unless part.empty?

              if index < parts.length - 1
                lines << current_line
                current_line = []
              end
            end
          else
            current_line << segment
          end
        end

        lines << current_line unless current_line.empty?
        lines
      end

      # Split and crop segments to a given width
      # @param segments [Enumerable<Segment>] Segments to process
      # @param width [Integer] Maximum width
      # @param style [Style, nil] Fill style
      # @param pad [Boolean] Pad lines to width
      # @param include_new_lines [Boolean] Include newline segments
      # @return [Array<Array<Segment>>]
      def split_and_crop_lines(segments, width, style: nil, pad: true, include_new_lines: true)
        lines = split_lines(segments)

        lines.map do |line|
          cropped = adjust_line_length(line, width, style: style, pad: pad)
          if include_new_lines
            cropped + [new("\n")]
          else
            cropped
          end
        end
      end

      # Adjust line length by cropping or padding
      # @param line [Array<Segment>] Line segments
      # @param length [Integer] Target length
      # @param style [Style, nil] Style for padding
      # @param pad [Boolean] Whether to pad short lines
      # @return [Array<Segment>]
      def adjust_line_length(line, length, style: nil, pad: true)
        current_length = get_line_length(line)

        if current_length < length
          # Pad if needed
          if pad
            pad_size = length - current_length
            line + [blank(pad_size, style: style)]
          else
            line
          end
        elsif current_length > length
          # Crop
          crop_line(line, length)
        else
          line
        end
      end

      # Get total cell length of a line
      # @param line [Array<Segment>] Line segments
      # @return [Integer]
      def get_line_length(line)
        line.sum(&:cell_length)
      end

      # Get dimensions of lines
      # @param lines [Array<Array<Segment>>] Lines
      # @return [Array<Integer>] [width, height]
      def get_shape(lines)
        height = lines.length
        width = lines.map { |line| get_line_length(line) }.max || 0
        [width, height]
      end

      # Crop a line to a maximum width
      # @param line [Array<Segment>] Line segments
      # @param max_width [Integer] Maximum width
      # @return [Array<Segment>]
      def crop_line(line, max_width)
        result = []
        remaining = max_width

        line.each do |segment|
          break if remaining <= 0

          segment_width = segment.cell_length

          if segment_width <= remaining
            result << segment
            remaining -= segment_width
          else
            # Need to split segment
            before, _after = segment.split_cells(remaining)
            result << before
            remaining = 0
          end
        end

        result
      end

      # Simplify consecutive segments with the same style
      # @param segments [Array<Segment>] Segments to simplify
      # @return [Array<Segment>]
      def simplify(segments)
        return segments if segments.empty?

        result = []
        current_text = +""
        current_style = nil
        current_control = nil

        segments.each do |segment|
          if segment.control?
            # Flush text if any
            unless current_text.empty?
              result << new(current_text, style: current_style, control: current_control)
              current_text = +""
            end
            result << segment
            current_style = nil
            current_control = nil
          elsif segment.style == current_style
            current_text << segment.text
          else
            unless current_text.empty?
              result << new(current_text, style: current_style, control: current_control)
            end
            current_text = +segment.text
            current_style = segment.style
            current_control = nil
          end
        end

        result << new(current_text, style: current_style) unless current_text.empty?

        result
      end

      # Render segments to string with ANSI codes
      # @param segments [Enumerable<Segment>] Segments to render
      # @param color_system [Symbol] Color system to use
      # @return [String]
      def render(segments, color_system: ColorSystem::TRUECOLOR)
        output = +""
        last_style = nil

        segments.each do |segment|
          if segment.control?
            # Handle control codes
            segment.control.each do |control_code|
              output << Control.generate(*control_code)
            end
          else
            style = segment.style

            if style != last_style
              # Reset if needed
              output << "\e[0m" if last_style
              # Apply new style
              output << style.render(color_system: color_system) if style
              last_style = style
            end

            output << segment.text
          end
        end

        # Reset at end if we had any style
        output << "\e[0m" if last_style

        output
      end

      # Split text at a cell position
      # @param text [String] Text to split
      # @param cut [Integer] Cell position
      # @param style [Style, nil] Style to apply
      # @return [Array<Segment>] Two segments
      def split_at_cell(text, cut, style)
        position = 0
        cell_count = 0
        insert_spaces = 0

        text.each_char do |char|
          char_width = Cells.char_width(char)
          new_cell_count = cell_count + char_width

          if new_cell_count > cut
            # Split happens in the middle of a wide character
            if char_width == 2 && cell_count + 1 == cut
              insert_spaces = 2
            end
            break
          end

          cell_count = new_cell_count
          position += 1
          break if cell_count == cut
        end

        if insert_spaces > 0
          [
            new(text[0...position] + " " * (cut - cell_count), style: style),
            new(" " * (insert_spaces - (cut - cell_count)) + text[position..], style: style)
          ]
        else
          [
            new(text[0...position], style: style),
            new(text[position..] || "", style: style)
          ]
        end
      end

      private

      # No private methods currently
    end
  end
end
