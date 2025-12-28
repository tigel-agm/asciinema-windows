# frozen_string_literal: true

require_relative "test_helper"

class TestPanel < Minitest::Test
  include TestHelper

  def test_creation
    panel = Rich::Panel.new("Content")
    refute_nil panel
  end

  def test_render
    panel = Rich::Panel.new("Hello World")
    output = panel.render(max_width: 30)
    assert output.is_a?(String)
    refute output.empty?
  end

  def test_with_title
    panel = Rich::Panel.new("Content", title: "My Title")
    output = panel.render(max_width: 40)
    assert_includes strip_ansi(output), "My Title"
  end

  def test_with_subtitle
    panel = Rich::Panel.new("Content", subtitle: "Footer")
    output = panel.render(max_width: 40)
    assert_includes strip_ansi(output), "Footer"
  end

  def test_with_border_style
    panel = Rich::Panel.new("Content", border_style: "red")
    output = panel.render(max_width: 30)
    assert_has_ansi(output)
  end

  def test_different_box_styles
    boxes = [Rich::Box::ASCII, Rich::Box::ROUNDED, Rich::Box::HEAVY, Rich::Box::DOUBLE]
    boxes.each do |box|
      panel = Rich::Panel.new("Content", box: box)
      output = panel.render(max_width: 30)
      refute output.empty?
    end
  end

  def test_multiline_content
    panel = Rich::Panel.new("Line 1\nLine 2\nLine 3")
    output = panel.render(max_width: 30)
    lines = output.lines
    assert lines.length >= 5  # Top border, 3 content lines, bottom border
  end

  def test_with_padding
    panel = Rich::Panel.new("Content", padding: 2)
    output = panel.render(max_width: 40)
    refute output.empty?
  end

  def test_fit_mode
    panel = Rich::Panel.new("Short", title: "Title", expand: false)
    output = panel.render(max_width: 80)
    refute output.empty?
  end
end

class TestTable < Minitest::Test
  include TestHelper

  def test_creation
    table = Rich::Table.new
    refute_nil table
  end

  def test_add_column
    table = Rich::Table.new
    table.add_column("Name")
    assert_equal 1, table.columns.length
  end

  def test_add_row
    table = Rich::Table.new
    table.add_column("Name")
    table.add_column("Age")
    table.add_row("Alice", "30")
    assert_equal 1, table.rows.length
  end

  def test_render
    table = Rich::Table.new(title: "Users")
    table.add_column("Name")
    table.add_column("Age")
    table.add_row("Alice", "30")
    table.add_row("Bob", "25")
    output = table.render(max_width: 40)
    refute output.empty?
    assert_includes strip_ansi(output), "Alice"
    assert_includes strip_ansi(output), "Bob"
  end

  def test_with_header_style
    table = Rich::Table.new
    table.add_column("Name", header_style: "bold cyan")
    table.add_row("Test")
    output = table.render(max_width: 30)
    assert_has_ansi(output)
  end

  def test_column_justification
    table = Rich::Table.new
    table.add_column("Left", justify: :left)
    table.add_column("Center", justify: :center)
    table.add_column("Right", justify: :right)
    table.add_row("A", "B", "C")
    output = table.render(max_width: 50)
    refute output.empty?
  end

  def test_different_box_styles
    table = Rich::Table.new(box: Rich::Box::DOUBLE)
    table.add_column("Col")
    table.add_row("Data")
    output = table.render(max_width: 30)
    refute output.empty?
  end

  def test_many_rows
    table = Rich::Table.new
    table.add_column("ID")
    table.add_column("Name")
    10.times { |i| table.add_row(i.to_s, "Name#{i}") }
    output = table.render(max_width: 40)
    refute output.empty?
  end
end

class TestTree < Minitest::Test
  include TestHelper

  def test_creation
    tree = Rich::Tree.new("Root")
    refute_nil tree
    refute_nil tree.root
  end

  def test_add_child
    tree = Rich::Tree.new("Root")
    child = tree.add("Child")
    refute_nil child
    assert_equal 1, tree.root.children.length
  end

  def test_nested_children
    tree = Rich::Tree.new("Root")
    child = tree.add("Child")
    grandchild = child.add("Grandchild")
    refute_nil grandchild
  end

  def test_render
    tree = Rich::Tree.new("Root")
    tree.add("Child 1")
    tree.add("Child 2")
    output = tree.render
    refute output.empty?
    assert_includes strip_ansi(output), "Root"
    assert_includes strip_ansi(output), "Child 1"
  end

  def test_different_guides
    guides = [
      Rich::TreeGuide::UNICODE,
      Rich::TreeGuide::ASCII,
      Rich::TreeGuide::ROUNDED,
      Rich::TreeGuide::BOLD
    ]
    guides.each do |guide|
      tree = Rich::Tree.new("Root", guide: guide)
      tree.add("Child")
      output = tree.render
      refute output.empty?
    end
  end

  def test_deep_nesting
    tree = Rich::Tree.new("Level 0")
    node = tree.root
    5.times { |i| node = node.add("Level #{i + 1}") }
    output = tree.render
    assert_includes output, "Level 5"
  end

  def test_with_style
    tree = Rich::Tree.new("Root", style: "bold yellow")
    tree.add("Child", style: "green")
    output = tree.render
    assert_has_ansi(output)
  end
end
