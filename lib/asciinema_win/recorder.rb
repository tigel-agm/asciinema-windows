# frozen_string_literal: true

require "io/console"

module AsciinemaWin
  # Terminal session recorder for Windows
  #
  # Captures terminal output by periodically sampling the screen buffer
  # and detecting changes between frames. Produces asciicast v2 compatible
  # recordings that can be played back or uploaded to asciinema.org.
  #
  # @example Record an interactive session
  #   recorder = AsciinemaWin::Recorder.new(title: "Demo")
  #   recorder.record("session.cast") do
  #     # Recording runs until Ctrl+D or block exits
  #   end
  #
  # @example Record a command
  #   recorder = AsciinemaWin::Recorder.new(command: "dir /s")
  #   recorder.record("command.cast")
  class Recorder
    # Default maximum idle time between events (seconds)
    DEFAULT_IDLE_TIME_LIMIT = 2.0

    # Default interval between screen captures (seconds)
    DEFAULT_CAPTURE_INTERVAL = 0.1

    # Minimum interval between captures to avoid CPU thrashing
    MIN_CAPTURE_INTERVAL = 0.033  # ~30 FPS max

    # @return [String, nil] Recording title
    attr_reader :title

    # @return [String, nil] Command to record
    attr_reader :command

    # @return [Float] Maximum idle time between events
    attr_reader :idle_time_limit

    # @return [Float] Interval between screen captures
    attr_reader :capture_interval

    # @return [Array<String>] Environment variables to capture
    attr_reader :env_vars

    # @return [Symbol] Current recording state (:idle, :recording, :paused, :stopped)
    attr_reader :state

    # Create a new recorder
    #
    # @param title [String, nil] Recording title
    # @param command [String, nil] Command to record in subprocess
    # @param idle_time_limit [Float] Maximum idle time (capped in output)
    # @param capture_interval [Float] Time between screen captures
    # @param env_vars [Array<String>] Environment variable names to capture
    def initialize(
      title: nil,
      command: nil,
      idle_time_limit: DEFAULT_IDLE_TIME_LIMIT,
      capture_interval: DEFAULT_CAPTURE_INTERVAL,
      env_vars: %w[SHELL TERM COMSPEC]
    )
      @title = title
      @command = command
      @idle_time_limit = idle_time_limit.to_f
      @capture_interval = [capture_interval.to_f, MIN_CAPTURE_INTERVAL].max
      @env_vars = env_vars

      @state = :idle
      @writer = nil
      @start_time = nil
      @last_buffer = nil
      @capture_thread = nil
      @stop_requested = false
      @markers = []
    end

    # Start recording to a file
    #
    # @param output_path [String] Path to save the recording
    # @yield [Recorder] Block for interactive recording
    # @return [Hash] Recording statistics
    # @raise [RecordingError] If recording fails
    def record(output_path, &block)
      raise RecordingError, "Already recording" if @state == :recording

      @state = :recording
      @stop_requested = false
      @markers = []

      begin
        if @command
          record_command(output_path)
        else
          record_interactive(output_path, &block)
        end
      ensure
        @state = :stopped
      end
    end

    # Pause recording (stops capturing but keeps file open)
    #
    # @return [void]
    def pause
      return unless @state == :recording

      @state = :paused
    end

    # Resume recording after pause
    #
    # @return [void]
    def resume
      return unless @state == :paused

      @state = :recording
    end

    # Stop recording
    #
    # @return [void]
    def stop
      @stop_requested = true
      @state = :stopped
    end

    # Add a marker at the current position
    #
    # @param label [String] Marker label
    # @return [void]
    def add_marker(label = "")
      return unless @writer && @start_time

      time = current_time
      @writer.write_marker(time, label)
      @markers << { time: time, label: label }
    end

    private

    # Record an interactive terminal session
    #
    # @param output_path [String] Output file path
    # @yield [Recorder] Block for custom recording logic
    # @return [Hash] Recording statistics
    def record_interactive(output_path)
      # Get initial terminal size
      size = get_terminal_size
      width = size[0]
      height = size[1]

      # Build header
      header = Asciicast::Header.new(
        width: width,
        height: height,
        title: @title,
        idle_time_limit: @idle_time_limit,
        env: capture_environment
      )

      # Open output file and create writer
      File.open(output_path, "w", encoding: "UTF-8") do |file|
        @writer = Asciicast::Writer.new(file, header)
        @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @last_buffer = nil
        @last_event_time = 0.0

        # Print recording message
        print_recording_started(output_path)

        begin
          if block_given?
            # Start capture thread
            start_capture_thread

            # Yield control to block
            yield self

            # Wait a bit for final captures
            sleep(@capture_interval * 2)
          else
            # Interactive recording with keyboard input
            run_interactive_loop
          end
        ensure
          stop_capture_thread
          @writer.close
        end

        # Return statistics
        {
          path: output_path,
          duration: @writer.last_event_time,
          event_count: @writer.event_count,
          width: width,
          height: height,
          markers: @markers.length
        }
      end
    end

    # Record a command execution
    #
    # @param output_path [String] Output file path
    # @return [Hash] Recording statistics
    def record_command(output_path)
      # Get initial terminal size
      size = get_terminal_size
      width = size[0]
      height = size[1]

      # Build header
      header = Asciicast::Header.new(
        width: width,
        height: height,
        title: @title || @command,
        command: @command,
        idle_time_limit: @idle_time_limit,
        env: capture_environment
      )

      File.open(output_path, "w", encoding: "UTF-8") do |file|
        @writer = Asciicast::Writer.new(file, header)
        @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @last_buffer = nil
        @last_event_time = 0.0

        print_recording_started(output_path)

        begin
          # Start capture thread
          start_capture_thread

          # Execute command and wait for it
          system(@command)

          # Wait for final output to be captured
          sleep(@capture_interval * 3)
        ensure
          stop_capture_thread
          @writer.close
        end

        print_recording_finished

        {
          path: output_path,
          duration: @writer.last_event_time,
          event_count: @writer.event_count,
          width: width,
          height: height,
          markers: @markers.length
        }
      end
    end

    # Run interactive recording loop
    #
    # @return [void]
    def run_interactive_loop
      # Start capture thread
      start_capture_thread

      # Set up raw mode for input detection
      puts "\e[33mRecording... Press Ctrl+D to stop, Ctrl+M for marker.\e[0m\n"

      begin
        loop do
          break if @stop_requested

          # Check for input (non-blocking)
          if $stdin.respond_to?(:ready?) && $stdin.ready?
            char = $stdin.getc
            handle_input_char(char)
          end

          # Also check for Ctrl+D or EOF
          if $stdin.eof?
            break
          end

          sleep(0.05)  # Small delay to avoid busy waiting
        end
      rescue Interrupt
        # Ctrl+C pressed
        @stop_requested = true
      rescue EOFError
        # End of input
        @stop_requested = true
      end
    end

    # Handle a single input character during recording
    #
    # @param char [String] Character pressed
    # @return [void]
    def handle_input_char(char)
      case char
      when "\x04"  # Ctrl+D
        @stop_requested = true
      when "\r"    # Ctrl+M (same as Enter)
        add_marker
      end
    end

    # Start the screen capture background thread
    #
    # @return [void]
    def start_capture_thread
      @capture_thread = Thread.new do
        capture_loop
      end
    end

    # Stop the capture thread
    #
    # @return [void]
    def stop_capture_thread
      @stop_requested = true

      if @capture_thread
        @capture_thread.join(1.0)  # Wait up to 1 second
        @capture_thread.kill if @capture_thread.alive?
        @capture_thread = nil
      end
    end

    # Main capture loop running in background thread
    #
    # @return [void]
    def capture_loop
      last_width = nil
      last_height = nil

      until @stop_requested
        begin
          # Skip if paused
          if @state == :paused
            sleep(@capture_interval)
            next
          end

          # Capture current screen
          buffer = ScreenBuffer.capture
          next unless buffer

          # Check for resize
          if last_width && last_height
            if buffer.width != last_width || buffer.height != last_height
              emit_resize_event(buffer.width, buffer.height)
            end
          end

          last_width = buffer.width
          last_height = buffer.height

          # Generate diff from previous buffer
          if @last_buffer
            diff = buffer.diff(@last_buffer)
            emit_output_event(diff) unless diff.empty?
          else
            # First capture - emit full screen
            output = buffer.to_ansi
            emit_output_event(output) unless output.empty?
          end

          @last_buffer = buffer

          sleep(@capture_interval)
        rescue StandardError => e
          # Log error but keep running
          warn "Capture error: #{e.message}" if ENV["DEBUG"]
          sleep(@capture_interval)
        end
      end
    end

    # Emit an output event with idle time limiting
    #
    # @param data [String] Output data
    # @return [void]
    def emit_output_event(data)
      return if data.nil? || data.empty?
      return unless @writer

      time = current_time

      # Apply idle time limit
      if @idle_time_limit > 0 && @last_event_time
        gap = time - @last_event_time
        if gap > @idle_time_limit
          # Adjust time to cap the idle period
          time = @last_event_time + @idle_time_limit
        end
      end

      @writer.write_output(time, data)
      @last_event_time = time
    end

    # Emit a resize event
    #
    # @param width [Integer] New width
    # @param height [Integer] New height
    # @return [void]
    def emit_resize_event(width, height)
      return unless @writer

      time = current_time
      @writer.write_resize(time, width, height)
    end

    # Get current recording time offset
    #
    # @return [Float] Seconds since recording started
    def current_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start_time
    end

    # Get terminal dimensions
    #
    # @return [Array<Integer>] [width, height]
    def get_terminal_size
      if Gem.win_platform? && defined?(Rich::Win32Console)
        size = Rich::Win32Console.get_size
        return size if size
      end

      # Try IO#winsize
      if $stdout.respond_to?(:winsize)
        height, width = $stdout.winsize
        return [width, height] if width > 0 && height > 0
      end

      # Default
      [80, 24]
    end

    # Capture environment variables
    #
    # @return [Hash<String, String>] Environment variable map
    def capture_environment
      result = {}

      @env_vars.each do |var|
        value = ENV[var]
        result[var] = value if value
      end

      # Add Windows-specific variables
      result["SHELL"] ||= ENV["COMSPEC"] || "cmd.exe"
      result["TERM"] ||= "xterm-256color"

      result
    end

    # Print recording started message
    #
    # @param path [String] Output path
    # @return [void]
    def print_recording_started(path)
      puts "\e[32masciinema-win: Recording started → #{path}\e[0m"
      puts "\e[33mPress Ctrl+D to finish recording.\e[0m"
      puts
    end

    # Print recording finished message
    #
    # @return [void]
    def print_recording_finished
      puts
      puts "\e[32masciinema-win: Recording finished.\e[0m"
      if @writer
        puts "Duration: #{format("%.2f", @writer.last_event_time)}s"
        puts "Events: #{@writer.event_count}"
      end
    end
  end
end
