##
# Generically represent a Diff
##
class Diff
  include Reloadable

  attr_accessor :chunks

  def initialize(chunks)
    @chunks = chunks
  end

  def inspect
    self.chunks.join("\n")
  end

  class Chunk
    attr_accessor :src_files, :dst_file, :blobs, :lines
    def initialize(src, dst, blobs, lines)
      @src_files = src
      @dst_file = dst
      @blobs = blobs
      @lines = lines
    end
  end

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
