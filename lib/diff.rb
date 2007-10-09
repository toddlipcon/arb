class Diff
  include Reloadable

  attr_accessor :chunks

  def initialize
  end

  def inspect
    self.chunks.join("\n")
  end


  class Chunk
    def initialize(lines)
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
