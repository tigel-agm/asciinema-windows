# frozen_string_literal: true

module AsciinemaWin
  # Terminal session player for Windows
  #
  # Plays back asciicast v2 recordings with accurate timing,
  # using Rich-Ruby for terminal output rendering. Supports
  # speed control, idle time limiting, and interactive controls.
  #
  # @example Basic playback
  #   player = AsciinemaWin::Player.new
  #   player.play("session.cast")
  #
  # @example Fast playback
  #   player = AsciinemaWin::Player.new(speed: 2.0)
  #   player.play("session.cast")
  #
  # @example With idle time limit
  #   player = AsciinemaWin::Player.new(idle_time_limit: 1.0)
  #   player.play("session.cast")
  class Player
    # @return [Float] Playback speed multiplier
    attr_reader :speed

    # @return [Float, nil] Maximum idle time between frames
    attr_reader :idle_time_limit

    # @return [Float, nil] Alternative max idle time setting
    attr_reader :max_idle_time

    # @return [Boolean] Whether to pause at markers
    attr_reader :pause_on_markers

    # @return [Symbol] Current playback state (:idle, :playing, :paused, :stopped)
    attr_reader :state

    # @return [Float] Current playback position in seconds
    attr_reader :position

    # Create a new player
    #
    # @param speed [Float] Playback speed multiplier (1.0 = normal)
    # @param idle_time_limit [Float, nil] Cap idle time from recording header
    # @param max_idle_time [Float, nil] Override max idle time between frames
    # @param pause_on_markers [Boolean] Pause playback at marker events
    def initialize(
      speed: 1.0,
      idle_time_limit: nil,
      max_idle_time: nil,
      pause_on_markers: false
    )
      @speed = speed.to_f
      @speed = 1.0 if @speed <= 0

      @idle_time_limit = idle_time_limit&.to_f
      @max_idle_time = max_idle_time&.to_f
      @pause_on_markers = pause_on_markers

      @state = :idle
      @position = 0.0
      @reader = nil
      @header = nil
    end

    # Play a recording from a file
    #
    # @param input_path [String] Path to the recording file
    # @return [void]
    # @raise [FormatError] If file format is invalid
    # @raise [PlaybackError] If playback fails
    def play(input_path)
      raise PlaybackError, "Already playing" if @state == :playing

      File.open(input_path, "r", encoding: "UTF-8") do |file|
        @reader = Asciicast::Reader.new(file)
        @header = @reader.header
        @state = :playing
        @position = 0.0

        begin
          setup_terminal
          play_events
        ensure
          restore_terminal
          @state = :stopped
        end
      end
    end

    # Play from an IO stream
    #
    # @param io [IO] Input stream
    # @return [void]
    def play_stream(io)
      raise PlaybackError, "Already playing" if @state == :playing

      @reader = Asciicast::Reader.new(io)
      @header = @reader.header
      @state = :playing
      @position = 0.0

      begin
        setup_terminal
        play_events
      ensure
        restore_terminal
        @state = :stopped
      end
    end

    # Pause playback
    #
    # @return [void]
    def pause
      return unless @state == :playing

      @state = :paused
    end

    # Resume playback after pause
    #
    # @return [void]
    def resume
      return unless @state == :paused

      @state = :playing
    end

    # Stop playback
    #
    # @return [void]
    def stop
      @state = :stopped
    end

    # Set playback speed
    #
    # @param multiplier [Float] New speed multiplier
    # @return [void]
    def set_speed(multiplier)
      @speed = [multiplier.to_f, 0.1].max
    end

    # Get recording info without playing
    #
    # @param input_path [String] Path to recording file
    # @return [Hash] Recording metadata
    def info(input_path)
      Asciicast::Reader.info(input_path)
    end

    private

    # Set up terminal for playback
    #
    # @return [void]
    def setup_terminal
      return unless @header

      # Enable ANSI on Windows
      if Gem.win_platform? && defined?(Rich::Win32Console)
        Rich::Win32Console.enable_ansi!
      end

      # Clear screen and move cursor to home
      print "\e[2J"  # Clear screen
      print "\e[H"   # Move to home

      # Hide cursor during playback
      print "\e[?25l"

      # Print playback info if verbose
      if ENV["DEBUG"]
        $stderr.puts "Playing: #{@header.title || "Untitled"}"
        $stderr.puts "Size: #{@header.width}x#{@header.height}"
        $stderr.puts "Speed: #{@speed}x"
      end
    end

    # Restore terminal to normal state
    #
    # @return [void]
    def restore_terminal
      # Reset colors and attributes
      print "\e[0m"

      # Show cursor
      print "\e[?25h"

      # Move to new line
      puts

      # Flush output
      $stdout.flush
    end

    # Play all events from the recording
    #
    # @return [void]
    def play_events
      last_time = 0.0
      effective_idle_limit = calculate_idle_limit

      @reader.each_event do |event|
        break if @state == :stopped

        # Handle pause state
        while @state == :paused
          sleep(0.1)
          break if @state == :stopped
        end

        break if @state == :stopped

        # Calculate delay
        delay = event.time - last_time

        # Apply idle time limit
        if effective_idle_limit && delay > effective_idle_limit
          delay = effective_idle_limit
        end

        # Apply speed multiplier
        delay /= @speed unless @speed == Float::INFINITY

        # Wait for appropriate time
        wait_for_event(delay) if delay > 0

        # Update position
        @position = event.time
        last_time = event.time

        # Process event
        process_event(event)
      end
    end

    # Calculate effective idle time limit
    #
    # @return [Float, nil] Effective idle limit
    def calculate_idle_limit
      # Priority: explicit max_idle_time > idle_time_limit > header value
      @max_idle_time ||
        @idle_time_limit ||
        @header&.idle_time_limit
    end

    # Wait for the specified duration (interruptible)
    #
    # @param seconds [Float] Time to wait
    # @return [void]
    def wait_for_event(seconds)
      return if seconds <= 0 || @speed == Float::INFINITY

      # Use small sleep intervals to allow interruption
      remaining = seconds

      while remaining > 0 && @state == :playing
        sleep_time = [remaining, 0.05].min
        sleep(sleep_time)
        remaining -= sleep_time
      end
    end

    # Process a single event
    #
    # @param event [Asciicast::Event] Event to process
    # @return [void]
    def process_event(event)
      case event.type
      when Asciicast::EventType::OUTPUT
        render_output(event.data)
      when Asciicast::EventType::RESIZE
        handle_resize(event)
      when Asciicast::EventType::MARKER
        handle_marker(event)
      when Asciicast::EventType::INPUT
        # Input events are typically not played back
        nil
      end
    end

    # Render output data to terminal
    #
    # @param data [String] Output data (may contain ANSI sequences)
    # @return [void]
    def render_output(data)
      # Write directly to stdout, preserving ANSI sequences
      print data
      $stdout.flush
    end

    # Handle resize event
    #
    # @param event [Asciicast::Event] Resize event
    # @return [void]
    def handle_resize(event)
      dimensions = event.resize_dimensions
      return unless dimensions

      width, height = dimensions

      # Note: We can't actually resize the terminal, but we could
      # adjust our rendering or warn the user if sizes don't match
      if ENV["DEBUG"]
        $stderr.puts "Resize: #{width}x#{height}"
      end
    end

    # Handle marker event
    #
    # @param event [Asciicast::Event] Marker event
    # @return [void]
    def handle_marker(event)
      return unless @pause_on_markers

      label = event.data.empty? ? "marker" : event.data
      $stderr.puts "\n[Marker: #{label}] Press Enter to continue..."

      # Pause and wait for input
      @state = :paused
      $stdin.gets
      @state = :playing
    end
  end

  # Simple output mode - outputs recording to stdout without timing
  # Used by the `cat` command for piping to other tools
  class RawPlayer < Player
    def initialize
      super(speed: Float::INFINITY)
    end

    private

    def setup_terminal
      # No setup needed for raw output
    end

    def restore_terminal
      # No restore needed
    end

    def wait_for_event(_seconds)
      # No waiting in raw mode
    end
  end
end
