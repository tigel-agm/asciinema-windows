# frozen_string_literal: true

module AsciinemaWin
  # Command-line interface for asciinema-win
  #
  # Provides commands for recording, playing back, and inspecting
  # terminal recordings. Uses only Ruby standard library for argument
  # parsing (no external gems).
  #
  # @example Run the CLI
  #   AsciinemaWin::CLI.run(ARGV)
  class CLI
    # Available commands
    COMMANDS = %w[rec play cat info export help version].freeze

    # ANSI color codes for output
    module Colors
      RESET = "\e[0m"
      BOLD = "\e[1m"
      RED = "\e[31m"
      GREEN = "\e[32m"
      YELLOW = "\e[33m"
      BLUE = "\e[34m"
      CYAN = "\e[36m"
    end

    # Run the CLI with the given arguments
    #
    # @param args [Array<String>] Command-line arguments
    # @return [Integer] Exit code
    def self.run(args)
      new.run(args)
    end

    # Run the CLI
    #
    # @param args [Array<String>] Command-line arguments
    # @return [Integer] Exit code
    def run(args)
      if args.empty?
        print_usage
        return 0
      end

      command = args.shift

      case command
      when "rec", "record"
        cmd_rec(args)
      when "play"
        cmd_play(args)
      when "cat"
        cmd_cat(args)
      when "info"
        cmd_info(args)
      when "export"
        cmd_export(args)
      when "help", "-h", "--help"
        cmd_help(args)
      when "version", "-v", "--version"
        cmd_version
      else
        error("Unknown command: #{command}")
        print_usage
        1
      end
    rescue StandardError => e
      error(e.message)
      error(e.backtrace.first(5).join("\n")) if ENV["DEBUG"]
      1
    end

    private

    # =========================================================================
    # Commands
    # =========================================================================

    # Record command
    #
    # @param args [Array<String>] Command arguments
    # @return [Integer] Exit code
    def cmd_rec(args)
      options = parse_options(args, {
        "t" => :title,
        "title" => :title,
        "c" => :command,
        "command" => :command,
        "i" => :idle_time_limit,
        "idle-time-limit" => :idle_time_limit,
        "y" => :overwrite,
        "overwrite" => :overwrite
      })

      output_path = args.shift

      unless output_path
        error("Missing output file path")
        puts "Usage: asciinema_win rec [options] <filename>"
        return 1
      end

      # Check if file exists and overwrite not set
      if File.exist?(output_path) && !options[:overwrite]
        error("File already exists: #{output_path}")
        puts "Use -y or --overwrite to overwrite"
        return 1
      end

      # Create recorder
      recorder = Recorder.new(
        title: options[:title],
        command: options[:command],
        idle_time_limit: options[:idle_time_limit]&.to_f || Recorder::DEFAULT_IDLE_TIME_LIMIT
      )

      # Start recording
      stats = recorder.record(output_path)

      success("Recording saved to #{output_path}")
      puts "Duration: #{format("%.2f", stats[:duration])}s"
      puts "Events: #{stats[:event_count]}"

      0
    end

    # Play command
    #
    # @param args [Array<String>] Command arguments
    # @return [Integer] Exit code
    def cmd_play(args)
      options = parse_options(args, {
        "s" => :speed,
        "speed" => :speed,
        "i" => :idle_time_limit,
        "idle-time-limit" => :idle_time_limit,
        "m" => :pause_on_markers,
        "pause-on-markers" => :pause_on_markers
      })

      input_path = args.shift

      unless input_path
        error("Missing input file path")
        puts "Usage: asciinema_win play [options] <filename>"
        return 1
      end

      unless File.exist?(input_path)
        error("File not found: #{input_path}")
        return 1
      end

      # Create player
      player = Player.new(
        speed: options[:speed]&.to_f || 1.0,
        idle_time_limit: options[:idle_time_limit]&.to_f,
        pause_on_markers: !!options[:pause_on_markers]
      )

      # Start playback
      player.play(input_path)

      0
    end

    # Cat command (output without timing)
    #
    # @param args [Array<String>] Command arguments
    # @return [Integer] Exit code
    def cmd_cat(args)
      input_path = args.shift

      unless input_path
        error("Missing input file path")
        puts "Usage: asciinema_win cat <filename>"
        return 1
      end

      unless File.exist?(input_path)
        error("File not found: #{input_path}")
        return 1
      end

      # Use raw player for immediate output
      player = RawPlayer.new
      player.play(input_path)

      0
    end

    # Info command
    #
    # @param args [Array<String>] Command arguments
    # @return [Integer] Exit code
    def cmd_info(args)
      input_path = args.shift

      unless input_path
        error("Missing input file path")
        puts "Usage: asciinema_win info <filename>"
        return 1
      end

      unless File.exist?(input_path)
        error("File not found: #{input_path}")
        return 1
      end

      # Get info
      info_data = Asciicast::Reader.info(input_path)

      # Print info
      puts "#{Colors::BOLD}File:#{Colors::RESET} #{input_path}"
      puts "#{Colors::BOLD}Version:#{Colors::RESET} #{info_data[:version]}"
      puts "#{Colors::BOLD}Size:#{Colors::RESET} #{info_data[:width]}x#{info_data[:height]}"
      puts "#{Colors::BOLD}Duration:#{Colors::RESET} #{format("%.2f", info_data[:duration])}s"
      puts "#{Colors::BOLD}Events:#{Colors::RESET} #{info_data[:event_count]}"

      if info_data[:title]
        puts "#{Colors::BOLD}Title:#{Colors::RESET} #{info_data[:title]}"
      end

      if info_data[:command]
        puts "#{Colors::BOLD}Command:#{Colors::RESET} #{info_data[:command]}"
      end

      if info_data[:timestamp]
        time = Time.at(info_data[:timestamp])
        puts "#{Colors::BOLD}Recorded:#{Colors::RESET} #{time.strftime("%Y-%m-%d %H:%M:%S")}"
      end

      if info_data[:idle_time_limit]
        puts "#{Colors::BOLD}Idle limit:#{Colors::RESET} #{info_data[:idle_time_limit]}s"
      end

      unless info_data[:env].empty?
        puts "#{Colors::BOLD}Environment:#{Colors::RESET}"
        info_data[:env].each do |key, value|
          puts "  #{key}=#{value}"
        end
      end

      0
    end

    # Export command
    #
    # @param args [Array<String>] Command arguments
    # @return [Integer] Exit code
    def cmd_export(args)
      options = parse_options(args, {
        "f" => :format,
        "format" => :format,
        "o" => :output,
        "output" => :output,
        "t" => :title,
        "title" => :title,
        "fps" => :fps,
        "theme" => :theme,
        "scale" => :scale
      })

      input_path = args.shift

      unless input_path
        error("Missing input file path")
        puts "Usage: asciinema_win export [options] <input.cast> [-o output]"
        return 1
      end

      unless File.exist?(input_path)
        error("File not found: #{input_path}")
        return 1
      end

      # Determine format from output extension or option
      output_path = options[:output]
      format = options[:format]&.to_sym

      unless output_path
        # Default output based on format
        format ||= :html
        ext = format == :text ? ".txt" : ".#{format}"
        output_path = input_path.sub(/\.cast$/, ext)
      end

      unless format
        # Infer from output extension
        ext = File.extname(output_path).downcase
        format = case ext
                 when ".html" then :html
                 when ".svg" then :svg
                 when ".txt" then :text
                 when ".json" then :json
                 when ".gif" then :gif
                 when ".mp4" then :mp4
                 when ".webm" then :webm
                 else :html
                 end
      end

      puts "Exporting #{input_path} to #{output_path} (#{format})..."

      # Build export options
      export_opts = { format: format, title: options[:title] }
      export_opts[:fps] = options[:fps].to_i if options[:fps]
      export_opts[:theme] = options[:theme] if options[:theme]
      export_opts[:scale] = options[:scale].to_f if options[:scale]

      Export.export(input_path, output_path, **export_opts)

      success("Exported to #{output_path}")
      0
    rescue ExportError => e
      error(e.message)
      1
    end

    # Help command
    #
    # @param args [Array<String>] Command arguments
    # @return [Integer] Exit code
    def cmd_help(args)
      command = args.shift

      case command
      when "rec", "record"
        print_rec_help
      when "play"
        print_play_help
      when "cat"
        print_cat_help
      when "info"
        print_info_help
      when "export"
        print_export_help
      else
        print_usage
      end

      0
    end

    # Version command
    #
    # @return [Integer] Exit code
    def cmd_version
      puts "asciinema-win #{VERSION}"
      puts "Ruby #{RUBY_VERSION} (#{RUBY_PLATFORM})"
      0
    end

    # =========================================================================
    # Option Parsing
    # =========================================================================

    # Parse command-line options
    #
    # @param args [Array<String>] Arguments (modified in place)
    # @param valid_options [Hash] Map of option names to symbols
    # @return [Hash] Parsed options
    def parse_options(args, valid_options)
      options = {}
      remaining = []

      i = 0
      while i < args.length
        arg = args[i]

        if arg.start_with?("--")
          # Long option
          key = arg[2..]
          if key.include?("=")
            key, value = key.split("=", 2)
          else
            value = nil
          end

          sym = valid_options[key]
          if sym
            if value.nil? && i + 1 < args.length && !args[i + 1].start_with?("-")
              i += 1
              value = args[i]
            end
            options[sym] = value || true
          else
            remaining << arg
          end
        elsif arg.start_with?("-") && arg.length > 1
          # Short option
          key = arg[1]
          value = arg.length > 2 ? arg[2..] : nil

          sym = valid_options[key]
          if sym
            if value.nil? && i + 1 < args.length && !args[i + 1].start_with?("-")
              i += 1
              value = args[i]
            end
            options[sym] = value || true
          else
            remaining << arg
          end
        else
          remaining << arg
        end

        i += 1
      end

      args.replace(remaining)
      options
    end

    # =========================================================================
    # Help Text
    # =========================================================================

    # Print main usage
    def print_usage
      puts <<~USAGE
        #{Colors::BOLD}asciinema-win#{Colors::RESET} - Native Windows terminal recorder

        #{Colors::BOLD}USAGE:#{Colors::RESET}
            asciinema_win <command> [options]

        #{Colors::BOLD}COMMANDS:#{Colors::RESET}
            rec      Record terminal session
            play     Play back a recording
            cat      Output recording to stdout (no timing)
            info     Show recording metadata
            export   Export to HTML, SVG, text, or video
            help     Show help for a command
            version  Show version information

        #{Colors::BOLD}EXAMPLES:#{Colors::RESET}
            asciinema_win rec session.cast
            asciinema_win rec -c "dir /s" output.cast
            asciinema_win play session.cast
            asciinema_win play -s 2 session.cast
            asciinema_win info session.cast

        #{Colors::BOLD}OPTIONS:#{Colors::RESET}
            -h, --help     Show help
            -v, --version  Show version

        Run 'asciinema_win help <command>' for command-specific help.
      USAGE
    end

    # Print rec command help
    def print_rec_help
      puts <<~HELP
        #{Colors::BOLD}asciinema_win rec#{Colors::RESET} - Record terminal session

        #{Colors::BOLD}USAGE:#{Colors::RESET}
            asciinema_win rec [options] <filename>

        #{Colors::BOLD}DESCRIPTION:#{Colors::RESET}
            Record terminal session and save it to a file. Press Ctrl+D to stop
            recording. The recording is saved in asciicast v2 format, compatible
            with asciinema.org.

        #{Colors::BOLD}OPTIONS:#{Colors::RESET}
            -t, --title <title>     Recording title
            -c, --command <cmd>     Record specific command instead of interactive session
            -i, --idle-time-limit   Maximum idle time between events (default: 2.0s)
            -y, --overwrite         Overwrite existing file

        #{Colors::BOLD}EXAMPLES:#{Colors::RESET}
            asciinema_win rec demo.cast
            asciinema_win rec -t "My Demo" demo.cast
            asciinema_win rec -c "ping localhost" network.cast
            asciinema_win rec -i 1.0 fast.cast
      HELP
    end

    # Print play command help
    def print_play_help
      puts <<~HELP
        #{Colors::BOLD}asciinema_win play#{Colors::RESET} - Play back a recording

        #{Colors::BOLD}USAGE:#{Colors::RESET}
            asciinema_win play [options] <filename>

        #{Colors::BOLD}DESCRIPTION:#{Colors::RESET}
            Play back a terminal recording with accurate timing. Press Ctrl+C
            to stop playback.

        #{Colors::BOLD}OPTIONS:#{Colors::RESET}
            -s, --speed <factor>       Playback speed (default: 1.0)
            -i, --idle-time-limit <s>  Max idle time between frames
            -m, --pause-on-markers     Pause at marker events

        #{Colors::BOLD}EXAMPLES:#{Colors::RESET}
            asciinema_win play demo.cast
            asciinema_win play -s 2 demo.cast      # 2x speed
            asciinema_win play -s 0.5 demo.cast    # Half speed
            asciinema_win play -i 0.5 demo.cast    # Max 0.5s idle
      HELP
    end

    # Print cat command help
    def print_cat_help
      puts <<~HELP
        #{Colors::BOLD}asciinema_win cat#{Colors::RESET} - Output recording to stdout

        #{Colors::BOLD}USAGE:#{Colors::RESET}
            asciinema_win cat <filename>

        #{Colors::BOLD}DESCRIPTION:#{Colors::RESET}
            Output the recording to stdout without timing. Useful for piping
            to other tools or capturing the final output.

        #{Colors::BOLD}EXAMPLES:#{Colors::RESET}
            asciinema_win cat demo.cast
            asciinema_win cat demo.cast | more
            asciinema_win cat demo.cast > output.txt
      HELP
    end

    # Print info command help
    def print_info_help
      puts <<~HELP
        #{Colors::BOLD}asciinema_win info#{Colors::RESET} - Show recording metadata

        #{Colors::BOLD}USAGE:#{Colors::RESET}
            asciinema_win info <filename>

        #{Colors::BOLD}DESCRIPTION:#{Colors::RESET}
            Display metadata about a recording, including duration, dimensions,
            title, and environment variables.

        #{Colors::BOLD}EXAMPLES:#{Colors::RESET}
            asciinema_win info demo.cast
      HELP
    end

    # Print export command help
    def print_export_help
      puts <<~HELP
        #{Colors::BOLD}asciinema_win export#{Colors::RESET} - Export recording to other formats

        #{Colors::BOLD}USAGE:#{Colors::RESET}
            asciinema_win export [options] <filename>

        #{Colors::BOLD}DESCRIPTION:#{Colors::RESET}
            Export a recording to different formats. Native formats (cast, HTML,
            SVG, text, JSON) require no external dependencies. Video formats
            (GIF, MP4, WebM) require FFmpeg to be installed.

        #{Colors::BOLD}FORMATS:#{Colors::RESET}
            cast   asciicast v2 (copy or transform)
            html   Standalone HTML with embedded asciinema-player
            svg    SVG image (static snapshot)
            txt    Plain text (ANSI codes stripped)
            json   Normalized JSON format
            gif    Animated GIF (requires FFmpeg)
            mp4    MP4 video (requires FFmpeg)
            webm   WebM video (requires FFmpeg)

        #{Colors::BOLD}OPTIONS:#{Colors::RESET}
            -f, --format <fmt>    Output format (default: inferred from extension)
            -o, --output <file>   Output file path
            -t, --title <title>   Title for HTML export or cast transform
            --fps <n>             Frames per second for video export (default: 10)
            --theme <name>        Color theme (asciinema, dracula, monokai, etc.)
            --scale <n>           Scale factor for video output (default: 1.0)

        #{Colors::BOLD}EXAMPLES:#{Colors::RESET}
            asciinema_win export demo.cast -o demo.html
            asciinema_win export demo.cast -f svg -o preview.svg
            asciinema_win export demo.cast -f gif -o demo.gif --fps 15
            asciinema_win export demo.cast -f cast -t "New Title" -o renamed.cast
      HELP
    end

    # =========================================================================
    # Output Helpers
    # =========================================================================

    # Print error message
    #
    # @param message [String] Error message
    def error(message)
      $stderr.puts "#{Colors::RED}Error:#{Colors::RESET} #{message}"
    end

    # Print success message
    #
    # @param message [String] Success message
    def success(message)
      puts "#{Colors::GREEN}#{message}#{Colors::RESET}"
    end

    # Print warning message
    #
    # @param message [String] Warning message
    def warning(message)
      puts "#{Colors::YELLOW}Warning:#{Colors::RESET} #{message}"
    end
  end
end
