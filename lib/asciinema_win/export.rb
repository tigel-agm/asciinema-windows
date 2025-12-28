# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

module AsciinemaWin
  # Export module for converting recordings to different formats
  #
  # Supports export to:
  # - Cast (asciicast v2 - copy/convert)
  # - HTML (embedded player)
  # - SVG (static snapshot)
  # - Text (plain text dump)
  # - JSON (normalized format)
  # - GIF/MP4/WebM (requires FFmpeg - optional)
  #
  # @note Video export requires FFmpeg installed and in PATH.
  #       This is an OPTIONAL feature - core functionality works without it.
  module Export
    # Export formats supported natively (no external dependencies)
    NATIVE_FORMATS = %i[cast html svg txt text json].freeze

    # Export formats requiring external tools
    EXTERNAL_FORMATS = %i[gif mp4 webm].freeze

    # All supported formats
    ALL_FORMATS = (NATIVE_FORMATS + EXTERNAL_FORMATS).freeze

    class << self
      # Export a recording to the specified format
      #
      # @param input_path [String] Path to the .cast file
      # @param output_path [String] Path for the output file
      # @param format [Symbol] Output format (:cast, :html, :svg, :txt, :json, :gif, :mp4, :webm)
      # @param options [Hash] Format-specific options
      # @return [Boolean] True if export succeeded
      # @raise [ExportError] If export fails
      def export(input_path, output_path, format:, **options)
        format = format.to_sym

        unless ALL_FORMATS.include?(format)
          raise ExportError, "Unsupported format: #{format}. Supported: #{ALL_FORMATS.join(", ")}"
        end

        case format
        when :cast
          export_cast(input_path, output_path, **options)
        when :html
          export_html(input_path, output_path, **options)
        when :svg
          export_svg(input_path, output_path, **options)
        when :txt, :text
          export_text(input_path, output_path, **options)
        when :json
          export_json(input_path, output_path, **options)
        when :gif, :mp4, :webm
          export_video(input_path, output_path, format: format, **options)
        end
      end

      # Export to asciicast v2 format (copy or transform)
      #
      # @param input_path [String] Input .cast file
      # @param output_path [String] Output .cast file
      # @param title [String, nil] New title (optional)
      # @param trim_start [Float, nil] Trim seconds from start
      # @param trim_end [Float, nil] Trim seconds from end
      # @param speed [Float] Speed multiplier (1.0 = normal, 2.0 = 2x faster)
      # @param max_idle [Float, nil] Maximum idle time between events
      # @return [Boolean] Success
      def export_cast(input_path, output_path, title: nil, trim_start: nil, trim_end: nil, speed: 1.0, max_idle: nil, **_options)
        reader = Asciicast.load(input_path)
        original_header = reader.header

        # Create new header with potential modifications
        new_header = Asciicast::Header.new(
          width: original_header.width,
          height: original_header.height,
          timestamp: original_header.timestamp,
          idle_time_limit: max_idle || original_header.idle_time_limit,
          command: original_header.command,
          title: title || original_header.title,
          env: original_header.env,
          theme: original_header.theme
        )

        File.open(output_path, "w", encoding: "UTF-8") do |file|
          writer = Asciicast::Writer.new(file, new_header)
          last_time = 0.0

          reader.each_event do |event|
            # Apply trimming if specified
            next if trim_start && event.time < trim_start
            next if trim_end && event.time > trim_end

            # Adjust time for trimming
            adjusted_time = trim_start ? event.time - trim_start : event.time

            # Apply speed adjustment
            adjusted_time /= speed

            # Apply max idle limit
            if max_idle && (adjusted_time - last_time) > max_idle
              adjusted_time = last_time + max_idle
            end

            writer.write_event(Asciicast::Event.new(adjusted_time, event.type, event.data))
            last_time = adjusted_time
          end

          writer.close
        end

        true
      end

      # Concatenate multiple recordings into one
      #
      # @param input_paths [Array<String>] Paths to .cast files to concatenate
      # @param output_path [String] Output .cast file path
      # @param title [String, nil] Title for combined recording
      # @param gap [Float] Gap in seconds between recordings
      # @return [Boolean] Success
      def concatenate(input_paths, output_path, title: nil, gap: 1.0)
        raise ExportError, "No input files specified" if input_paths.empty?

        # Load first file to get dimensions
        first_reader = Asciicast.load(input_paths.first)
        first_header = first_reader.header

        # Determine max dimensions across all files
        max_width = first_header.width
        max_height = first_header.height

        input_paths[1..].each do |path|
          reader = Asciicast.load(path)
          max_width = [max_width, reader.header.width].max
          max_height = [max_height, reader.header.height].max
        end

        # Create output header
        combined_title = title || input_paths.map { |p| File.basename(p, ".cast") }.join(" + ")
        new_header = Asciicast::Header.new(
          width: max_width,
          height: max_height,
          timestamp: first_header.timestamp,
          title: combined_title
        )

        File.open(output_path, "w", encoding: "UTF-8") do |file|
          writer = Asciicast::Writer.new(file, new_header)
          current_time = 0.0

          input_paths.each_with_index do |path, index|
            reader = Asciicast.load(path)
            last_event_time = 0.0

            reader.each_event do |event|
              writer.write_event(Asciicast::Event.new(current_time + event.time, event.type, event.data))
              last_event_time = event.time
            end

            # Add gap before next recording (except after last)
            current_time += last_event_time + gap if index < input_paths.length - 1

            # Add marker at join point
            if index < input_paths.length - 1
              writer.write_marker(current_time - gap / 2, "joined: #{File.basename(path)}")
            end
          end

          writer.close
        end

        true
      end

      # Generate a thumbnail image from a recording
      #
      # @param input_path [String] Input .cast file
      # @param output_path [String] Output image path (.svg or .png)
      # @param frame [Symbol] Which frame (:first, :last, :middle)
      # @param theme [String] Color theme
      # @param width [Integer, nil] Override width in pixels
      # @param height [Integer, nil] Override height in pixels
      # @return [Boolean] Success
      def thumbnail(input_path, output_path, frame: :last, theme: "asciinema", width: nil, height: nil, **_options)
        info = Asciicast::Reader.info(input_path)
        reader = Asciicast.load(input_path)

        # Determine which frame to capture
        target_time = case frame
                      when :first then 0.0
                      when :last then info[:duration]
                      when :middle then info[:duration] / 2
                      when Numeric then frame.to_f
                      else info[:duration]
                      end

        # Collect output up to target time
        output = StringIO.new
        reader.each_event do |event|
          break if event.time > target_time

          output << event.data if event.output?
        end

        # Parse and render
        color_theme = Themes.get(theme)
        parser = AnsiParser.new(width: info[:width], height: info[:height])
        lines = parser.parse(output.string)

        svg = generate_thumbnail_svg(lines, info[:width], info[:height], color_theme, width: width, height: height)

        File.write(output_path, svg, encoding: "UTF-8")
        true
      end

      # Adjust playback speed of a recording
      #
      # @param input_path [String] Input .cast file
      # @param output_path [String] Output .cast file
      # @param speed [Float] Speed multiplier (2.0 = 2x faster)
      # @param max_idle [Float, nil] Compress idle time to this maximum
      # @return [Boolean] Success
      def adjust_speed(input_path, output_path, speed: 1.0, max_idle: nil)
        export_cast(input_path, output_path, speed: speed, max_idle: max_idle)
      end

      # Export to HTML with embedded asciinema-player
      #
      # @param input_path [String] Input .cast file
      # @param output_path [String] Output .html file
      # @param title [String] Page title
      # @param theme [String] Player theme (asciinema, tango, solarized-dark, etc.)
      # @param autoplay [Boolean] Auto-start playback
      # @return [Boolean] Success
      def export_html(input_path, output_path, title: nil, theme: "asciinema", autoplay: false, **_options)
        info = Asciicast::Reader.info(input_path)
        cast_content = File.read(input_path, encoding: "UTF-8")
        title ||= info[:title] || "Terminal Recording"

        html = generate_html(cast_content, info, title: title, theme: theme, autoplay: autoplay)

        File.write(output_path, html, encoding: "UTF-8")
        true
      end

      # Export to SVG with full color support
      #
      # @param input_path [String] Input .cast file
      # @param output_path [String] Output .svg file
      # @param theme [String] Color theme (asciinema, dracula, monokai, etc.)
      # @param frame [Symbol] Which frame to capture (:first, :last, :all)
      # @return [Boolean] Success
      def export_svg(input_path, output_path, theme: "asciinema", frame: :last, **_options)
        info = Asciicast::Reader.info(input_path)
        reader = Asciicast.load(input_path)

        # Collect all output
        output = StringIO.new
        reader.each_event do |event|
          output << event.data if event.output?
        end

        # Parse ANSI codes and render colored SVG
        color_theme = Themes.get(theme)
        svg = generate_colored_svg(output.string, info[:width], info[:height], color_theme)

        File.write(output_path, svg, encoding: "UTF-8")
        true
      end

      # Export to plain text
      #
      # @param input_path [String] Input .cast file
      # @param output_path [String] Output .txt file
      # @param strip_ansi [Boolean] Remove ANSI escape sequences
      # @return [Boolean] Success
      def export_text(input_path, output_path, strip_ansi: true, **_options)
        reader = Asciicast.load(input_path)

        output = StringIO.new
        reader.each_event do |event|
          output << event.data if event.output?
        end

        text = output.string
        text = strip_ansi_codes(text) if strip_ansi

        File.write(output_path, text, encoding: "UTF-8")
        true
      end

      # Export to JSON (normalized format)
      #
      # @param input_path [String] Input .cast file
      # @param output_path [String] Output .json file
      # @return [Boolean] Success
      def export_json(input_path, output_path, **_options)
        require "json"

        info = Asciicast::Reader.info(input_path)
        reader = Asciicast.load(input_path)

        events = reader.each_event.map do |event|
          { time: event.time, type: event.type, data: event.data }
        end

        data = {
          header: info,
          events: events
        }

        File.write(output_path, JSON.pretty_generate(data), encoding: "UTF-8")
        true
      end

      # Export to video format (GIF, MP4, WebM)
      #
      # Uses FFmpeg with 2-pass palette generation for high-quality GIF output.
      # Renders each frame as SVG and pipes directly to FFmpeg for optimal efficiency.
      #
      # @note Requires FFmpeg to be installed and in PATH (or FFMPEG_PATH set)
      #
      # @param input_path [String] Input .cast file
      # @param output_path [String] Output video file
      # @param format [Symbol] Video format (:gif, :mp4, :webm)
      # @param fps [Integer] Frames per second (default: 10)
      # @param font_size [Integer] Font size in pixels (default: 14)
      # @param theme [String] Color theme name (default: "asciinema")
      # @param scale [Float] Output scale factor (default: 1.0)
      # @param loop_count [Integer] GIF loop count (-1=infinite, 0=none, default: -1)
      # @return [Boolean] Success
      # @raise [ExportError] If FFmpeg is not available or export fails
      def export_video(input_path, output_path, format:, fps: 10, font_size: 14, theme: "asciinema", scale: 1.0, loop_count: -1, **_options)
        unless ffmpeg_available?
          raise ExportError, <<~MSG
            FFmpeg is required for #{format.upcase} export but was not found.

            To install FFmpeg:
            1. Download from https://ffmpeg.org/download.html
            2. Add to PATH or set FFMPEG_PATH environment variable

            Alternatively, use native export formats: #{NATIVE_FORMATS.join(", ")}
          MSG
        end

        # Create temporary directory for frames
        temp_dir = File.join(Dir.tmpdir, "asciinema_win_#{Process.pid}_#{Time.now.to_i}")
        FileUtils.mkdir_p(temp_dir)

        begin
          # Generate SVG frame files
          $stderr.puts "Generating frames at #{fps} FPS..."
          frame_count = generate_video_frames(
            input_path, temp_dir,
            fps: fps,
            font_size: font_size,
            theme: theme,
            scale: scale
          )

          if frame_count == 0
            raise ExportError, "No frames generated from recording"
          end

          $stderr.puts "Generated #{frame_count} frames"

          # Use FFmpeg to create video
          $stderr.puts "Encoding #{format.upcase}..."
          ffmpeg_create_video(temp_dir, output_path, format: format, fps: fps, loop_count: loop_count)

          $stderr.puts "Video saved to #{output_path}"
          true
        ensure
          # Cleanup temp files
          FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
        end
      end

      # Check if FFmpeg is available
      #
      # @return [Boolean] True if FFmpeg is in PATH
      def ffmpeg_available?
        ffmpeg_path = ENV["FFMPEG_PATH"] || "ffmpeg"
        system("#{ffmpeg_path} -version", out: File::NULL, err: File::NULL)
      rescue StandardError
        false
      end

      private

      # Generate HTML with embedded player
      def generate_html(cast_content, info, title:, theme:, autoplay:)
        # Escape the cast content for embedding in JavaScript
        escaped_cast = cast_content.gsub("\\", "\\\\\\\\")
                                   .gsub("'", "\\\\'")
                                   .gsub("\n", "\\n")
                                   .gsub("\r", "\\r")

        autoplay_attr = autoplay ? 'autoplay="true"' : ""

        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>#{title}</title>
            <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/asciinema-player@3.6.3/dist/bundle/asciinema-player.css" />
            <style>
              body {
                margin: 0;
                padding: 20px;
                background: #1a1a2e;
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
              }
              .container {
                max-width: 1000px;
                margin: 0 auto;
              }
              h1 {
                color: #eee;
                margin-bottom: 20px;
              }
              .info {
                color: #888;
                margin-bottom: 20px;
              }
              #player {
                border-radius: 8px;
                overflow: hidden;
              }
            </style>
          </head>
          <body>
            <div class="container">
              <h1>#{title}</h1>
              <div class="info">
                Size: #{info[:width]}x#{info[:height]} |
                Duration: #{format("%.1f", info[:duration])}s |
                Events: #{info[:event_count]}
              </div>
              <div id="player"></div>
            </div>

            <script src="https://cdn.jsdelivr.net/npm/asciinema-player@3.6.3/dist/bundle/asciinema-player.min.js"></script>
            <script>
              const castContent = '#{escaped_cast}';
              const blob = new Blob([castContent], { type: 'text/plain' });
              const url = URL.createObjectURL(blob);

              AsciinemaPlayer.create(url, document.getElementById('player'), {
                theme: '#{theme}',
                #{autoplay_attr}
                fit: 'width',
                fontSize: 'medium'
              });
            </script>
          </body>
          </html>
        HTML
      end

      # Generate colored SVG representation using ANSI parser
      #
      # @param content [String] Raw ANSI content
      # @param width [Integer] Terminal width
      # @param height [Integer] Terminal height
      # @param theme [Themes::Theme] Color theme
      # @return [String] SVG content
      def generate_colored_svg(content, width, height, theme)
        # Parse ANSI content
        parser = AnsiParser.new(width: width, height: height)
        lines = parser.parse(content)

        char_width = 8.4
        char_height = 18
        padding = 16
        border_radius = 8

        svg_width = (width * char_width + padding * 2).ceil
        svg_height = (height * char_height + padding * 2 + 30).ceil  # +30 for title bar

        # Build SVG content
        svg_content = StringIO.new

        # Render each line
        lines.each_with_index do |line, y|
          y_pos = padding + 30 + (y + 1) * char_height  # +30 for title bar offset

          # Group characters with same style for efficiency
          x = 0
          while x < line.chars.length
            char_data = line.chars[x]

            # Find run of characters with same style
            run_start = x
            while x < line.chars.length && line.chars[x].same_style?(char_data)
              x += 1
            end

            # Skip if just spaces with default style
            text = line.chars[run_start...x].map(&:char).join
            next if text.match?(/^\s*$/) && char_data.default_style?

            # Calculate position
            x_pos = padding + run_start * char_width

            # Build style attributes
            styles = []
            fill = resolve_fg_color(char_data.fg, theme)
            styles << "fill:#{fill}" if fill != theme.foreground

            bg = resolve_bg_color(char_data.bg, theme)
            if bg && bg != theme.background
              # Add background rectangle
              bg_width = (x - run_start) * char_width
              svg_content << %(<rect x="#{x_pos}" y="#{y_pos - char_height + 4}" width="#{bg_width}" height="#{char_height}" fill="#{bg}"/>)
              svg_content << "\n"
            end

            styles << "font-weight:bold" if char_data.bold
            styles << "font-style:italic" if char_data.italic

            style_attr = styles.empty? ? "" : %( style="#{styles.join(";")}")

            # Escape text for XML
            escaped = text.gsub("&", "&amp;")
                          .gsub("<", "&lt;")
                          .gsub(">", "&gt;")
                          .gsub("'", "&apos;")
                          .gsub('"', "&quot;")

            # Add decorations
            decorations = []
            decorations << "underline" if char_data.underline
            decorations << "line-through" if char_data.strikethrough
            dec_attr = decorations.empty? ? "" : %( text-decoration="#{decorations.join(" ")}")

            svg_content << %(<text x="#{x_pos}" y="#{y_pos}" class="t"#{style_attr}#{dec_attr}>#{escaped}</text>)
            svg_content << "\n"
          end
        end

        # Window button colors
        close_color = "#ff5f56"
        minimize_color = "#ffbd2e"
        maximize_color = "#27c93f"

        <<~SVG
          <?xml version="1.0" encoding="UTF-8"?>
          <svg xmlns="http://www.w3.org/2000/svg" width="#{svg_width}" height="#{svg_height}" viewBox="0 0 #{svg_width} #{svg_height}">
            <defs>
              <style>
                .bg { fill: #{theme.background}; }
                .title-bar { fill: #{darken_color(theme.background, 0.15)}; }
                .t {
                  font-family: "Cascadia Code", "Fira Code", "Consolas", "Monaco", "Courier New", monospace;
                  font-size: 14px;
                  fill: #{theme.foreground};
                  white-space: pre;
                }
              </style>
            </defs>

            <!-- Window frame -->
            <rect class="bg" width="100%" height="100%" rx="#{border_radius}"/>

            <!-- Title bar -->
            <rect class="title-bar" width="100%" height="30" rx="#{border_radius}" ry="#{border_radius}"/>
            <rect class="title-bar" y="#{border_radius}" width="100%" height="#{30 - border_radius}"/>

            <!-- Window buttons -->
            <circle cx="20" cy="15" r="6" fill="#{close_color}"/>
            <circle cx="40" cy="15" r="6" fill="#{minimize_color}"/>
            <circle cx="60" cy="15" r="6" fill="#{maximize_color}"/>

            <!-- Terminal content -->
            <g class="terminal">
          #{svg_content.string}    </g>
          </svg>
        SVG
      end

      # Generate thumbnail SVG (smaller, simplified)
      #
      # @param lines [Array<ParsedLine>] Parsed lines
      # @param term_width [Integer] Terminal width
      # @param term_height [Integer] Terminal height
      # @param theme [Themes::Theme] Color theme
      # @param width [Integer, nil] Override width
      # @param height [Integer, nil] Override height
      # @return [String] SVG content
      def generate_thumbnail_svg(lines, term_width, term_height, theme, width: nil, height: nil)
        # Calculate dimensions
        char_width = 6.0
        char_height = 12.0
        padding = 8
        border_radius = 6
        title_bar_height = 20

        svg_width = width || (term_width * char_width + padding * 2).ceil
        svg_height = height || (term_height * char_height + padding * 2 + title_bar_height).ceil

        # Scale factor if custom dimensions provided
        scale_x = width ? width.to_f / (term_width * char_width + padding * 2) : 1.0
        scale_y = height ? height.to_f / (term_height * char_height + padding * 2 + title_bar_height) : 1.0

        # Build SVG content
        svg_content = StringIO.new

        # Render each line (simplified)
        lines.each_with_index do |line, y|
          y_pos = (padding + title_bar_height + (y + 1) * char_height) * scale_y

          x = 0
          while x < line.chars.length
            char_data = line.chars[x]

            run_start = x
            while x < line.chars.length && line.chars[x].same_style?(char_data)
              x += 1
            end

            text = line.chars[run_start...x].map(&:char).join
            next if text.match?(/^\s*$/) && char_data.default_style?

            x_pos = (padding + run_start * char_width) * scale_x
            fill = resolve_fg_color(char_data.fg, theme)
            style = fill != theme.foreground ? %( style="fill:#{fill}") : ""

            escaped = text.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
            svg_content << %(<text x="#{x_pos}" y="#{y_pos}" class="t"#{style}>#{escaped}</text>\n)
          end
        end

        <<~SVG
          <?xml version="1.0" encoding="UTF-8"?>
          <svg xmlns="http://www.w3.org/2000/svg" width="#{svg_width}" height="#{svg_height}">
            <defs>
              <style>
                .bg { fill: #{theme.background}; }
                .bar { fill: #{darken_color(theme.background, 0.15)}; }
                .t {
                  font-family: monospace;
                  font-size: #{(10 * scale_y).round}px;
                  fill: #{theme.foreground};
                }
              </style>
            </defs>
            <rect class="bg" width="100%" height="100%" rx="#{border_radius}"/>
            <rect class="bar" width="100%" height="#{title_bar_height}" rx="#{border_radius}"/>
            <circle cx="12" cy="10" r="4" fill="#ff5f56"/>
            <circle cx="26" cy="10" r="4" fill="#ffbd2e"/>
            <circle cx="40" cy="10" r="4" fill="#27c93f"/>
            <g class="content">
          #{svg_content.string}    </g>
          </svg>
        SVG
      end

      # Resolve foreground color from ANSI code to hex
      #
      # @param fg [Integer, String, nil] Foreground color
      # @param theme [Themes::Theme] Color theme
      # @return [String] Hex color
      def resolve_fg_color(fg, theme)
        return theme.foreground if fg.nil?
        return fg if fg.is_a?(String) && fg.start_with?("#")

        case fg
        when 30..37
          theme.fg_color(fg)
        when 90..97
          theme.fg_color(fg)
        when Integer
          theme.color(fg)
        else
          theme.foreground
        end
      end

      # Resolve background color from ANSI code to hex
      #
      # @param bg [Integer, String, nil] Background color
      # @param theme [Themes::Theme] Color theme
      # @return [String, nil] Hex color or nil
      def resolve_bg_color(bg, theme)
        return nil if bg.nil?
        return bg if bg.is_a?(String) && bg.start_with?("#")

        case bg
        when 40..47
          theme.bg_color(bg)
        when 100..107
          theme.bg_color(bg)
        when Integer
          theme.color(bg)
        else
          nil
        end
      end

      # Darken a hex color
      #
      # @param hex [String] Hex color (#rrggbb)
      # @param factor [Float] Darken factor (0-1)
      # @return [String] Darkened hex color
      def darken_color(hex, factor)
        hex = hex.delete("#")
        r = [(hex[0..1].to_i(16) * (1 - factor)).round, 0].max
        g = [(hex[2..3].to_i(16) * (1 - factor)).round, 0].max
        b = [(hex[4..5].to_i(16) * (1 - factor)).round, 0].max
        format("#%02x%02x%02x", r, g, b)
      end

      # Generate SVG representation (legacy, no colors)
      def generate_svg(content, width, height)
        # Strip ANSI codes for SVG (simplified)
        text = strip_ansi_codes(content)
        lines = text.split("\n")

        char_width = 8
        char_height = 16
        padding = 20

        svg_width = width * char_width + padding * 2
        svg_height = height * char_height + padding * 2

        svg_lines = lines.first(height).map.with_index do |line, y|
          escaped = line.gsub("&", "&amp;")
                        .gsub("<", "&lt;")
                        .gsub(">", "&gt;")
          y_pos = padding + (y + 1) * char_height
          %(<text x="#{padding}" y="#{y_pos}" class="line">#{escaped}</text>)
        end.join("\n")

        <<~SVG
          <?xml version="1.0" encoding="UTF-8"?>
          <svg xmlns="http://www.w3.org/2000/svg" width="#{svg_width}" height="#{svg_height}">
            <style>
              .bg { fill: #1a1a2e; }
              .line {
                font-family: "Consolas", "Monaco", "Courier New", monospace;
                font-size: 14px;
                fill: #eee;
              }
            </style>
            <rect class="bg" width="100%" height="100%" rx="8"/>
            #{svg_lines}
          </svg>
        SVG
      end

      # Strip ANSI escape codes from text
      def strip_ansi_codes(text)
        # Remove all ANSI escape sequences
        text.gsub(/\e\[[0-9;]*[a-zA-Z]/, "")
            .gsub(/\e\][^\a]*\a/, "")  # OSC sequences
            .gsub(/\r/, "")             # Carriage returns
      end

      # Generate video frames by rendering terminal state at each frame time
      #
      # @param input_path [String] Input .cast file
      # @param temp_dir [String] Temporary directory for frame files
      # @param fps [Integer] Frames per second
      # @param font_size [Integer] Font size in pixels
      # @param theme [String] Color theme name
      # @param scale [Float] Output scale factor
      # @return [Integer] Number of frames generated
      def generate_video_frames(input_path, temp_dir, fps:, font_size:, theme: "asciinema", scale: 1.0)
        # Load recording info and data
        info = Asciicast::Reader.info(input_path)
        reader = Asciicast.load(input_path)
        color_theme = Themes.get(theme)

        term_width = info[:width]
        term_height = info[:height]
        duration = info[:duration]

        # Character cell dimensions (8x16 is standard VGA font size)
        cell_width = 8
        cell_height = 16

        # Calculate image dimensions
        padding = 16
        title_bar_height = 24
        img_width = term_width * cell_width + padding * 2
        img_height = term_height * cell_height + padding * 2 + title_bar_height

        # Collect all output events with timestamps
        events = []
        reader.each_event do |event|
          events << { time: event.time, data: event.data } if event.output?
        end

        # Calculate frame times
        frame_interval = 1.0 / fps
        frame_times = []
        t = 0.0
        while t <= duration
          frame_times << t
          t += frame_interval
        end

        # Ensure we have at least the final frame
        frame_times << duration if frame_times.last < duration

        frame_count = 0
        last_content_hash = nil

        frame_times.each_with_index do |frame_time, idx|
          # Accumulate output up to this frame time
          accumulated_output = StringIO.new
          events.each do |event|
            break if event[:time] > frame_time
            accumulated_output << event[:data]
          end

          # Parse ANSI content
          parser = AnsiParser.new(width: term_width, height: term_height)
          lines = parser.parse(accumulated_output.string)

          # Compute content hash for deduplication
          content_hash = lines.hash

          # Render to PPM bitmap
          frame_path = File.join(temp_dir, format("frame_%04d.ppm", frame_count))

          if content_hash != last_content_hash
            ppm_data = render_frame_ppm(
              lines, term_width, term_height, color_theme,
              cell_width: cell_width,
              cell_height: cell_height,
              padding: padding,
              title_bar_height: title_bar_height,
              img_width: img_width,
              img_height: img_height
            )
            File.binwrite(frame_path, ppm_data)
            last_content_hash = content_hash
          else
            # Duplicate previous frame
            if frame_count > 0
              prev_path = File.join(temp_dir, format("frame_%04d.ppm", frame_count - 1))
              FileUtils.cp(prev_path, frame_path) if File.exist?(prev_path)
            end
          end

          frame_count += 1

          # Progress indicator
          if (idx % 10).zero? || idx == frame_times.length - 1
            progress = ((idx + 1).to_f / frame_times.length * 100).round
            $stderr.print "\rRendering: #{progress}% (#{idx + 1}/#{frame_times.length})"
          end
        end

        $stderr.puts "" # Newline after progress
        frame_count
      end

      # Render a single frame to PPM (Portable Pixmap) format
      #
      # PPM is a simple image format that FFmpeg reads natively.
      # Uses an embedded 8x16 bitmap font for character rendering.
      #
      # @param lines [Array<ParsedLine>] Parsed ANSI lines
      # @param term_width [Integer] Terminal width
      # @param term_height [Integer] Terminal height
      # @param theme [Themes::Theme] Color theme
      # @param options [Hash] Rendering options
      # @return [String] Binary PPM image data
      def render_frame_ppm(lines, term_width, term_height, theme,
                           cell_width:, cell_height:, padding:, title_bar_height:,
                           img_width:, img_height:)
        # Parse background color
        bg_rgb = hex_to_rgb(theme.background)
        title_bar_rgb = darken_rgb(bg_rgb, 0.15)
        fg_rgb = hex_to_rgb(theme.foreground)

        # Create pixel buffer
        pixels = Array.new(img_height) { Array.new(img_width) { bg_rgb } }

        # Draw title bar
        title_bar_height.times do |y|
          img_width.times do |x|
            pixels[y][x] = title_bar_rgb
          end
        end

        # Draw window buttons in title bar
        button_y = title_bar_height / 2
        button_radius = 5
        draw_circle(pixels, 16, button_y, button_radius, [255, 95, 86])   # Close (red)
        draw_circle(pixels, 36, button_y, button_radius, [255, 189, 46])  # Minimize (yellow)
        draw_circle(pixels, 56, button_y, button_radius, [39, 201, 63])   # Maximize (green)

        # Render each line of terminal content
        content_y_start = padding + title_bar_height

        lines.each_with_index do |line, row|
          next unless line.respond_to?(:chars)

          y_base = content_y_start + row * cell_height

          col = 0
          while col < line.chars.length && col < term_width
            char_data = line.chars[col]
            char = char_data.char

            # Get foreground color
            char_fg = resolve_rgb_color(char_data.fg, theme, fg_rgb)
            char_bg = resolve_rgb_color(char_data.bg, theme, bg_rgb, is_bg: true)

            x_base = padding + col * cell_width

            # Draw background if different from default
            if char_bg != bg_rgb
              cell_height.times do |dy|
                cell_width.times do |dx|
                  px = x_base + dx
                  py = y_base + dy
                  pixels[py][px] = char_bg if py < img_height && px < img_width
                end
              end
            end

            # Draw character glyph
            draw_char(pixels, x_base, y_base, char, char_fg, cell_width, cell_height)

            col += 1
          end
        end

        # Encode as PPM
        encode_ppm(pixels, img_width, img_height)
      end

      # Parse hex color to RGB array
      #
      # @param hex [String] Hex color string (#RRGGBB)
      # @return [Array<Integer>] RGB values [r, g, b]
      def hex_to_rgb(hex)
        hex = hex.delete("#")
        [
          hex[0..1].to_i(16),
          hex[2..3].to_i(16),
          hex[4..5].to_i(16)
        ]
      end

      # Darken an RGB color
      #
      # @param rgb [Array<Integer>] RGB values
      # @param factor [Float] Darken factor (0-1)
      # @return [Array<Integer>] Darkened RGB values
      def darken_rgb(rgb, factor)
        rgb.map { |c| [(c * (1 - factor)).round, 0].max }
      end

      # Resolve ANSI color code to RGB
      #
      # @param color [Integer, String, nil] Color value
      # @param theme [Themes::Theme] Color theme
      # @param default [Array<Integer>] Default RGB value
      # @param is_bg [Boolean] Whether this is a background color
      # @return [Array<Integer>] RGB values
      def resolve_rgb_color(color, theme, default, is_bg: false)
        return default if color.nil?

        if color.is_a?(String) && color.start_with?("#")
          return hex_to_rgb(color)
        end

        hex = if is_bg
                resolve_bg_color(color, theme)
              else
                resolve_fg_color(color, theme)
              end

        hex ? hex_to_rgb(hex) : default
      end

      # Draw a filled circle on pixel buffer
      #
      # @param pixels [Array<Array<Array>>] Pixel buffer
      # @param cx [Integer] Center X
      # @param cy [Integer] Center Y
      # @param radius [Integer] Radius
      # @param rgb [Array<Integer>] RGB color
      def draw_circle(pixels, cx, cy, radius, rgb)
        (cy - radius).upto(cy + radius) do |y|
          next if y < 0 || y >= pixels.length

          (cx - radius).upto(cx + radius) do |x|
            next if x < 0 || x >= pixels[0].length

            dx = x - cx
            dy = y - cy
            pixels[y][x] = rgb if dx * dx + dy * dy <= radius * radius
          end
        end
      end

      # Draw a character glyph on pixel buffer
      #
      # Uses a simple 8x16 bitmap font for ASCII characters
      #
      # @param pixels [Array<Array<Array>>] Pixel buffer
      # @param x [Integer] X position
      # @param y [Integer] Y position
      # @param char [String] Character to draw
      # @param rgb [Array<Integer>] Foreground RGB color
      # @param cell_width [Integer] Cell width
      # @param cell_height [Integer] Cell height
      def draw_char(pixels, x, y, char, rgb, cell_width, cell_height)
        glyph = font_glyph(char)
        return unless glyph

        glyph.each_with_index do |row_bits, dy|
          py = y + dy
          next if py < 0 || py >= pixels.length

          8.times do |dx|
            px = x + dx
            next if px < 0 || px >= pixels[0].length

            if (row_bits >> (7 - dx)) & 1 == 1
              pixels[py][px] = rgb
            end
          end
        end
      end

      # Get bitmap glyph for a character
      #
      # Returns a 16-element array where each element is an 8-bit row
      #
      # @param char [String] Character
      # @return [Array<Integer>, nil] 16 rows of 8-bit pixel data
      def font_glyph(char)
        FONT_8X16[char.ord] || FONT_8X16[32] # Default to space
      end

      # Encode pixel buffer as PPM P6 format
      #
      # @param pixels [Array<Array<Array>>] Pixel buffer
      # @param width [Integer] Image width
      # @param height [Integer] Image height
      # @return [String] Binary PPM data
      def encode_ppm(pixels, width, height)
        header = "P6\n#{width} #{height}\n255\n"
        data = String.new(encoding: Encoding::BINARY)

        pixels.each do |row|
          row.each do |rgb|
            data << rgb[0].chr << rgb[1].chr << rgb[2].chr
          end
        end

        header + data
      end

      # Embedded 8x16 bitmap font for ASCII characters 32-126
      # Each character is 16 rows of 8-bit pixel data
      FONT_8X16 = {
        32 => [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], # space
        33 => [0x00, 0x00, 0x18, 0x3c, 0x3c, 0x3c, 0x18, 0x18, 0x18, 0x00, 0x18, 0x18, 0x00, 0x00, 0x00, 0x00], # !
        34 => [0x00, 0x66, 0x66, 0x66, 0x24, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], # "
        35 => [0x00, 0x00, 0x00, 0x6c, 0x6c, 0xfe, 0x6c, 0x6c, 0x6c, 0xfe, 0x6c, 0x6c, 0x00, 0x00, 0x00, 0x00], # #
        36 => [0x18, 0x18, 0x7c, 0xc6, 0xc2, 0xc0, 0x7c, 0x06, 0x06, 0x86, 0xc6, 0x7c, 0x18, 0x18, 0x00, 0x00], # $
        37 => [0x00, 0x00, 0x00, 0x00, 0xc2, 0xc6, 0x0c, 0x18, 0x30, 0x60, 0xc6, 0x86, 0x00, 0x00, 0x00, 0x00], # %
        38 => [0x00, 0x00, 0x38, 0x6c, 0x6c, 0x38, 0x76, 0xdc, 0xcc, 0xcc, 0xcc, 0x76, 0x00, 0x00, 0x00, 0x00], # &
        39 => [0x00, 0x30, 0x30, 0x30, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], # '
        40 => [0x00, 0x00, 0x0c, 0x18, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x18, 0x0c, 0x00, 0x00, 0x00, 0x00], # (
        41 => [0x00, 0x00, 0x30, 0x18, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x18, 0x30, 0x00, 0x00, 0x00, 0x00], # )
        42 => [0x00, 0x00, 0x00, 0x00, 0x00, 0x66, 0x3c, 0xff, 0x3c, 0x66, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], # *
        43 => [0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x7e, 0x18, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], # +
        44 => [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x18, 0x30, 0x00, 0x00, 0x00], # ,
        45 => [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfe, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], # -
        46 => [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x00, 0x00, 0x00, 0x00], # .
        47 => [0x00, 0x00, 0x00, 0x00, 0x02, 0x06, 0x0c, 0x18, 0x30, 0x60, 0xc0, 0x80, 0x00, 0x00, 0x00, 0x00], # /
        48 => [0x00, 0x00, 0x7c, 0xc6, 0xc6, 0xce, 0xde, 0xf6, 0xe6, 0xc6, 0xc6, 0x7c, 0x00, 0x00, 0x00, 0x00], # 0
        49 => [0x00, 0x00, 0x18, 0x38, 0x78, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x7e, 0x00, 0x00, 0x00, 0x00], # 1
        50 => [0x00, 0x00, 0x7c, 0xc6, 0x06, 0x0c, 0x18, 0x30, 0x60, 0xc0, 0xc6, 0xfe, 0x00, 0x00, 0x00, 0x00], # 2
        51 => [0x00, 0x00, 0x7c, 0xc6, 0x06, 0x06, 0x3c, 0x06, 0x06, 0x06, 0xc6, 0x7c, 0x00, 0x00, 0x00, 0x00], # 3
        52 => [0x00, 0x00, 0x0c, 0x1c, 0x3c, 0x6c, 0xcc, 0xfe, 0x0c, 0x0c, 0x0c, 0x1e, 0x00, 0x00, 0x00, 0x00], # 4
        53 => [0x00, 0x00, 0xfe, 0xc0, 0xc0, 0xc0, 0xfc, 0x06, 0x06, 0x06, 0xc6, 0x7c, 0x00, 0x00, 0x00, 0x00], # 5
        54 => [0x00, 0x00, 0x38, 0x60, 0xc0, 0xc0, 0xfc, 0xc6, 0xc6, 0xc6, 0xc6, 0x7c, 0x00, 0x00, 0x00, 0x00], # 6
        55 => [0x00, 0x00, 0xfe, 0xc6, 0x06, 0x06, 0x0c, 0x18, 0x30, 0x30, 0x30, 0x30, 0x00, 0x00, 0x00, 0x00], # 7
        56 => [0x00, 0x00, 0x7c, 0xc6, 0xc6, 0xc6, 0x7c, 0xc6, 0xc6, 0xc6, 0xc6, 0x7c, 0x00, 0x00, 0x00, 0x00], # 8
        57 => [0x00, 0x00, 0x7c, 0xc6, 0xc6, 0xc6, 0x7e, 0x06, 0x06, 0x06, 0x0c, 0x78, 0x00, 0x00, 0x00, 0x00], # 9
        58 => [0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x00, 0x00, 0x00, 0x18, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00], # :
        59 => [0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x00, 0x00, 0x00, 0x18, 0x18, 0x30, 0x00, 0x00, 0x00, 0x00], # ;
        60 => [0x00, 0x00, 0x00, 0x06, 0x0c, 0x18, 0x30, 0x60, 0x30, 0x18, 0x0c, 0x06, 0x00, 0x00, 0x00, 0x00], # <
        61 => [0x00, 0x00, 0x00, 0x00, 0x00, 0x7e, 0x00, 0x00, 0x7e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], # =
        62 => [0x00, 0x00, 0x00, 0x60, 0x30, 0x18, 0x0c, 0x06, 0x0c, 0x18, 0x30, 0x60, 0x00, 0x00, 0x00, 0x00], # >
        63 => [0x00, 0x00, 0x7c, 0xc6, 0xc6, 0x0c, 0x18, 0x18, 0x18, 0x00, 0x18, 0x18, 0x00, 0x00, 0x00, 0x00], # ?
        64 => [0x00, 0x00, 0x7c, 0xc6, 0xc6, 0xc6, 0xde, 0xde, 0xde, 0xdc, 0xc0, 0x7c, 0x00, 0x00, 0x00, 0x00], # @
        65 => [0x00, 0x00, 0x10, 0x38, 0x6c, 0xc6, 0xc6, 0xfe, 0xc6, 0xc6, 0xc6, 0xc6, 0x00, 0x00, 0x00, 0x00], # A
        66 => [0x00, 0x00, 0xfc, 0x66, 0x66, 0x66, 0x7c, 0x66, 0x66, 0x66, 0x66, 0xfc, 0x00, 0x00, 0x00, 0x00], # B
        67 => [0x00, 0x00, 0x3c, 0x66, 0xc2, 0xc0, 0xc0, 0xc0, 0xc0, 0xc2, 0x66, 0x3c, 0x00, 0x00, 0x00, 0x00], # C
        68 => [0x00, 0x00, 0xf8, 0x6c, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x6c, 0xf8, 0x00, 0x00, 0x00, 0x00], # D
        69 => [0x00, 0x00, 0xfe, 0x66, 0x62, 0x68, 0x78, 0x68, 0x60, 0x62, 0x66, 0xfe, 0x00, 0x00, 0x00, 0x00], # E
        70 => [0x00, 0x00, 0xfe, 0x66, 0x62, 0x68, 0x78, 0x68, 0x60, 0x60, 0x60, 0xf0, 0x00, 0x00, 0x00, 0x00], # F
        71 => [0x00, 0x00, 0x3c, 0x66, 0xc2, 0xc0, 0xc0, 0xde, 0xc6, 0xc6, 0x66, 0x3a, 0x00, 0x00, 0x00, 0x00], # G
        72 => [0x00, 0x00, 0xc6, 0xc6, 0xc6, 0xc6, 0xfe, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0x00, 0x00, 0x00, 0x00], # H
        73 => [0x00, 0x00, 0x3c, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x3c, 0x00, 0x00, 0x00, 0x00], # I
        74 => [0x00, 0x00, 0x1e, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0xcc, 0xcc, 0xcc, 0x78, 0x00, 0x00, 0x00, 0x00], # J
        75 => [0x00, 0x00, 0xe6, 0x66, 0x66, 0x6c, 0x78, 0x78, 0x6c, 0x66, 0x66, 0xe6, 0x00, 0x00, 0x00, 0x00], # K
        76 => [0x00, 0x00, 0xf0, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x62, 0x66, 0xfe, 0x00, 0x00, 0x00, 0x00], # L
        77 => [0x00, 0x00, 0xc6, 0xee, 0xfe, 0xfe, 0xd6, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0x00, 0x00, 0x00, 0x00], # M
        78 => [0x00, 0x00, 0xc6, 0xe6, 0xf6, 0xfe, 0xde, 0xce, 0xc6, 0xc6, 0xc6, 0xc6, 0x00, 0x00, 0x00, 0x00], # N
        79 => [0x00, 0x00, 0x7c, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0x7c, 0x00, 0x00, 0x00, 0x00], # O
        80 => [0x00, 0x00, 0xfc, 0x66, 0x66, 0x66, 0x7c, 0x60, 0x60, 0x60, 0x60, 0xf0, 0x00, 0x00, 0x00, 0x00], # P
        81 => [0x00, 0x00, 0x7c, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xd6, 0xde, 0x7c, 0x0c, 0x0e, 0x00, 0x00], # Q
        82 => [0x00, 0x00, 0xfc, 0x66, 0x66, 0x66, 0x7c, 0x6c, 0x66, 0x66, 0x66, 0xe6, 0x00, 0x00, 0x00, 0x00], # R
        83 => [0x00, 0x00, 0x7c, 0xc6, 0xc6, 0x60, 0x38, 0x0c, 0x06, 0xc6, 0xc6, 0x7c, 0x00, 0x00, 0x00, 0x00], # S
        84 => [0x00, 0x00, 0x7e, 0x7e, 0x5a, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x3c, 0x00, 0x00, 0x00, 0x00], # T
        85 => [0x00, 0x00, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0x7c, 0x00, 0x00, 0x00, 0x00], # U
        86 => [0x00, 0x00, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0x6c, 0x38, 0x10, 0x00, 0x00, 0x00, 0x00], # V
        87 => [0x00, 0x00, 0xc6, 0xc6, 0xc6, 0xc6, 0xd6, 0xd6, 0xd6, 0xfe, 0xee, 0x6c, 0x00, 0x00, 0x00, 0x00], # W
        88 => [0x00, 0x00, 0xc6, 0xc6, 0x6c, 0x7c, 0x38, 0x38, 0x7c, 0x6c, 0xc6, 0xc6, 0x00, 0x00, 0x00, 0x00], # X
        89 => [0x00, 0x00, 0x66, 0x66, 0x66, 0x66, 0x3c, 0x18, 0x18, 0x18, 0x18, 0x3c, 0x00, 0x00, 0x00, 0x00], # Y
        90 => [0x00, 0x00, 0xfe, 0xc6, 0x86, 0x0c, 0x18, 0x30, 0x60, 0xc2, 0xc6, 0xfe, 0x00, 0x00, 0x00, 0x00], # Z
        91 => [0x00, 0x00, 0x3c, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x3c, 0x00, 0x00, 0x00, 0x00], # [
        92 => [0x00, 0x00, 0x00, 0x80, 0xc0, 0xe0, 0x70, 0x38, 0x1c, 0x0e, 0x06, 0x02, 0x00, 0x00, 0x00, 0x00], # \
        93 => [0x00, 0x00, 0x3c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x3c, 0x00, 0x00, 0x00, 0x00], # ]
        94 => [0x10, 0x38, 0x6c, 0xc6, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], # ^
        95 => [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x00, 0x00], # _
        96 => [0x00, 0x30, 0x18, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], # `
        97 => [0x00, 0x00, 0x00, 0x00, 0x00, 0x78, 0x0c, 0x7c, 0xcc, 0xcc, 0xcc, 0x76, 0x00, 0x00, 0x00, 0x00], # a
        98 => [0x00, 0x00, 0xe0, 0x60, 0x60, 0x78, 0x6c, 0x66, 0x66, 0x66, 0x66, 0x7c, 0x00, 0x00, 0x00, 0x00], # b
        99 => [0x00, 0x00, 0x00, 0x00, 0x00, 0x7c, 0xc6, 0xc0, 0xc0, 0xc0, 0xc6, 0x7c, 0x00, 0x00, 0x00, 0x00], # c
        100 => [0x00, 0x00, 0x1c, 0x0c, 0x0c, 0x3c, 0x6c, 0xcc, 0xcc, 0xcc, 0xcc, 0x76, 0x00, 0x00, 0x00, 0x00], # d
        101 => [0x00, 0x00, 0x00, 0x00, 0x00, 0x7c, 0xc6, 0xfe, 0xc0, 0xc0, 0xc6, 0x7c, 0x00, 0x00, 0x00, 0x00], # e
        102 => [0x00, 0x00, 0x38, 0x6c, 0x64, 0x60, 0xf0, 0x60, 0x60, 0x60, 0x60, 0xf0, 0x00, 0x00, 0x00, 0x00], # f
        103 => [0x00, 0x00, 0x00, 0x00, 0x00, 0x76, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0x7c, 0x0c, 0xcc, 0x78, 0x00], # g
        104 => [0x00, 0x00, 0xe0, 0x60, 0x60, 0x6c, 0x76, 0x66, 0x66, 0x66, 0x66, 0xe6, 0x00, 0x00, 0x00, 0x00], # h
        105 => [0x00, 0x00, 0x18, 0x18, 0x00, 0x38, 0x18, 0x18, 0x18, 0x18, 0x18, 0x3c, 0x00, 0x00, 0x00, 0x00], # i
        106 => [0x00, 0x00, 0x06, 0x06, 0x00, 0x0e, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x66, 0x66, 0x3c, 0x00], # j
        107 => [0x00, 0x00, 0xe0, 0x60, 0x60, 0x66, 0x6c, 0x78, 0x78, 0x6c, 0x66, 0xe6, 0x00, 0x00, 0x00, 0x00], # k
        108 => [0x00, 0x00, 0x38, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x3c, 0x00, 0x00, 0x00, 0x00], # l
        109 => [0x00, 0x00, 0x00, 0x00, 0x00, 0xec, 0xfe, 0xd6, 0xd6, 0xd6, 0xd6, 0xc6, 0x00, 0x00, 0x00, 0x00], # m
        110 => [0x00, 0x00, 0x00, 0x00, 0x00, 0xdc, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x00, 0x00, 0x00, 0x00], # n
        111 => [0x00, 0x00, 0x00, 0x00, 0x00, 0x7c, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0x7c, 0x00, 0x00, 0x00, 0x00], # o
        112 => [0x00, 0x00, 0x00, 0x00, 0x00, 0xdc, 0x66, 0x66, 0x66, 0x66, 0x66, 0x7c, 0x60, 0x60, 0xf0, 0x00], # p
        113 => [0x00, 0x00, 0x00, 0x00, 0x00, 0x76, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0x7c, 0x0c, 0x0c, 0x1e, 0x00], # q
        114 => [0x00, 0x00, 0x00, 0x00, 0x00, 0xdc, 0x76, 0x66, 0x60, 0x60, 0x60, 0xf0, 0x00, 0x00, 0x00, 0x00], # r
        115 => [0x00, 0x00, 0x00, 0x00, 0x00, 0x7c, 0xc6, 0x60, 0x38, 0x0c, 0xc6, 0x7c, 0x00, 0x00, 0x00, 0x00], # s
        116 => [0x00, 0x00, 0x10, 0x30, 0x30, 0xfc, 0x30, 0x30, 0x30, 0x30, 0x36, 0x1c, 0x00, 0x00, 0x00, 0x00], # t
        117 => [0x00, 0x00, 0x00, 0x00, 0x00, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0x76, 0x00, 0x00, 0x00, 0x00], # u
        118 => [0x00, 0x00, 0x00, 0x00, 0x00, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3c, 0x18, 0x00, 0x00, 0x00, 0x00], # v
        119 => [0x00, 0x00, 0x00, 0x00, 0x00, 0xc6, 0xc6, 0xd6, 0xd6, 0xd6, 0xfe, 0x6c, 0x00, 0x00, 0x00, 0x00], # w
        120 => [0x00, 0x00, 0x00, 0x00, 0x00, 0xc6, 0x6c, 0x38, 0x38, 0x38, 0x6c, 0xc6, 0x00, 0x00, 0x00, 0x00], # x
        121 => [0x00, 0x00, 0x00, 0x00, 0x00, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0x7e, 0x06, 0x0c, 0xf8, 0x00], # y
        122 => [0x00, 0x00, 0x00, 0x00, 0x00, 0xfe, 0xcc, 0x18, 0x30, 0x60, 0xc6, 0xfe, 0x00, 0x00, 0x00, 0x00], # z
        123 => [0x00, 0x00, 0x0e, 0x18, 0x18, 0x18, 0x70, 0x18, 0x18, 0x18, 0x18, 0x0e, 0x00, 0x00, 0x00, 0x00], # {
        124 => [0x00, 0x00, 0x18, 0x18, 0x18, 0x18, 0x00, 0x18, 0x18, 0x18, 0x18, 0x18, 0x00, 0x00, 0x00, 0x00], # |
        125 => [0x00, 0x00, 0x70, 0x18, 0x18, 0x18, 0x0e, 0x18, 0x18, 0x18, 0x18, 0x70, 0x00, 0x00, 0x00, 0x00], # }
        126 => [0x00, 0x00, 0x76, 0xdc, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], # ~

        # Unicode block elements (for progress bars)
        0x2588 => [0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff], # █ Full block
        0x2591 => [0x22, 0x88, 0x22, 0x88, 0x22, 0x88, 0x22, 0x88, 0x22, 0x88, 0x22, 0x88, 0x22, 0x88, 0x22, 0x88], # ░ Light shade
        0x2592 => [0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa], # ▒ Medium shade
        0x2593 => [0x77, 0xdd, 0x77, 0xdd, 0x77, 0xdd, 0x77, 0xdd, 0x77, 0xdd, 0x77, 0xdd, 0x77, 0xdd, 0x77, 0xdd], # ▓ Dark shade

        # Unicode box-drawing characters (for tables/panels)
        0x2500 => [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], # ─ Horizontal
        0x2502 => [0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18], # │ Vertical
        0x250c => [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18], # ┌ Down and right
        0x2510 => [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf8, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18], # ┐ Down and left
        0x2514 => [0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x1f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], # └ Up and right
        0x2518 => [0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0xf8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], # ┘ Up and left
        0x251c => [0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x1f, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18], # ├ Vertical and right
        0x2524 => [0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0xf8, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18], # ┤ Vertical and left
        0x252c => [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18], # ┬ Horizontal and down
        0x2534 => [0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], # ┴ Horizontal and up
        0x253c => [0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0xff, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18], # ┼ Cross

        # Double-line box characters
        0x2550 => [0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x00, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], # ═ Double horizontal
        0x2551 => [0x6c, 0x6c, 0x6c, 0x6c, 0x6c, 0x6c, 0x6c, 0x6c, 0x6c, 0x6c, 0x6c, 0x6c, 0x6c, 0x6c, 0x6c, 0x6c], # ║ Double vertical
        0x2554 => [0x00, 0x00, 0x00, 0x00, 0x00, 0x7f, 0x60, 0x6f, 0x6c, 0x6c, 0x6c, 0x6c, 0x6c, 0x6c, 0x6c, 0x6c], # ╔ Double down and right
        0x2557 => [0x00, 0x00, 0x00, 0x00, 0x00, 0xfc, 0x0c, 0xec, 0x6c, 0x6c, 0x6c, 0x6c, 0x6c, 0x6c, 0x6c, 0x6c], # ╗ Double down and left
        0x255a => [0x6c, 0x6c, 0x6c, 0x6c, 0x6c, 0x6f, 0x60, 0x7f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], # ╚ Double up and right
        0x255d => [0x6c, 0x6c, 0x6c, 0x6c, 0x6c, 0xec, 0x0c, 0xfc, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], # ╝ Double up and left

        # Arrows and symbols
        0x2190 => [0x00, 0x00, 0x00, 0x00, 0x10, 0x30, 0x7f, 0xff, 0x7f, 0x30, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00], # ← Left arrow
        0x2192 => [0x00, 0x00, 0x00, 0x00, 0x08, 0x0c, 0xfe, 0xff, 0xfe, 0x0c, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00], # → Right arrow
        0x2713 => [0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x06, 0xcc, 0x78, 0x30, 0x00, 0x00, 0x00, 0x00, 0x00], # ✓ Check mark
        0x2717 => [0x00, 0x00, 0x00, 0xc6, 0xee, 0x7c, 0x38, 0x38, 0x7c, 0xee, 0xc6, 0x00, 0x00, 0x00, 0x00, 0x00], # ✗ X mark
        0x25b6 => [0x00, 0x00, 0xc0, 0xf0, 0xfc, 0xff, 0xff, 0xff, 0xfc, 0xf0, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00], # ▶ Right-pointing triangle
      }.freeze

      # Render a single frame to SVG format
      #
      # @param lines [Array<ParsedLine>] Parsed ANSI lines
      # @param term_width [Integer] Terminal width
      # @param term_height [Integer] Terminal height
      # @param theme [Themes::Theme] Color theme
      # @param options [Hash] Rendering options
      # @return [String] SVG content
      def render_frame_svg(lines, term_width, term_height, theme,
                           char_width:, char_height:, padding:, title_bar_height:,
                           svg_width:, svg_height:, font_size:)
        # Build SVG content
        svg_content = StringIO.new

        # Render each line
        lines.each_with_index do |line, y|
          y_pos = padding + title_bar_height + (y + 1) * char_height

          x = 0
          while x < line.chars.length
            char_data = line.chars[x]

            # Find run of characters with same style
            run_start = x
            while x < line.chars.length && line.chars[x].same_style?(char_data)
              x += 1
            end

            # Build text content
            text = line.chars[run_start...x].map(&:char).join
            next if text.match?(/^\s*$/) && char_data.default_style?

            # Calculate position
            x_pos = padding + run_start * char_width

            # Build style attributes
            styles = []
            fill = resolve_fg_color(char_data.fg, theme)
            styles << "fill:#{fill}" if fill != theme.foreground

            bg = resolve_bg_color(char_data.bg, theme)
            if bg && bg != theme.background
              # Add background rectangle
              bg_width = (x - run_start) * char_width
              svg_content << %(<rect x="#{x_pos}" y="#{y_pos - char_height + 4}" width="#{bg_width}" height="#{char_height}" fill="#{bg}"/>)
              svg_content << "\n"
            end

            styles << "font-weight:bold" if char_data.bold
            styles << "font-style:italic" if char_data.italic

            style_attr = styles.empty? ? "" : %( style="#{styles.join(";")}")

            # Escape text for XML
            escaped = text.gsub("&", "&amp;")
                          .gsub("<", "&lt;")
                          .gsub(">", "&gt;")
                          .gsub("'", "&apos;")
                          .gsub('"', "&quot;")

            # Add decorations
            decorations = []
            decorations << "underline" if char_data.underline
            decorations << "line-through" if char_data.strikethrough
            dec_attr = decorations.empty? ? "" : %( text-decoration="#{decorations.join(" ")}")

            svg_content << %(<text x="#{x_pos}" y="#{y_pos}" class="t"#{style_attr}#{dec_attr}>#{escaped}</text>)
            svg_content << "\n"
          end
        end

        # Window button colors
        close_color = "#ff5f56"
        minimize_color = "#ffbd2e"
        maximize_color = "#27c93f"
        border_radius = (8 * (svg_height.to_f / 600)).ceil

        <<~SVG
          <?xml version="1.0" encoding="UTF-8"?>
          <svg xmlns="http://www.w3.org/2000/svg" width="#{svg_width}" height="#{svg_height}" viewBox="0 0 #{svg_width} #{svg_height}">
            <defs>
              <style>
                .bg { fill: #{theme.background}; }
                .title-bar { fill: #{darken_color(theme.background, 0.15)}; }
                .t {
                  font-family: "Cascadia Code", "Fira Code", "Consolas", "Monaco", "Courier New", monospace;
                  font-size: #{font_size}px;
                  fill: #{theme.foreground};
                  white-space: pre;
                }
              </style>
            </defs>

            <!-- Window frame -->
            <rect class="bg" width="100%" height="100%" rx="#{border_radius}"/>

            <!-- Title bar -->
            <rect class="title-bar" width="100%" height="#{title_bar_height}" rx="#{border_radius}" ry="#{border_radius}"/>
            <rect class="title-bar" y="#{border_radius}" width="100%" height="#{title_bar_height - border_radius}"/>

            <!-- Window buttons -->
            <circle cx="#{20 * (svg_width.to_f / 800)}" cy="#{title_bar_height / 2}" r="#{6 * (svg_height.to_f / 600)}" fill="#{close_color}"/>
            <circle cx="#{40 * (svg_width.to_f / 800)}" cy="#{title_bar_height / 2}" r="#{6 * (svg_height.to_f / 600)}" fill="#{minimize_color}"/>
            <circle cx="#{60 * (svg_width.to_f / 800)}" cy="#{title_bar_height / 2}" r="#{6 * (svg_height.to_f / 600)}" fill="#{maximize_color}"/>

            <!-- Terminal content -->
            <g class="terminal">
          #{svg_content.string}    </g>
          </svg>
        SVG
      end

      # Use FFmpeg to create video from PPM frames
      #
      # PPM is a simple image format that FFmpeg reads natively without
      # any special decoders. For GIF, uses 2-pass palette generation
      # for optimal color quality.
      #
      # @param temp_dir [String] Directory containing frame PPM files
      # @param output_path [String] Output video file path
      # @param format [Symbol] Video format (:gif, :mp4, :webm)
      # @param fps [Integer] Frames per second
      # @param loop_count [Integer] GIF loop count (-1=infinite)
      # @return [void]
      def ffmpeg_create_video(temp_dir, output_path, format:, fps:, loop_count: -1)
        ffmpeg = ENV["FFMPEG_PATH"] || "ffmpeg"
        input_pattern = File.join(temp_dir, "frame_%04d.ppm").gsub("\\", "/")
        palette_path = File.join(temp_dir, "palette.png").gsub("\\", "/")
        output = output_path.gsub("\\", "/")

        case format
        when :gif
          # 2-pass palette-based GIF creation for optimal quality
          # Pass 1: Generate optimal palette from all frames
          cmd1 = [
            ffmpeg, "-y",
            "-framerate", fps.to_s,
            "-i", input_pattern,
            "-vf", "palettegen=stats_mode=diff:max_colors=256",
            palette_path
          ]

          success1 = system(*cmd1, out: File::NULL, err: File::NULL)
          unless success1
            raise ExportError, "FFmpeg palette generation failed"
          end

          # Pass 2: Encode GIF using the palette
          loop_opt = loop_count < 0 ? "0" : loop_count.to_s # 0 = infinite loop in GIF
          cmd2 = [
            ffmpeg, "-y",
            "-framerate", fps.to_s,
            "-i", input_pattern,
            "-i", palette_path,
            "-lavfi", "paletteuse=dither=sierra2_4a:diff_mode=rectangle",
            "-loop", loop_opt,
            output
          ]

          success2 = system(*cmd2, out: File::NULL, err: File::NULL)
          unless success2
            raise ExportError, "FFmpeg GIF encoding failed"
          end

        when :mp4
          # H.264 encoding with good compatibility settings
          cmd = [
            ffmpeg, "-y",
            "-framerate", fps.to_s,
            "-i", input_pattern,
            "-c:v", "libx264",
            "-preset", "medium",
            "-crf", "23",
            "-pix_fmt", "yuv420p",
            "-movflags", "+faststart",
            output
          ]

          success = system(*cmd, out: File::NULL, err: File::NULL)
          unless success
            raise ExportError, "FFmpeg MP4 encoding failed"
          end

        when :webm
          # VP9 encoding for WebM
          cmd = [
            ffmpeg, "-y",
            "-framerate", fps.to_s,
            "-i", input_pattern,
            "-c:v", "libvpx-vp9",
            "-crf", "30",
            "-b:v", "0",
            "-pix_fmt", "yuv420p",
            output
          ]

          success = system(*cmd, out: File::NULL, err: File::NULL)
          unless success
            raise ExportError, "FFmpeg WebM encoding failed"
          end

        else
          raise ExportError, "Unsupported video format: #{format}"
        end
      end
    end
  end
end

