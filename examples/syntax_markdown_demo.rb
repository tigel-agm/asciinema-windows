# frozen_string_literal: true

# Demo of Syntax Highlighting and Markdown Rendering

require_relative "../lib/rich"

console = Rich::Console.new

console.rule("Syntax Highlighting Demo", style: "bold cyan")
puts ""

# Ruby code
ruby_code = <<~RUBY
  # Ruby example
  class User
    attr_accessor :name, :email

    def initialize(name, email)
      @name = name
      @email = email
    end

    def greet
      puts "Hello, \#{@name}!"
    end
  end

  user = User.new("Alice", "alice@example.com")
  user.greet
RUBY

puts "Ruby:"
puts ""
syntax = Rich::Syntax.new(ruby_code, language: "ruby", line_numbers: true)
puts syntax.render
puts ""

# Python code
python_code = <<~PYTHON
  # Python example
  import json
  from dataclasses import dataclass

  @dataclass
  class Config:
      name: str
      debug: bool = False

  def load_config(path: str) -> Config:
      with open(path) as f:
          data = json.load(f)
      return Config(**data)

  if __name__ == "__main__":
      config = load_config("config.json")
      print(f"Loaded: {config.name}")
PYTHON

puts "Python:"
puts ""
syntax = Rich::Syntax.new(python_code, language: "python", line_numbers: true, theme: :monokai)
puts syntax.render
puts ""

# JavaScript
js_code = <<~JS
  // JavaScript example
  const express = require('express');
  const app = express();

  app.get('/api/users', async (req, res) => {
    const users = await User.findAll();
    res.json({ data: users, count: users.length });
  });

  app.listen(3000, () => console.log('Server running'));
JS

puts "JavaScript (Dracula theme):"
puts ""
syntax = Rich::Syntax.new(js_code, language: "javascript", line_numbers: true, theme: :dracula)
puts syntax.render
puts ""

# SQL
sql_code = <<~SQL
  -- Get active users with their orders
  SELECT u.name, u.email, COUNT(o.id) AS order_count
  FROM users u
  LEFT JOIN orders o ON u.id = o.user_id
  WHERE u.status = 'active'
    AND o.created_at >= '2025-01-01'
  GROUP BY u.id
  HAVING order_count > 5
  ORDER BY order_count DESC
  LIMIT 10;
SQL

puts "SQL:"
puts ""
syntax = Rich::Syntax.new(sql_code, language: "sql")
puts syntax.render
puts ""

console.rule("Markdown Rendering Demo", style: "bold cyan")
puts ""

markdown = <<~MD
  # Welcome to Rich Markdown

  This is a **full-featured** Markdown renderer for your *terminal*.

  ## Features

  ### Text Formatting

  You can use **bold**, *italic*, ***bold italic***, ~~strikethrough~~, and `inline code`.

  ### Lists

  Unordered list:
  - First item
  - Second item
    - Nested item
    - Another nested

  Ordered list:
  1. Step one
  2. Step two
  3. Step three

  ### Blockquotes

  > This is a blockquote.
  > It can span multiple lines.
  > -- Someone Famous

  ### Code Blocks

  ```ruby
  def hello(name)
    puts "Hello, \#{name}!"
  end
  ```

  ### Tables

  | Name     | Language | Stars |
  |----------|----------|-------|
  | Ruby     | Ruby     | 21k   |
  | Python   | Python   | 58k   |
  | Node.js  | JS       | 102k  |

  ### Links

  Check out [Rich Library](https://github.com/Textualize/rich) for more!

  ---

  That's all folks!
MD

md = Rich::Markdown.new(markdown)
puts md.render(max_width: 70)

console.rule("Demo Complete!", style: "bold green")
