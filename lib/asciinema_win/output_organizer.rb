# frozen_string_literal: true

require "fileutils"

module AsciinemaWin
  # Output organization utilities
  #
  # Provides structured directory organization for recordings and exports
  # with timestamp-based naming and format-specific subdirectories.
  module OutputOrganizer
    # Default base directory for outputs
    DEFAULT_BASE_DIR = "asciinema_output"

    # Format subdirectory mapping
    FORMAT_DIRS = {
      cast: "recordings",
      html: "html",
      svg: "svg",
      txt: "text",
      text: "text",
      json: "json",
      gif: "video",
      mp4: "video",
      webm: "video",
      thumbnail: "thumbnails"
    }.freeze

    class << self
      # Get organized output path
      #
      # @param base_name [String] Base name for the file
      # @param format [Symbol] Output format
      # @param base_dir [String] Base output directory
      # @param timestamp [Boolean] Include timestamp in filename
      # @param session_id [String, nil] Session ID for grouping related files
      # @return [String] Full output path
      def output_path(base_name, format:, base_dir: DEFAULT_BASE_DIR, timestamp: true, session_id: nil)
        # Ensure base directory exists
        ensure_directory(base_dir)

        # Get format-specific subdirectory
        format_dir = FORMAT_DIRS[format.to_sym] || "other"
        full_dir = File.join(base_dir, format_dir)

        # Add session subdirectory if provided
        if session_id
          full_dir = File.join(full_dir, session_id)
        end

        ensure_directory(full_dir)

        # Build filename
        filename = if timestamp
                     "#{base_name}_#{timestamp_string}.#{format}"
                   else
                     "#{base_name}.#{format}"
                   end

        File.join(full_dir, filename)
      end

      # Create a session directory for related outputs
      #
      # @param name [String] Session name
      # @param base_dir [String] Base output directory
      # @return [Session] Session object for organizing related files
      def create_session(name, base_dir: DEFAULT_BASE_DIR)
        session_id = "#{sanitize_name(name)}_#{timestamp_string}"
        Session.new(session_id, base_dir)
      end

      # Get organized path for a recording
      #
      # @param name [String] Recording name
      # @param base_dir [String] Base output directory
      # @param timestamp [Boolean] Include timestamp
      # @return [String] Full path to recording file
      def recording_path(name, base_dir: DEFAULT_BASE_DIR, timestamp: true)
        output_path(sanitize_name(name), format: :cast, base_dir: base_dir, timestamp: timestamp)
      end

      # List all sessions in output directory
      #
      # @param base_dir [String] Base output directory
      # @return [Array<String>] Session directory names
      def list_sessions(base_dir: DEFAULT_BASE_DIR)
        recordings_dir = File.join(base_dir, "recordings")
        return [] unless Dir.exist?(recordings_dir)

        Dir.children(recordings_dir)
           .select { |f| File.directory?(File.join(recordings_dir, f)) }
           .sort
           .reverse
      end

      # Get summary of output directory contents
      #
      # @param base_dir [String] Base output directory
      # @return [Hash] Summary of files by category
      def summary(base_dir: DEFAULT_BASE_DIR)
        result = {}

        FORMAT_DIRS.values.uniq.each do |subdir|
          path = File.join(base_dir, subdir)
          next unless Dir.exist?(path)

          files = Dir.glob(File.join(path, "**", "*"))
                     .select { |f| File.file?(f) }

          result[subdir] = {
            count: files.length,
            total_size: files.sum { |f| File.size(f) },
            files: files.map { |f| File.basename(f) }
          }
        end

        result
      end

      # Clean old files from output directory
      #
      # @param base_dir [String] Base output directory
      # @param keep_days [Integer] Keep files newer than this many days
      # @return [Integer] Number of files deleted
      def cleanup(base_dir: DEFAULT_BASE_DIR, keep_days: 30)
        cutoff = Time.now - (keep_days * 24 * 60 * 60)
        deleted = 0

        Dir.glob(File.join(base_dir, "**", "*")).each do |file|
          next unless File.file?(file)
          next if File.mtime(file) > cutoff

          File.delete(file)
          deleted += 1
        end

        # Remove empty directories
        Dir.glob(File.join(base_dir, "**", "*"))
           .select { |d| File.directory?(d) }
           .sort_by { |d| -d.length }  # Deepest first
           .each do |dir|
             Dir.rmdir(dir) if Dir.empty?(dir)
           rescue Errno::ENOTEMPTY
             # Skip non-empty directories
           end

        deleted
      end

      private

      # Generate timestamp string for filenames
      #
      # @return [String] Timestamp in YYYYMMDD_HHMMSS format
      def timestamp_string
        Time.now.strftime("%Y%m%d_%H%M%S")
      end

      # Sanitize a name for use in filenames
      #
      # @param name [String] Original name
      # @return [String] Sanitized name
      def sanitize_name(name)
        name.to_s
            .gsub(/[^a-zA-Z0-9_\-]/, "_")
            .gsub(/_+/, "_")
            .gsub(/^_|_$/, "")
            .downcase
      end

      # Ensure directory exists
      #
      # @param path [String] Directory path
      # @return [void]
      def ensure_directory(path)
        FileUtils.mkdir_p(path) unless Dir.exist?(path)
      end
    end

    # Session for grouping related output files
    class Session
      # @return [String] Session ID
      attr_reader :id

      # @return [String] Base output directory
      attr_reader :base_dir

      # @return [Time] Session creation time
      attr_reader :created_at

      # @return [Hash] Paths generated in this session
      attr_reader :outputs

      def initialize(id, base_dir)
        @id = id
        @base_dir = base_dir
        @created_at = Time.now
        @outputs = {}
      end

      # Get path for a recording in this session
      #
      # @param name [String] Recording name
      # @return [String] Full path
      def recording_path(name = "recording")
        path = OutputOrganizer.output_path(
          OutputOrganizer.send(:sanitize_name, name),
          format: :cast,
          base_dir: @base_dir,
          session_id: @id,
          timestamp: false
        )
        @outputs[:recording] = path
        path
      end

      # Get path for an export in this session
      #
      # @param name [String] Export name
      # @param format [Symbol] Output format
      # @return [String] Full path
      def export_path(name, format:)
        path = OutputOrganizer.output_path(
          OutputOrganizer.send(:sanitize_name, name),
          format: format,
          base_dir: @base_dir,
          session_id: @id,
          timestamp: false
        )
        @outputs[format] ||= []
        @outputs[format] << path
        path
      end

      # Get path for a thumbnail in this session
      #
      # @param name [String] Thumbnail name
      # @param frame [Symbol] Frame type (:first, :middle, :last)
      # @return [String] Full path
      def thumbnail_path(name, frame: :last)
        path = OutputOrganizer.output_path(
          "#{OutputOrganizer.send(:sanitize_name, name)}_#{frame}",
          format: :svg,
          base_dir: File.join(@base_dir, "thumbnails"),
          session_id: @id,
          timestamp: false
        )
        @outputs[:thumbnails] ||= []
        @outputs[:thumbnails] << path
        path
      end

      # Get session directory path
      #
      # @return [String] Session directory
      def directory
        File.join(@base_dir, "recordings", @id)
      end

      # Print summary of session outputs
      #
      # @return [String] Summary text
      def summary
        lines = ["Session: #{@id}", "Created: #{@created_at}", "Outputs:"]
        @outputs.each do |type, paths|
          paths = [paths] unless paths.is_a?(Array)
          paths.each do |path|
            size = File.exist?(path) ? File.size(path) : 0
            lines << "  #{type}: #{File.basename(path)} (#{size} bytes)"
          end
        end
        lines.join("\n")
      end
    end
  end
end
