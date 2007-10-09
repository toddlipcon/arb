class GitDiffParser
  include Reloadable
  include DiffParser

  attr_accessor :state
  attr_accessor :current_line_number

  def parse(diff)
    @lines = diff.split(/\n/)
    @current_line_number = 0

    @state = DiffLineState.new(self)

    while (! @state.nil?) do
      debug "Parsing -- on line #{@current_line_number}"
      @state = @state.parse_line
    end
  end

  def get_next_line
    @current_line_number += 1
    @lines[@current_line_number - 1]
  end

  def back_line
    @current_line_number -= 1
  end

  def more_lines?
    return @current_line_number < @lines.length - 1
  end

  def peek_next_line
    return @lines[@current_line_number]
  end

  def except(msg)
    throw Exception.new("Parse error (#{msg}) at line #{@current_line_number}: " +
                        "#{@lines[@current_line_number - 1]}")
  end

  def debug(msg)
    puts "PARSER DEBUG: #{msg}"
  end

  class State
    attr_accessor :parser
    attr_accessor :data

    def initialize(parser, data = {})
      @parser = parser
      @data = data
    end

    def parse_line
      return nil
    end
  end

=begin
Reads:

diff --cc AsqlShard.java

=end
  ##
  class DiffLineState < State
    def parse_line
      line = @parser.get_next_line

      if (! line.match(/^diff --git (.+)$/))
        parser.except("Diff line had bad format at")
      end

      parser.debug("matched diff args: #{$1}")

      data['diff_files'] = $1.split(/ /);

      return IndexLineState.new(parser, data)
    end
  end

=begin
Reads:

index 2e7199ed8dbbe95d4df8fe0a22ec4035ae5dc6dc,97c30c3a5364561b123fc159f19329c580fa53e5..c69a2a5082a7aeb124de612c2f56a183f2bef01d

=end
  ##
  class IndexLineState < State
    def parse_line
      line = @parser.get_next_line

      if (! line.match(/^index ([\w,]+)\.\.(\w)+\s+\d+$/))
        parser.except("Indexline had bad format at")
      end

      data[:source_blobs] = $1.split(',')
      data[:dst_blob] = $2

      return FileLineState.new(parser, data)
    end
  end

=begin
Reads:

--- a/AsqlShard.java
+++ b/AsqlShard.java

=end
  ##
  class FileLineState < State
    def initialize(parser, data)
      super(parser, data)

      @src_files = Array.new
      @dst_files = Array.new
    end

    def parse_line
      line = @parser.get_next_line

      if (line.match(/^--- (.+)$/))
        @src_files << $1
        return parse_line

      elsif (line.match(/^\+\+\+ (.+)$/))
        @dst_files << $1
        return parse_line

      else
        @parser.back_line

        data[:src_files] = @src_files
        data[:dst_files] = @dst_files
        return ChunkStartState.new(parser, data)
      end
    end
  end # FileLineState



=begin

Reads the header at the top of a chunk that looks like:

@@@ -2,7 -2,7 +2,7 @@@ package com.amiestreet.asql

=end
  class ChunkStartState < State
    def parse_line
      line = @parser.get_next_line
      if !line.match(/^\@{2,} ((?:[\-\+]\d+,\d+ )+)\@{2,}/)
        parser.except("Bad chunk start state")
      end

      range_strings = $~.to_a[1].split(' ')
      ranges = range_strings.map do |s|
        (start, len) = s[1,s.length].split(/,/).map { |x| x.to_i }

        [s[0], Range.new(start, start+len - 1)]
      end

      parser.debug("Ranges: " + ranges.map {|a| a.join(":")}.join("|"));

      chunk = {}
      chunk[:from_file_ranges] = ranges.select {|r| r[0] == ?-}.map { |r| r[1] }

      to_file_ranges   = ranges.select {|r| r[0] == ?+}.map { |r| r[1] }

      if to_file_ranges.length != 1
        parser.except("Too many to_file_ranges");
      end

      chunk[:to_file_range] = to_file_ranges[0]

      return ChunkDataState.new(parser, data, chunk)
    end
  end #ChunkStartState

=begin

Reads lines of the type:

 -  * Represents a shard. Its okay
 -  * Represents a shard. Its great
 ++ * Represents a shard. Its somewhere between OK to great

=end

    class ChunkDataState < State
      def initialize(parser, data, chunk_data)
        super(parser, data)
        @chunk_data = chunk_data
        @lines = []
      end

      def parse_line
        from_lines = @chunk_data[:from_file_ranges].map {|r| r.first}
        to_line = @chunk_data[:to_file_range].first

        while to_line <= @chunk_data[:to_file_range].last
          line = @parser.get_next_line

          parser.debug("Parsing line: #{line}")

          diff_status = line[0.. from_lines.length - 1].split("")
          #          parser.debug("Diff_status: #{diff_status.inspect}")

          #TODO(todd) add more checking on lengths

          line_numbers = []

          diff_status.each_index do |i|
            if diff_status[i] == " "
              line_numbers << from_lines[i]
              from_lines[i] += 1
            else
              line_numbers << nil
            end
          end

          if diff_status.select { |x| x == "-" }.empty?
            line_numbers << to_line
            to_line += 1
          else
            line_numbers << nil
          end

          @lines << Diff::DiffLine.new(line_numbers, line[from_lines.length - 1 .. line.length])

          parser.debug("line numbers: " + line_numbers.map { |x| x.inspect }.join("|"));
        end


        chunk = Diff::Chunk.new(@lines)

        return nil unless parser.more_lines?
        peek = parser.peek_next_line
        
        if peek =~ /^\@\@/
          return ChunkStartState.new(parser, data)
        else
          return DiffLineState.new(parser, data)
        end

      end
    end # ChunkDataState

  end
