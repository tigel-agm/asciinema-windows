# frozen_string_literal: true

require_relative "style"
require_relative "segment"
require_relative "text"
require_relative "panel"

module Rich
  # Syntax highlighting for source code.
  # Provides token-based syntax highlighting for multiple programming languages.
  class Syntax
    # Default theme for syntax highlighting
    DEFAULT_THEME = {
      # Keywords
      keyword: Style.new(color: Color.parse("magenta"), bold: true),
      keyword_constant: Style.new(color: Color.parse("cyan"), bold: true),
      keyword_declaration: Style.new(color: Color.parse("magenta"), bold: true),
      keyword_namespace: Style.new(color: Color.parse("magenta"), bold: true),
      keyword_type: Style.new(color: Color.parse("cyan")),

      # Names
      name: Style.new(color: Color.parse("white")),
      name_builtin: Style.new(color: Color.parse("cyan")),
      name_class: Style.new(color: Color.parse("green"), bold: true),
      name_constant: Style.new(color: Color.parse("cyan")),
      name_decorator: Style.new(color: Color.parse("bright_magenta")),
      name_exception: Style.new(color: Color.parse("green"), bold: true),
      name_function: Style.new(color: Color.parse("green")),
      name_variable: Style.new(color: Color.parse("white")),
      name_tag: Style.new(color: Color.parse("bright_magenta")),
      name_attribute: Style.new(color: Color.parse("yellow")),

      # Literals
      string: Style.new(color: Color.parse("yellow")),
      string_doc: Style.new(color: Color.parse("yellow"), italic: true),
      string_escape: Style.new(color: Color.parse("bright_magenta")),
      string_interpol: Style.new(color: Color.parse("bright_magenta")),
      string_regex: Style.new(color: Color.parse("bright_yellow")),
      string_symbol: Style.new(color: Color.parse("bright_green")),

      number: Style.new(color: Color.parse("cyan")),
      number_float: Style.new(color: Color.parse("cyan")),
      number_hex: Style.new(color: Color.parse("cyan")),

      # Operators and Punctuation
      operator: Style.new(color: Color.parse("bright_magenta")),
      punctuation: Style.new(color: Color.parse("white")),

      # Comments
      comment: Style.new(color: Color.parse("bright_black"), italic: true),
      comment_doc: Style.new(color: Color.parse("bright_black"), italic: true),
      comment_preproc: Style.new(color: Color.parse("bright_magenta")),

      # Generic
      generic_deleted: Style.new(color: Color.parse("red")),
      generic_inserted: Style.new(color: Color.parse("green")),
      generic_heading: Style.new(color: Color.parse("bright_blue"), bold: true),
      generic_subheading: Style.new(color: Color.parse("bright_blue")),
      generic_error: Style.new(color: Color.parse("bright_red")),

      # Other
      text: Style.new,
      error: Style.new(color: Color.parse("bright_red"), bold: true)
    }.freeze

    # Monokai theme
    MONOKAI_THEME = {
      keyword: Style.new(color: Color.parse("#f92672"), bold: true),
      keyword_constant: Style.new(color: Color.parse("#ae81ff")),
      keyword_type: Style.new(color: Color.parse("#66d9ef"), italic: true),
      name: Style.new(color: Color.parse("#f8f8f2")),
      name_builtin: Style.new(color: Color.parse("#66d9ef")),
      name_class: Style.new(color: Color.parse("#a6e22e")),
      name_function: Style.new(color: Color.parse("#a6e22e")),
      name_decorator: Style.new(color: Color.parse("#a6e22e")),
      string: Style.new(color: Color.parse("#e6db74")),
      string_doc: Style.new(color: Color.parse("#e6db74")),
      number: Style.new(color: Color.parse("#ae81ff")),
      operator: Style.new(color: Color.parse("#f92672")),
      comment: Style.new(color: Color.parse("#75715e"), italic: true),
      punctuation: Style.new(color: Color.parse("#f8f8f2")),
      text: Style.new(color: Color.parse("#f8f8f2")),
      error: Style.new(color: Color.parse("#f92672"), bold: true)
    }.freeze

    # Dracula theme
    DRACULA_THEME = {
      keyword: Style.new(color: Color.parse("#ff79c6"), bold: true),
      keyword_constant: Style.new(color: Color.parse("#bd93f9")),
      keyword_type: Style.new(color: Color.parse("#8be9fd"), italic: true),
      name: Style.new(color: Color.parse("#f8f8f2")),
      name_builtin: Style.new(color: Color.parse("#8be9fd")),
      name_class: Style.new(color: Color.parse("#50fa7b")),
      name_function: Style.new(color: Color.parse("#50fa7b")),
      name_decorator: Style.new(color: Color.parse("#50fa7b")),
      string: Style.new(color: Color.parse("#f1fa8c")),
      string_doc: Style.new(color: Color.parse("#6272a4")),
      number: Style.new(color: Color.parse("#bd93f9")),
      operator: Style.new(color: Color.parse("#ff79c6")),
      comment: Style.new(color: Color.parse("#6272a4"), italic: true),
      punctuation: Style.new(color: Color.parse("#f8f8f2")),
      text: Style.new(color: Color.parse("#f8f8f2")),
      error: Style.new(color: Color.parse("#ff5555"), bold: true)
    }.freeze

    THEMES = {
      default: DEFAULT_THEME,
      monokai: MONOKAI_THEME,
      dracula: DRACULA_THEME
    }.freeze

    # @return [String] Source code
    attr_reader :code

    # @return [String] Language name
    attr_reader :language

    # @return [Hash] Theme styles
    attr_reader :theme

    # @return [Boolean] Show line numbers
    attr_reader :line_numbers

    # @return [Integer, nil] Starting line number
    attr_reader :start_line

    # @return [Array<Integer>, nil] Lines to highlight
    attr_reader :highlight_lines

    # @return [Boolean] Word wrap
    attr_reader :word_wrap

    # @return [Style, nil] Background style
    attr_reader :background_style

    # @return [Integer] Tab size
    attr_reader :tab_size

    def initialize(
      code,
      language: "text",
      theme: :default,
      line_numbers: false,
      start_line: 1,
      highlight_lines: nil,
      word_wrap: false,
      background_style: nil,
      tab_size: 4
    )
      @code = code.to_s
      @language = language.to_s.downcase
      @theme = theme.is_a?(Hash) ? theme : (THEMES[theme] || DEFAULT_THEME)
      @line_numbers = line_numbers
      @start_line = start_line
      @highlight_lines = highlight_lines
      @word_wrap = word_wrap
      @background_style = background_style
      @tab_size = tab_size
    end

    # Highlight the code and return segments
    # @return [Array<Segment>]
    def to_segments
      segments = []
      lines = @code.gsub("\t", " " * @tab_size).split("\n", -1)

      # Calculate line number width
      line_num_width = (@start_line + lines.length - 1).to_s.length

      lines.each_with_index do |line, index|
        line_num = @start_line + index
        is_highlighted = @highlight_lines&.include?(line_num)

        # Line number
        if @line_numbers
          num_style = is_highlighted ? Style.new(color: Color.parse("yellow"), bold: true) : Style.new(color: Color.parse("bright_black"))
          segments << Segment.new(line_num.to_s.rjust(line_num_width), style: num_style)
          segments << Segment.new(" │ ", style: Style.new(color: Color.parse("bright_black")))
        end

        # Highlighted line background
        if is_highlighted
          bg_style = Style.new(bgcolor: Color.parse("color(237)"))
          segments.concat(highlight_line(line).map do |seg|
            combined_style = seg.style ? seg.style + bg_style : bg_style
            Segment.new(seg.text, style: combined_style)
          end)
        else
          segments.concat(highlight_line(line))
        end

        segments << Segment.new("\n") if index < lines.length - 1
      end

      segments
    end

    # Highlight a single line
    # @param line [String] Line to highlight
    # @return [Array<Segment>]
    def highlight_line(line)
      lexer = get_lexer(@language)
      lexer.tokenize(line, @theme)
    end

    # Render to string with ANSI codes
    # @param color_system [Symbol] Color system
    # @return [String]
    def render(color_system: ColorSystem::TRUECOLOR)
      Segment.render(to_segments, color_system: color_system)
    end

    # Render inside a panel
    # @param title [String, nil] Panel title
    # @return [String]
    def to_panel(title: nil, max_width: 80)
      title ||= @language.capitalize
      panel = Panel.new(
        render,
        title: title,
        border_style: "dim",
        padding: 0
      )
      panel.render(max_width: max_width)
    end

    class << self
      # Create syntax from file
      # @param path [String] File path
      # @param kwargs [Hash] Options
      # @return [Syntax]
      def from_file(path, **kwargs)
        code = File.read(path)
        language = kwargs.delete(:language) || detect_language(path)
        new(code, language: language, **kwargs)
      end

      # Detect language from file extension
      # @param path [String] File path
      # @return [String]
      def detect_language(path)
        ext = File.extname(path).downcase.delete(".")
        EXTENSION_MAP[ext] || "text"
      end

      # List supported languages
      # @return [Array<String>]
      def supported_languages
        LEXERS.keys.sort
      end
    end

    private

    def get_lexer(language)
      LEXERS[language] || LEXERS["text"]
    end

    # File extension to language mapping
    EXTENSION_MAP = {
      "rb" => "ruby",
      "py" => "python",
      "js" => "javascript",
      "ts" => "typescript",
      "jsx" => "javascript",
      "tsx" => "typescript",
      "json" => "json",
      "yml" => "yaml",
      "yaml" => "yaml",
      "xml" => "xml",
      "html" => "html",
      "htm" => "html",
      "css" => "css",
      "scss" => "scss",
      "sass" => "sass",
      "sql" => "sql",
      "sh" => "bash",
      "bash" => "bash",
      "zsh" => "bash",
      "ps1" => "powershell",
      "c" => "c",
      "h" => "c",
      "cpp" => "cpp",
      "hpp" => "cpp",
      "cc" => "cpp",
      "go" => "go",
      "rs" => "rust",
      "java" => "java",
      "kt" => "kotlin",
      "swift" => "swift",
      "md" => "markdown",
      "markdown" => "markdown",
      "dockerfile" => "dockerfile",
      "toml" => "toml",
      "ini" => "ini",
      "conf" => "ini",
      "txt" => "text"
    }.freeze
  end

  # Base lexer class for tokenization
  class BaseLexer
    def tokenize(line, theme)
      [Segment.new(line, style: theme[:text])]
    end
  end

  # Ruby lexer
  class RubyLexer < BaseLexer
    KEYWORDS = %w[
      def class module end if else elsif unless case when then
      begin rescue ensure raise return yield do while until for
      break next redo retry in and or not alias defined? super
      self nil true false __FILE__ __LINE__ __ENCODING__
      require require_relative include extend prepend attr_reader
      attr_writer attr_accessor private protected public
      lambda proc loop catch throw
    ].freeze

    BUILTINS = %w[
      puts print p pp gets chomp to_s to_i to_f to_a to_h length
      size each map select reject find reduce inject sort sort_by
      uniq compact flatten reverse join split push pop shift unshift
      first last min max sum count empty? nil? is_a? kind_of?
      respond_to? send __send__ method methods instance_variables
      class superclass ancestors included_modules freeze frozen?
      dup clone tap then yield_self itself inspect
    ].freeze

    def tokenize(line, theme)
      segments = []
      pos = 0

      while pos < line.length
        # Skip whitespace
        if line[pos].match?(/\s/)
          ws_end = pos
          ws_end += 1 while ws_end < line.length && line[ws_end].match?(/\s/)
          segments << Segment.new(line[pos...ws_end])
          pos = ws_end
          next
        end

        # Comment
        if line[pos] == "#"
          segments << Segment.new(line[pos..], style: theme[:comment])
          break
        end

        # String (double quote)
        if line[pos] == '"'
          str_end = find_string_end(line, pos, '"')
          segments << Segment.new(line[pos..str_end], style: theme[:string])
          pos = str_end + 1
          next
        end

        # String (single quote)
        if line[pos] == "'"
          str_end = find_string_end(line, pos, "'")
          segments << Segment.new(line[pos..str_end], style: theme[:string])
          pos = str_end + 1
          next
        end

        # Regex
        if line[pos] == "/" && (pos == 0 || line[pos - 1].match?(/[\s=({,]/))
          regex_end = find_string_end(line, pos, "/")
          if regex_end > pos
            segments << Segment.new(line[pos..regex_end], style: theme[:string_regex])
            pos = regex_end + 1
            next
          end
        end

        # Symbol
        if line[pos] == ":"
          if pos + 1 < line.length && line[pos + 1].match?(/[a-zA-Z_]/)
            sym_end = pos + 1
            sym_end += 1 while sym_end < line.length && line[sym_end].match?(/\w/)
            segments << Segment.new(line[pos...sym_end], style: theme[:string_symbol] || theme[:string])
            pos = sym_end
            next
          end
        end

        # Number
        if line[pos].match?(/\d/)
          num_end = pos
          num_end += 1 while num_end < line.length && line[num_end].match?(/[\d._xXoObB]/)
          segments << Segment.new(line[pos...num_end], style: theme[:number])
          pos = num_end
          next
        end

        # Instance variable
        if line[pos] == "@"
          var_end = pos + 1
          var_end += 1 if var_end < line.length && line[var_end] == "@"
          var_end += 1 while var_end < line.length && line[var_end].match?(/\w/)
          segments << Segment.new(line[pos...var_end], style: theme[:name_variable] || theme[:name])
          pos = var_end
          next
        end

        # Global variable
        if line[pos] == "$"
          var_end = pos + 1
          var_end += 1 while var_end < line.length && line[var_end].match?(/\w/)
          segments << Segment.new(line[pos...var_end], style: theme[:name_variable] || theme[:name])
          pos = var_end
          next
        end

        # Constant/Class name
        if line[pos].match?(/[A-Z]/)
          word_end = pos
          word_end += 1 while word_end < line.length && line[word_end].match?(/\w/)
          word = line[pos...word_end]
          if %w[true false nil].include?(word.downcase)
            segments << Segment.new(word, style: theme[:keyword_constant] || theme[:keyword])
          else
            segments << Segment.new(word, style: theme[:name_class] || theme[:name])
          end
          pos = word_end
          next
        end

        # Identifier/Keyword
        if line[pos].match?(/[a-z_]/i)
          word_end = pos
          word_end += 1 while word_end < line.length && line[word_end].match?(/[\w?!]/)
          word = line[pos...word_end]

          style = if KEYWORDS.include?(word)
                    theme[:keyword]
                  elsif BUILTINS.include?(word)
                    theme[:name_builtin] || theme[:name]
                  else
                    theme[:name]
                  end

          segments << Segment.new(word, style: style)
          pos = word_end
          next
        end

        # Operators and punctuation
        if line[pos].match?(/[+\-*\/%&|^~<>=!?:]/)
          op_end = pos + 1
          op_end += 1 while op_end < line.length && line[op_end].match?(/[+\-*\/%&|^~<>=!?:]/)
          segments << Segment.new(line[pos...op_end], style: theme[:operator])
          pos = op_end
          next
        end

        # Punctuation
        if line[pos].match?(/[(){}\[\].,;]/)
          segments << Segment.new(line[pos], style: theme[:punctuation])
          pos += 1
          next
        end

        # Default
        segments << Segment.new(line[pos])
        pos += 1
      end

      segments
    end

    private

    def find_string_end(line, start, delimiter)
      pos = start + 1
      while pos < line.length
        return pos if line[pos] == delimiter && line[pos - 1] != "\\"

        pos += 1
      end
      line.length - 1
    end
  end

  # Python lexer
  class PythonLexer < BaseLexer
    KEYWORDS = %w[
      and as assert async await break class continue def del elif else
      except finally for from global if import in is lambda None nonlocal
      not or pass raise return try while with yield True False
    ].freeze

    BUILTINS = %w[
      abs all any ascii bin bool breakpoint bytearray bytes callable
      chr classmethod compile complex delattr dict dir divmod enumerate
      eval exec filter float format frozenset getattr globals hasattr
      hash help hex id input int isinstance issubclass iter len list
      locals map max memoryview min next object oct open ord pow print
      property range repr reversed round set setattr slice sorted
      staticmethod str sum super tuple type vars zip
    ].freeze

    def tokenize(line, theme)
      segments = []
      pos = 0

      while pos < line.length
        if line[pos].match?(/\s/)
          ws_end = pos
          ws_end += 1 while ws_end < line.length && line[ws_end].match?(/\s/)
          segments << Segment.new(line[pos...ws_end])
          pos = ws_end
          next
        end

        # Comment
        if line[pos] == "#"
          segments << Segment.new(line[pos..], style: theme[:comment])
          break
        end

        # Docstring/String
        if line[pos..pos + 2] == '"""' || line[pos..pos + 2] == "'''"
          delim = line[pos..pos + 2]
          str_end = line.index(delim, pos + 3)
          str_end = str_end ? str_end + 2 : line.length - 1
          segments << Segment.new(line[pos..str_end], style: theme[:string_doc] || theme[:string])
          pos = str_end + 1
          next
        end

        # String
        if ['"', "'"].include?(line[pos])
          delim = line[pos]
          str_end = find_string_end(line, pos, delim)
          segments << Segment.new(line[pos..str_end], style: theme[:string])
          pos = str_end + 1
          next
        end

        # Number
        if line[pos].match?(/\d/)
          num_end = pos
          num_end += 1 while num_end < line.length && line[num_end].match?(/[\d._xXoObBeE+\-]/)
          segments << Segment.new(line[pos...num_end], style: theme[:number])
          pos = num_end
          next
        end

        # Decorator
        if line[pos] == "@"
          dec_end = pos + 1
          dec_end += 1 while dec_end < line.length && line[dec_end].match?(/[\w.]/)
          segments << Segment.new(line[pos...dec_end], style: theme[:name_decorator] || theme[:name])
          pos = dec_end
          next
        end

        # Identifier
        if line[pos].match?(/[a-zA-Z_]/)
          word_end = pos
          word_end += 1 while word_end < line.length && line[word_end].match?(/\w/)
          word = line[pos...word_end]

          style = if KEYWORDS.include?(word)
                    theme[:keyword]
                  elsif BUILTINS.include?(word)
                    theme[:name_builtin] || theme[:name]
                  elsif word[0].match?(/[A-Z]/)
                    theme[:name_class] || theme[:name]
                  else
                    theme[:name]
                  end

          segments << Segment.new(word, style: style)
          pos = word_end
          next
        end

        # Operators
        if line[pos].match?(/[+\-*\/%&|^~<>=!@]/)
          op_end = pos + 1
          op_end += 1 while op_end < line.length && line[op_end].match?(/[+\-*\/%&|^~<>=!@]/)
          segments << Segment.new(line[pos...op_end], style: theme[:operator])
          pos = op_end
          next
        end

        # Punctuation
        if line[pos].match?(/[(){}\[\].,;:]/)
          segments << Segment.new(line[pos], style: theme[:punctuation])
          pos += 1
          next
        end

        segments << Segment.new(line[pos])
        pos += 1
      end

      segments
    end

    private

    def find_string_end(line, start, delimiter)
      pos = start + 1
      while pos < line.length
        return pos if line[pos] == delimiter && line[pos - 1] != "\\"

        pos += 1
      end
      line.length - 1
    end
  end

  # JavaScript lexer
  class JavaScriptLexer < BaseLexer
    KEYWORDS = %w[
      async await break case catch class const continue debugger default
      delete do else export extends finally for function if import in
      instanceof let new return static super switch this throw try typeof
      var void while with yield true false null undefined
    ].freeze

    BUILTINS = %w[
      Array Boolean Date Error Function JSON Math Number Object Promise
      RegExp String Symbol Map Set WeakMap WeakSet Proxy Reflect
      console window document parseInt parseFloat isNaN isFinite
      decodeURI decodeURIComponent encodeURI encodeURIComponent eval
      setTimeout setInterval clearTimeout clearInterval fetch
    ].freeze

    def tokenize(line, theme)
      segments = []
      pos = 0

      while pos < line.length
        if line[pos].match?(/\s/)
          ws_end = pos
          ws_end += 1 while ws_end < line.length && line[ws_end].match?(/\s/)
          segments << Segment.new(line[pos...ws_end])
          pos = ws_end
          next
        end

        # Single-line comment
        if line[pos..pos + 1] == "//"
          segments << Segment.new(line[pos..], style: theme[:comment])
          break
        end

        # Template literal
        if line[pos] == "`"
          str_end = find_string_end(line, pos, "`")
          segments << Segment.new(line[pos..str_end], style: theme[:string])
          pos = str_end + 1
          next
        end

        # String
        if ['"', "'"].include?(line[pos])
          delim = line[pos]
          str_end = find_string_end(line, pos, delim)
          segments << Segment.new(line[pos..str_end], style: theme[:string])
          pos = str_end + 1
          next
        end

        # Regex
        if line[pos] == "/" && (pos == 0 || line[pos - 1].match?(/[\s=({,\[]/))
          regex_end = find_string_end(line, pos, "/")
          if regex_end > pos
            # Include flags
            regex_end += 1 while regex_end + 1 < line.length && line[regex_end + 1].match?(/[gimsuy]/)
            segments << Segment.new(line[pos..regex_end], style: theme[:string_regex] || theme[:string])
            pos = regex_end + 1
            next
          end
        end

        # Number
        if line[pos].match?(/\d/) || (line[pos] == "." && pos + 1 < line.length && line[pos + 1].match?(/\d/))
          num_end = pos
          num_end += 1 while num_end < line.length && line[num_end].match?(/[\d._xXoObBeEnN]/)
          segments << Segment.new(line[pos...num_end], style: theme[:number])
          pos = num_end
          next
        end

        # Identifier
        if line[pos].match?(/[a-zA-Z_$]/)
          word_end = pos
          word_end += 1 while word_end < line.length && line[word_end].match?(/[\w$]/)
          word = line[pos...word_end]

          style = if KEYWORDS.include?(word)
                    theme[:keyword]
                  elsif BUILTINS.include?(word)
                    theme[:name_builtin] || theme[:name]
                  elsif word[0].match?(/[A-Z]/)
                    theme[:name_class] || theme[:name]
                  else
                    theme[:name]
                  end

          segments << Segment.new(word, style: style)
          pos = word_end
          next
        end

        # Arrow function
        if line[pos..pos + 1] == "=>"
          segments << Segment.new("=>", style: theme[:operator])
          pos += 2
          next
        end

        # Operators
        if line[pos].match?(/[+\-*\/%&|^~<>=!?:]/)
          op_end = pos + 1
          op_end += 1 while op_end < line.length && line[op_end].match?(/[+\-*\/%&|^~<>=!?:]/)
          segments << Segment.new(line[pos...op_end], style: theme[:operator])
          pos = op_end
          next
        end

        # Punctuation
        if line[pos].match?(/[(){}\[\].,;]/)
          segments << Segment.new(line[pos], style: theme[:punctuation])
          pos += 1
          next
        end

        segments << Segment.new(line[pos])
        pos += 1
      end

      segments
    end

    private

    def find_string_end(line, start, delimiter)
      pos = start + 1
      while pos < line.length
        return pos if line[pos] == delimiter && line[pos - 1] != "\\"

        pos += 1
      end
      line.length - 1
    end
  end

  # SQL Lexer
  class SQLLexer < BaseLexer
    KEYWORDS = %w[
      SELECT FROM WHERE AND OR NOT NULL IS IN LIKE BETWEEN EXISTS
      INSERT INTO VALUES UPDATE SET DELETE CREATE TABLE DROP ALTER
      INDEX VIEW TRIGGER PROCEDURE FUNCTION AS ON JOIN LEFT RIGHT
      INNER OUTER FULL CROSS NATURAL USING ORDER BY ASC DESC GROUP
      HAVING LIMIT OFFSET UNION ALL DISTINCT CASE WHEN THEN ELSE END
      IF BEGIN COMMIT ROLLBACK TRANSACTION PRIMARY KEY FOREIGN
      REFERENCES UNIQUE DEFAULT CHECK CONSTRAINT CASCADE RESTRICT
      TRUE FALSE GRANT REVOKE WITH RECURSIVE
    ].freeze

    BUILTINS = %w[
      COUNT SUM AVG MIN MAX LENGTH UPPER LOWER TRIM CONCAT SUBSTRING
      REPLACE COALESCE NULLIF CAST CONVERT DATE TIME DATETIME
      YEAR MONTH DAY HOUR MINUTE SECOND NOW CURRENT_DATE
      CURRENT_TIME CURRENT_TIMESTAMP ABS ROUND FLOOR CEILING
      POWER SQRT MOD ROW_NUMBER RANK DENSE_RANK OVER PARTITION
    ].freeze

    TYPES = %w[
      INT INTEGER BIGINT SMALLINT TINYINT FLOAT DOUBLE DECIMAL
      NUMERIC REAL CHAR VARCHAR TEXT NCHAR NVARCHAR NTEXT
      DATE TIME DATETIME TIMESTAMP BOOLEAN BOOL BLOB BINARY
      VARBINARY UUID JSON XML
    ].freeze

    def tokenize(line, theme)
      segments = []
      pos = 0

      while pos < line.length
        if line[pos].match?(/\s/)
          ws_end = pos
          ws_end += 1 while ws_end < line.length && line[ws_end].match?(/\s/)
          segments << Segment.new(line[pos...ws_end])
          pos = ws_end
          next
        end

        # Comment
        if line[pos..pos + 1] == "--"
          segments << Segment.new(line[pos..], style: theme[:comment])
          break
        end

        # String
        if line[pos] == "'"
          str_end = pos + 1
          str_end += 1 while str_end < line.length && line[str_end] != "'"
          str_end = [str_end, line.length - 1].min
          segments << Segment.new(line[pos..str_end], style: theme[:string])
          pos = str_end + 1
          next
        end

        # Number
        if line[pos].match?(/\d/)
          num_end = pos
          num_end += 1 while num_end < line.length && line[num_end].match?(/[\d.]/)
          segments << Segment.new(line[pos...num_end], style: theme[:number])
          pos = num_end
          next
        end

        # Identifier
        if line[pos].match?(/[a-zA-Z_]/)
          word_end = pos
          word_end += 1 while word_end < line.length && line[word_end].match?(/\w/)
          word = line[pos...word_end]
          upper_word = word.upcase

          style = if KEYWORDS.include?(upper_word)
                    theme[:keyword]
                  elsif BUILTINS.include?(upper_word)
                    theme[:name_builtin] || theme[:name]
                  elsif TYPES.include?(upper_word)
                    theme[:keyword_type] || theme[:keyword]
                  else
                    theme[:name]
                  end

          segments << Segment.new(word, style: style)
          pos = word_end
          next
        end

        # Operators
        if line[pos].match?(/[+\-*\/%<>=!]/)
          op_end = pos + 1
          op_end += 1 while op_end < line.length && line[op_end].match?(/[+\-*\/%<>=!]/)
          segments << Segment.new(line[pos...op_end], style: theme[:operator])
          pos = op_end
          next
        end

        # Punctuation
        if line[pos].match?(/[(),;.]/)
          segments << Segment.new(line[pos], style: theme[:punctuation])
          pos += 1
          next
        end

        segments << Segment.new(line[pos])
        pos += 1
      end

      segments
    end
  end

  # JSON Lexer (simple)
  class JSONLexer < BaseLexer
    def tokenize(line, theme)
      segments = []
      pos = 0

      while pos < line.length
        if line[pos].match?(/\s/)
          ws_end = pos
          ws_end += 1 while ws_end < line.length && line[ws_end].match?(/\s/)
          segments << Segment.new(line[pos...ws_end])
          pos = ws_end
          next
        end

        # String
        if line[pos] == '"'
          str_end = pos + 1
          str_end += 1 while str_end < line.length && !(line[str_end] == '"' && line[str_end - 1] != "\\")
          str_end = [str_end, line.length - 1].min
          content = line[pos..str_end]

          # Check if it's a key (followed by :)
          rest = line[str_end + 1..].lstrip
          is_key = rest.start_with?(":")

          segments << Segment.new(content, style: is_key ? theme[:name] : theme[:string])
          pos = str_end + 1
          next
        end

        # Number
        if line[pos].match?(/[\d\-]/)
          num_end = pos
          num_end += 1 while num_end < line.length && line[num_end].match?(/[\d.eE+\-]/)
          segments << Segment.new(line[pos...num_end], style: theme[:number])
          pos = num_end
          next
        end

        # Boolean/null
        if line[pos].match?(/[tfn]/)
          if line[pos..pos + 3] == "true"
            segments << Segment.new("true", style: theme[:keyword_constant] || theme[:keyword])
            pos += 4
            next
          elsif line[pos..pos + 4] == "false"
            segments << Segment.new("false", style: theme[:keyword_constant] || theme[:keyword])
            pos += 5
            next
          elsif line[pos..pos + 3] == "null"
            segments << Segment.new("null", style: theme[:keyword_constant] || theme[:keyword])
            pos += 4
            next
          end
        end

        # Punctuation
        if line[pos].match?(/[{}\[\]:,]/)
          segments << Segment.new(line[pos], style: theme[:punctuation])
          pos += 1
          next
        end

        segments << Segment.new(line[pos])
        pos += 1
      end

      segments
    end
  end

  # YAML Lexer
  class YAMLLexer < BaseLexer
    def tokenize(line, theme)
      segments = []
      pos = 0

      while pos < line.length
        # Comment
        if line[pos] == "#"
          segments << Segment.new(line[pos..], style: theme[:comment])
          break
        end

        # Key (before colon)
        if pos == 0 || line[0...pos].match?(/^\s*$/)
          colon_pos = line.index(":")
          if colon_pos
            key = line[0...colon_pos]
            segments << Segment.new(key, style: theme[:name])
            segments << Segment.new(":", style: theme[:punctuation])
            pos = colon_pos + 1
            next
          end
        end

        if line[pos].match?(/\s/)
          ws_end = pos
          ws_end += 1 while ws_end < line.length && line[ws_end].match?(/\s/)
          segments << Segment.new(line[pos...ws_end])
          pos = ws_end
          next
        end

        # String
        if ['"', "'"].include?(line[pos])
          delim = line[pos]
          str_end = pos + 1
          str_end += 1 while str_end < line.length && line[str_end] != delim
          str_end = [str_end, line.length - 1].min
          segments << Segment.new(line[pos..str_end], style: theme[:string])
          pos = str_end + 1
          next
        end

        # Boolean/null
        rest = line[pos..].downcase
        if rest.start_with?("true") || rest.start_with?("false") || rest.start_with?("null") || rest.start_with?("yes") || rest.start_with?("no")
          word_end = pos
          word_end += 1 while word_end < line.length && line[word_end].match?(/\w/)
          segments << Segment.new(line[pos...word_end], style: theme[:keyword_constant] || theme[:keyword])
          pos = word_end
          next
        end

        # Number
        if line[pos].match?(/[\d\-]/)
          num_end = pos
          num_end += 1 while num_end < line.length && line[num_end].match?(/[\d.]/)
          segments << Segment.new(line[pos...num_end], style: theme[:number])
          pos = num_end
          next
        end

        # List marker
        if line[pos] == "-" && (pos + 1 >= line.length || line[pos + 1].match?(/\s/))
          segments << Segment.new("-", style: theme[:punctuation])
          pos += 1
          next
        end

        # Default text
        word_end = pos
        word_end += 1 while word_end < line.length && !line[word_end].match?(/[\s#]/)
        segments << Segment.new(line[pos...word_end], style: theme[:string])
        pos = word_end
      end

      segments
    end
  end

  # Bash/Shell lexer
  class BashLexer < BaseLexer
    KEYWORDS = %w[
      if then else elif fi case esac for while until do done in
      function return exit break continue local export readonly
      declare typeset source alias unalias
    ].freeze

    BUILTINS = %w[
      echo printf read cd pwd pushd popd dirs ls cat grep sed awk
      cut sort uniq wc head tail less more find xargs chmod chown
      mkdir rmdir rm cp mv ln touch date time kill ps top df du
      tar gzip gunzip zip unzip curl wget ssh scp rsync git
      sudo su man which whereis whatis type hash history set unset
      shift eval exec test true false
    ].freeze

    def tokenize(line, theme)
      segments = []
      pos = 0

      while pos < line.length
        if line[pos].match?(/\s/)
          ws_end = pos
          ws_end += 1 while ws_end < line.length && line[ws_end].match?(/\s/)
          segments << Segment.new(line[pos...ws_end])
          pos = ws_end
          next
        end

        # Comment
        if line[pos] == "#"
          segments << Segment.new(line[pos..], style: theme[:comment])
          break
        end

        # String
        if ['"', "'"].include?(line[pos])
          delim = line[pos]
          str_end = pos + 1
          str_end += 1 while str_end < line.length && !(line[str_end] == delim && line[str_end - 1] != "\\")
          str_end = [str_end, line.length - 1].min
          segments << Segment.new(line[pos..str_end], style: theme[:string])
          pos = str_end + 1
          next
        end

        # Variable
        if line[pos] == "$"
          var_end = pos + 1
          if var_end < line.length && line[var_end] == "{"
            var_end = line.index("}", var_end) || line.length - 1
          else
            var_end += 1 while var_end < line.length && line[var_end].match?(/\w/)
          end
          segments << Segment.new(line[pos..var_end], style: theme[:name_variable] || theme[:name])
          pos = var_end + 1
          next
        end

        # Number
        if line[pos].match?(/\d/)
          num_end = pos
          num_end += 1 while num_end < line.length && line[num_end].match?(/\d/)
          segments << Segment.new(line[pos...num_end], style: theme[:number])
          pos = num_end
          next
        end

        # Identifier
        if line[pos].match?(/[a-zA-Z_]/)
          word_end = pos
          word_end += 1 while word_end < line.length && line[word_end].match?(/[\w\-]/)
          word = line[pos...word_end]

          style = if KEYWORDS.include?(word)
                    theme[:keyword]
                  elsif BUILTINS.include?(word)
                    theme[:name_builtin] || theme[:name]
                  else
                    theme[:name]
                  end

          segments << Segment.new(word, style: style)
          pos = word_end
          next
        end

        # Operators and special chars
        if line[pos].match?(/[|&;<>(){}]/)
          segments << Segment.new(line[pos], style: theme[:operator])
          pos += 1
          next
        end

        segments << Segment.new(line[pos])
        pos += 1
      end

      segments
    end
  end

  # Plain text (no highlighting)
  class TextLexer < BaseLexer
    # Just returns the line as-is
  end

  # Lexer registry
  LEXERS = {
    "ruby" => RubyLexer.new,
    "python" => PythonLexer.new,
    "javascript" => JavaScriptLexer.new,
    "js" => JavaScriptLexer.new,
    "typescript" => JavaScriptLexer.new,
    "ts" => JavaScriptLexer.new,
    "sql" => SQLLexer.new,
    "json" => JSONLexer.new,
    "yaml" => YAMLLexer.new,
    "yml" => YAMLLexer.new,
    "bash" => BashLexer.new,
    "shell" => BashLexer.new,
    "sh" => BashLexer.new,
    "text" => TextLexer.new,
    "txt" => TextLexer.new
  }.freeze
end
