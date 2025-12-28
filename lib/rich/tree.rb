# frozen_string_literal: true

require_relative "style"
require_relative "segment"
require_relative "cells"
require_relative "markup"

module Rich
  # Tree guide characters for different styles
  module TreeGuide
    ASCII = {
      vertical: "|   ",
      branch: "+-- ",
      last: "`-- ",
      space: "    "
    }.freeze

    UNICODE = {
      vertical: "│   ",
      branch: "├── ",
      last: "└── ",
      space: "    "
    }.freeze

    ROUNDED = {
      vertical: "│   ",
      branch: "├── ",
      last: "╰── ",
      space: "    "
    }.freeze

    BOLD = {
      vertical: "┃   ",
      branch: "┣━━ ",
      last: "┗━━ ",
      space: "    "
    }.freeze

    DOUBLE = {
      vertical: "║   ",
      branch: "╠══ ",
      last: "╚══ ",
      space: "    "
    }.freeze
  end

  # A node in a tree structure
  class TreeNode
    # @return [String] Node label
    attr_reader :label

    # @return [Style, nil] Label style
    attr_reader :style

    # @return [Array<TreeNode>] Child nodes
    attr_reader :children

    # @return [Object, nil] Associated data
    attr_reader :data

    # @return [Boolean] Expanded state
    attr_accessor :expanded

    def initialize(label, style: nil, data: nil, expanded: true)
      @label = label.to_s
      @style = style.is_a?(String) ? Style.parse(style) : style
      @children = []
      @data = data
      @expanded = expanded
    end

    # Add a child node
    # @param label [String] Child label
    # @param kwargs [Hash] Node options
    # @return [TreeNode] The new child node
    def add(label, **kwargs)
      child = TreeNode.new(label, **kwargs)
      @children << child
      child
    end

    # @return [Boolean] True if node has children
    def leaf?
      @children.empty?
    end

    # @return [Integer] Number of children
    def child_count
      @children.length
    end

    # @return [Integer] Total descendant count
    def descendant_count
      @children.sum { |c| 1 + c.descendant_count }
    end

    # Iterate through all descendants
    # @yield [TreeNode, Integer] Each node and its depth
    def each_descendant(depth = 0, &block)
      yield(self, depth)
      @children.each do |child|
        child.each_descendant(depth + 1, &block)
      end
    end
  end

  # A tree display for hierarchical data
  class Tree
    # @return [TreeNode] Root node
    attr_reader :root

    # @return [Hash] Guide characters
    attr_reader :guide

    # @return [Style, nil] Guide style
    attr_reader :guide_style

    # @return [Boolean] Hide root node
    attr_reader :hide_root

    def initialize(
      label,
      style: nil,
      guide: TreeGuide::UNICODE,
      guide_style: nil,
      hide_root: false
    )
      @root = TreeNode.new(label, style: style)
      @guide = guide
      @guide_style = guide_style.is_a?(String) ? Style.parse(guide_style) : guide_style
      @hide_root = hide_root
    end

    # Add a child to root
    # @param label [String] Child label
    # @param kwargs [Hash] Node options
    # @return [TreeNode]
    def add(label, **kwargs)
      @root.add(label, **kwargs)
    end

    # Render tree to segments
    # @return [Array<Segment>]
    def to_segments
      segments = []

      unless @hide_root
        label_segments = parse_label(@root.label, @root.style)
        segments.concat(label_segments)
        segments << Segment.new("\n")
      end

      if @root.expanded
        render_children(@root.children, [], segments)
      end

      segments
    end

    # Parse a label with optional markup
    # @param label [String] Label text (may contain markup)
    # @param style [Style, nil] Base style
    # @return [Array<Segment>] Parsed segments
    def parse_label(label, style = nil)
      if label.include?("[") && label.include?("[/")
        # Contains markup - parse it
        text = Markup.parse(label)
        text.stylize_all(style) if style
        text.to_segments
      else
        [Segment.new(label, style: style)]
      end
    end

    # Render to string
    # @param color_system [Symbol] Color system
    # @return [String]
    def render(color_system: ColorSystem::TRUECOLOR)
      Segment.render(to_segments, color_system: color_system)
    end

    # Build tree from nested hash/array structure
    # @param data [Hash, Array] Nested data
    # @param label [String] Root label
    # @return [Tree]
    def self.from_data(data, label: "root", **kwargs)
      tree = new(label, **kwargs)
      add_data_to_node(tree.root, data)
      tree
    end

    private

    def render_children(children, prefix_parts, segments)
      children.each_with_index do |child, index|
        is_last = index == children.length - 1

        # Build prefix
        prefix = prefix_parts.join

        # Add guide character
        guide_char = is_last ? @guide[:last] : @guide[:branch]
        segments << Segment.new(prefix, style: @guide_style)
        segments << Segment.new(guide_char, style: @guide_style)
        label_segments = parse_label(child.label, child.style)
        segments.concat(label_segments)
        segments << Segment.new("\n")

        # Recurse for children
        if child.expanded && !child.children.empty?
          new_part = is_last ? @guide[:space] : @guide[:vertical]
          render_children(child.children, prefix_parts + [new_part], segments)
        end
      end
    end

    def self.add_data_to_node(node, data)
      case data
      when Hash
        data.each do |key, value|
          child = node.add(key.to_s)
          add_data_to_node(child, value)
        end
      when Array
        data.each_with_index do |item, index|
          if item.is_a?(Hash) || item.is_a?(Array)
            child = node.add("[#{index}]")
            add_data_to_node(child, item)
          else
            node.add(item.to_s)
          end
        end
      else
        node.add(data.to_s) unless data.nil?
      end
    end
  end
end
