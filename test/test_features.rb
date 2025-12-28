# frozen_string_literal: true

require_relative "test_helper"

class TestProgress < Minitest::Test
  def test_progress_bar_creation
    bar = Rich::ProgressBar.new(total: 100)
    refute_nil bar
    assert_equal 0, bar.completed
    assert_equal 100, bar.total
  end

  def test_progress_bar_update
    bar = Rich::ProgressBar.new(total: 100)
    bar.update(50)
    assert_equal 50, bar.completed
    assert_equal 50, bar.percentage
  end

  def test_progress_bar_advance
    bar = Rich::ProgressBar.new(total: 100)
    bar.advance(10)
    assert_equal 10, bar.completed
    bar.advance(5)
    assert_equal 15, bar.completed
  end

  def test_progress_bar_percentage
    bar = Rich::ProgressBar.new(total: 200, completed: 50)
    assert_equal 25, bar.percentage
  end

  def test_progress_bar_render
    bar = Rich::ProgressBar.new(total: 100, completed: 50)
    output = bar.render
    refute output.empty?
    assert_includes output, "50%"
  end

  def test_progress_bar_complete
    bar = Rich::ProgressBar.new(total: 100)
    bar.update(100)
    assert bar.finished?
  end

  def test_progress_bar_styles
    bar = Rich::ProgressBar.new(
      total: 100,
      complete_style: "green",
      incomplete_style: "red"
    )
    bar.update(50)
    output = bar.render
    refute output.empty?
  end
end

class TestSpinner < Minitest::Test
  def test_spinner_creation
    spinner = Rich::Spinner.new
    refute_nil spinner
  end

  def test_spinner_with_frames
    frames = %w[a b c d]
    spinner = Rich::Spinner.new(frames: frames)
    assert_equal "a", spinner.frame
  end

  def test_spinner_advance
    spinner = Rich::Spinner.new(frames: %w[1 2 3])
    assert_equal "1", spinner.frame
    spinner.advance
    assert_equal "2", spinner.frame
    spinner.advance
    assert_equal "3", spinner.frame
    spinner.advance
    assert_equal "1", spinner.frame  # Wraps around
  end

  def test_spinner_styles
    styles = [
      Rich::ProgressStyle::DOTS,
      Rich::ProgressStyle::LINE,
      Rich::ProgressStyle::CIRCLE,
      Rich::ProgressStyle::BOUNCE
    ]
    styles.each do |frames|
      spinner = Rich::Spinner.new(frames: frames)
      refute spinner.frame.empty?
    end
  end
end

class TestJSON < Minitest::Test
  include TestHelper

  def test_to_s_hash
    data = { "name" => "Alice", "age" => 30 }
    output = Rich::JSON.to_s(data)
    refute output.empty?
    assert_includes output, "name"
    assert_includes output, "Alice"
  end

  def test_to_s_array
    data = [1, 2, 3]
    output = Rich::JSON.to_s(data)
    refute output.empty?
  end

  def test_to_s_nested
    data = { "user" => { "name" => "Alice" } }
    output = Rich::JSON.to_s(data)
    refute output.empty?
  end

  def test_highlight
    json_str = '{"name": "Alice"}'
    output = Rich::JSON.highlight(json_str)
    refute output.empty?
    assert_has_ansi(Rich::Segment.render(output))
  end

  def test_pretty_to_s
    data = { string: "hello", number: 42, bool: true, nil_val: nil }
    output = Rich::Pretty.to_s(data)
    refute output.empty?
  end
end

class TestSyntax < Minitest::Test
  include TestHelper

  def test_creation
    syntax = Rich::Syntax.new("def hello; end", language: "ruby")
    refute_nil syntax
    assert_equal "ruby", syntax.language
  end

  def test_render_ruby
    code = "def hello\n  puts 'Hello'\nend"
    syntax = Rich::Syntax.new(code, language: "ruby")
    output = syntax.render
    refute output.empty?
    assert_has_ansi(output)
  end

  def test_render_python
    code = "def hello():\n    print('Hello')"
    syntax = Rich::Syntax.new(code, language: "python")
    output = syntax.render
    refute output.empty?
  end

  def test_render_javascript
    code = "const x = 1;"
    syntax = Rich::Syntax.new(code, language: "javascript")
    output = syntax.render
    refute output.empty?
  end

  def test_render_sql
    code = "SELECT * FROM users WHERE active = true"
    syntax = Rich::Syntax.new(code, language: "sql")
    output = syntax.render
    refute output.empty?
  end

  def test_line_numbers
    code = "line1\nline2\nline3"
    syntax = Rich::Syntax.new(code, language: "text", line_numbers: true)
    output = syntax.render
    assert_includes output, "1"
    assert_includes output, "2"
  end

  def test_themes
    code = "puts 'hello'"
    [:default, :monokai, :dracula].each do |theme|
      syntax = Rich::Syntax.new(code, language: "ruby", theme: theme)
      output = syntax.render
      refute output.empty?
    end
  end

  def test_supported_languages
    languages = Rich::Syntax.supported_languages
    assert languages.include?("ruby")
    assert languages.include?("python")
    assert languages.include?("javascript")
  end

  def test_detect_language
    assert_equal "ruby", Rich::Syntax.detect_language("test.rb")
    assert_equal "python", Rich::Syntax.detect_language("test.py")
    assert_equal "javascript", Rich::Syntax.detect_language("test.js")
  end
end

class TestMarkdown < Minitest::Test
  include TestHelper

  def test_creation
    md = Rich::Markdown.new("# Hello")
    refute_nil md
  end

  def test_render_heading
    md = Rich::Markdown.new("# Title")
    output = md.render(max_width: 40)
    assert_includes strip_ansi(output), "Title"
  end

  def test_render_paragraph
    md = Rich::Markdown.new("This is a paragraph.")
    output = md.render(max_width: 40)
    assert_includes strip_ansi(output), "This is a paragraph"
  end

  def test_render_bold
    md = Rich::Markdown.new("**bold text**")
    output = md.render(max_width: 40)
    assert_includes strip_ansi(output), "bold text"
  end

  def test_render_italic
    md = Rich::Markdown.new("*italic text*")
    output = md.render(max_width: 40)
    assert_includes strip_ansi(output), "italic text"
  end

  def test_render_list
    md = Rich::Markdown.new("- Item 1\n- Item 2")
    output = md.render(max_width: 40)
    assert_includes strip_ansi(output), "Item 1"
    assert_includes strip_ansi(output), "Item 2"
  end

  def test_render_ordered_list
    md = Rich::Markdown.new("1. First\n2. Second")
    output = md.render(max_width: 40)
    assert_includes strip_ansi(output), "First"
    assert_includes strip_ansi(output), "Second"
  end

  def test_render_blockquote
    md = Rich::Markdown.new("> Quote")
    output = md.render(max_width: 40)
    assert_includes strip_ansi(output), "Quote"
  end

  def test_render_code_block
    md = Rich::Markdown.new("```ruby\nputs 'hello'\n```")
    output = md.render(max_width: 60)
    assert_includes strip_ansi(output), "puts"
  end

  def test_render_table
    table_md = "| A | B |\n|---|---|\n| 1 | 2 |"
    md = Rich::Markdown.new(table_md)
    output = md.render(max_width: 40)
    refute output.empty?
  end

  def test_render_link
    md = Rich::Markdown.new("[Click](https://example.com)")
    output = md.render(max_width: 60)
    assert_includes strip_ansi(output), "Click"
  end

  def test_render_inline_code
    md = Rich::Markdown.new("Use `code` here")
    output = md.render(max_width: 40)
    assert_includes strip_ansi(output), "code"
  end
end
