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
    attr_accessor :src_files, :dst_file, :lines
    def initialize(src, dst, lines)
      @src_files = src
      @dst_file = dst
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
  end

end
