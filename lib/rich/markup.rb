# frozen_string_literal: true

require_relative "style"
require_relative "text"

module Rich
  # Markup parsing error
  class MarkupError < StandardError
  end

  # Parser for Rich markup syntax: [style]text[/style]
  module Markup
    # Tag regex for matching markup tags, excluding escaped ones
    TAG_REGEX = /(?<!\\)\[(?<closing>\/)?(?<tag>[^\[\]\/]*)\]/

    class << self
      # Parse markup into a Text object
      # @param markup [String] Markup text
      # @param style [Style, String, nil] Base style
      # @return [Text]
      def parse(markup, style: nil)
        result_text = Text.new(style: style)
        style_stack = []
        pos = 0

        markup.scan(TAG_REGEX) do
          match = Regexp.last_match
          tag_start = match.begin(0)

          # Add text before tag
          if tag_start > pos
            pre_text = unescape(markup[pos...tag_start])
            start_pos = result_text.length
            result_text.append(pre_text)

            # Apply stacked styles to this text
            style_stack.each do |stacked_style|
              result_text.spans << Span.new(start_pos, result_text.length, stacked_style)
            end
          end

          # Process tag
          if match[:closing]
            # Closing tag - pop style
            style_stack.pop unless style_stack.empty?
          else
            # Opening tag - parse and push style
            tag_content = match[:tag].strip
            if tag_content.empty?
              # Literal []
              result_text.append("[]")
            else
              begin
                parsed_style = Style.parse(tag_content)
                style_stack << parsed_style
              rescue StandardError
                # Invalid style, treat as literal text
                result_text.append("[#{tag_content}]")
              end
            end
          end

          pos = match.end(0)
        end

        # Add remaining text
        if pos < markup.length
          remaining = unescape(markup[pos..])
          start_pos = result_text.length
          result_text.append(remaining)

          style_stack.each do |stacked_style|
            result_text.spans << Span.new(start_pos, result_text.length, stacked_style)
          end
        end

        result_text
      end

      # Render markup directly to ANSI string
      # @param markup [String] Markup text
      # @param color_system [Symbol] Color system
      # @return [String]
      def render(markup, color_system: ColorSystem::TRUECOLOR)
        parse(markup).render(color_system: color_system)
      end

      # Escape text for use in markup (escape square brackets)
      # @param text [String] Text to escape
      # @return [String]
      def escape(text)
        text.gsub(/[\[\]]/) { |m| "\\#{m}" }
      end

      # Unescape markup text
      # @param text [String] Text to unescape
      # @return [String]
      def unescape(text)
        text.gsub(/\\([\[\]\\])/, '\1')
      end

      # Strip markup tags from text
      # @param markup [String] Markup text
      # @return [String]
      def strip(markup)
        markup.gsub(TAG_REGEX, "")
      end

      # Check if text contains markup
      # @param text [String] Text to check
      # @return [Boolean]
      def contains_markup?(text)
        text.match?(TAG_REGEX)
      end

      # Extract all tags from markup
      # @param markup [String] Markup text
      # @return [Array<Hash>] Array of tag info
      def extract_tags(markup)
        tags = []

        markup.scan(TAG_REGEX) do
          match = Regexp.last_match
          tags << {
            position: match.begin(0),
            closing: !match[:closing].nil?,
            tag: match[:tag].to_s.strip,
            full_match: match[0]
          }
        end

        tags
      end

      # Validate markup (check for unclosed tags)
      # @param markup [String] Markup to validate
      # @return [Array<String>] List of errors (empty if valid)
      def validate(markup)
        errors = []
        open_tags = []

        extract_tags(markup).each do |tag|
          if tag[:closing]
            if open_tags.empty?
              errors << "Unexpected closing tag [/#{tag[:tag]}] at position #{tag[:position]}"
            else
              # In Rich, [/] closes the LAST tag, [ /tag] closes specific tag
              # Let's keep it simple for now: pop last.
              # If tag name matches, pop it. If it doesn't match and not empty, it's an error.
              last_tag = open_tags.pop
              if !tag[:tag].empty? && tag[:tag] != last_tag
                errors << "Mismatched closing tag [/#{tag[:tag]}] for [#{last_tag}]"
              end
            end
          else
            open_tags << tag[:tag]
          end
        end

        open_tags.each do |tag|
          errors << "Unclosed tag [#{tag}]"
        end

        errors
      end

      # Check if markup is valid
      # @param markup [String] Markup to check
      # @return [Boolean]
      def valid?(markup)
        validate(markup).empty?
      end
    end
  end
end
