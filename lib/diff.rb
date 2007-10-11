##
# Generically represent a Diff
##
class Diff
  include Reloadable

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
    attr_reader :src_files, :dst_file, :blobs, :chunks, :binary

    def initialize(files, blobs, chunks)

      @src_files = files[:src_files]
      @dst_file  = files[:dst_file]
      @blobs     = blobs
      @chunks    = chunks

      @binary = ! files[:binary].nil?
    end

    alias_method :binary?, :binary
  end

  ##
  # A set of line changes
  ##
  class Chunk
    attr_accessor :lines

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
  end

end
