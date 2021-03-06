##
# Generically represent a Diff
##
class Diff
  attr_accessor :file_change_sets

  def initialize(file_change_sets)
    @file_change_sets = file_change_sets
  end

  def inspect
    self.file_change_sets.join("\n")
  end

  ##
  # A set of change chunks that apply to the same set of files.
  # Each FileChangeSet produces changes in a single destination file,
  # and has any number of source files (usually 1, but more for merges,
  # and 0 for created files)
  ##
  class FileChangeSet
    attr_reader :src_files, :dst_file, :blobs, :chunks, :extended_headers, :binary

    def initialize(files, blobs, chunks, extended_headers)

      @src_files = files[:src_files]
      @dst_file  = files[:dst_file]
      @blobs     = blobs
      @chunks    = chunks
      @extended_headers = extended_headers

      @binary = ! files[:binary].nil?
    end

    def new_file?
      @extended_headers.has_key?('new file')
    end

    def deleted_file?
      @extended_headers.has_key?('deleted file')
    end

    alias_method :binary?, :binary
  end

  ##
  # A set of line changes
  ##
  class Chunk
    attr_reader :lines

    def initialize(lines)
      @lines = lines
    end
  end

  ##
  # A single line of differences
  ##
  class DiffLine
    attr_accessor :line_numbers
    attr_accessor :line

    def initialize(line_numbers, line)
      @line_numbers = line_numbers
      @line = line
    end

    def unchanged?
      @line_numbers.uniq.length == 1
    end

    def fully_inserted?
      @line_numbers[0.. @line_numbers.length - 2].uniq == [nil]
    end

    def appears_in_output?
      ! @line_numbers.last.nil?
    end

    def best_file_index
      last_non_nil_idx = line_numbers.map { |x| x.nil? }.rindex(false)
      if last_non_nil_idx.nil?
        raise "No non-nil lines in diff line: #{self.inspect}"
      end

      last_non_nil_idx
    end
  end

end
