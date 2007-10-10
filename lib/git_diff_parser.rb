class GitDiffParser
  include Reloadable
  include DiffParser

  attr_accessor :state
  attr_accessor :current_line_number

  def parse(diff)
    @lines = diff.split(/\n/)
    @current_line_number = 0

    @state = DiffLineState.new(self)

    while (! @state.nil? and ! @state.done?) do
      debug "Parsing -- on line #{@current_line_number}"
      @state = @state.parse_line
    end

    @state.diff
  end

  def get_next_line
    @current_line_number += 1
    if @current_line_number > @lines.length
      raise "No more lines"
    end
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

    def done?
      return false
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

      if (! line.match(/^diff (?:--git||--cc) (.+)$/))
        parser.except("Diff line had bad format at")
      end

      parser.debug("matched diff args: #{$1}")

      data['diff_files'] = $1.split(/ /);

      return ExtendedHeaderState.new(parser, data)
    end
  end

=begin
Reads the extended header lines:

       2. It is followed by one or more extended header lines:

          old mode <mode>
          new mode <mode>
          deleted file mode <mode>
          new file mode <mode>
          copy from <path>
          copy to <path>
          rename from <path>
          rename to <path>
          similarity index <number>
          dissimilarity index <number>
          index <hash>..<hash> <mode>

=end
  ##
  class ExtendedHeaderState < State
    def parse_line
      data[:extended_headers] = []

      while 1 do
        line = @parser.get_next_line

        if match_data = line.match(/^index ([\w,]+)\.\.(\w+)(?:\s+(\d+))?$/)
          data[:extended_headers] <<
            ['index', {
              :src_blobs => match_data[1].split(','),
              :dst_blob     => match_data[2],
              :index_mode   => match_data[3]
            }]
        elsif match_data = line.match(/^mode ([\d,]+)\.\.(\d+)$/)
          data[:extended_headers] <<
            ['mode', {
              :source_modes => match_data[1].split(','),
              :dst_mode     => match_data[2]
            }]
        elsif match_data = line.match(/^new file mode (\d+)$/)
          data[:extended_headers] <<
            ['new file', {
              :mode => match_data[1]
            }]
        elsif match_data = line.match(/^deleted file mode ([\d,]+)$/)
          data[:extended_headers] <<
            ['deleted file', {
              :modes => match_data[1].split(',')
            }]
        elsif match_data = line.match(/^(rename|copy) (from|to) (.+)$/)
          data[:extended_headers] <<
            [$1 + " " + match_data[2], {
              :path => match_data[3]
            }]
        elsif match_data = line.match(/^(similarity|dissimilarity) index (\d+)%$/)
          data[:extended_headers] <<
            [$1 + " index", {
              :percentage => match_data[2]
            }]
        else
          parser.back_line
          return FileLineState.new(parser, data)
        end
      end
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

        if @dst_files.length != 1
          parser.except("Wrong number of destination files -- need exactly 1")
        end

        data[:src_files] = @src_files
        data[:dst_file] = @dst_files[0]
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

      all_ranges = @chunk_data[:from_file_ranges].push(@chunk_data[:to_file_range])

      done_lines = Array.new(all_ranges.length, nil)
      max_lines = all_ranges.map { |r| r.last }

      # If there's an empty range, then we don't expect to see any lines
      # in that source, so set max_lines to nil in that column
      max_lines.each_index do |i|
        max_lines[i] = nil if all_ranges[i].last < all_ranges[i].first
      end
      

      parser.debug("Looking for max_lines: " + max_lines.join("|"))

      while done_lines != max_lines
        line = @parser.get_next_line

        parser.debug("Parsing line: #{line}")

        # Get the '+', ' ', and '-' flags from the beginning of the line
        # There is one for each "input" file
        diff_status = line[0.. from_lines.length - 1].split("")

        has_plusses = ! diff_status.select { |x| x == '+' }.empty?
        has_minuses = ! diff_status.select { |x| x == '-' }.empty?

#        parser.debug("+: #{has_plusses.inspect}  -: #{has_minuses.inspect}")

        if has_plusses and has_minuses
          parser.except("Shouldn't have both plusses and minuses on a diff body line!")
        end

        # If there's a + in any of the columns, or all the flags are ' ', then
        # it appears in the destination file
        line_appears_in_dst = has_plusses || (! has_minuses)
#        parser.debug("appears in dst: #{line_appears_in_dst.inspect}")

        #TODO(todd) add more checking on lengths

        line_numbers = []

        diff_status.each_index do |i|
          if (diff_status[i] == '-') ||
              ((diff_status[i] == ' ') && line_appears_in_dst)
            line_numbers << from_lines[i]
            done_lines[i] = from_lines[i]

            from_lines[i] += 1
          else
            line_numbers << nil
          end
        end

        # Take care of the line number for the "destination" file
        if line_appears_in_dst
          line_numbers << to_line
          done_lines[-1] = to_line

          to_line += 1
        else
          line_numbers << nil
        end

        @lines << Diff::DiffLine.new(line_numbers, line[from_lines.length .. line.length])

        parser.debug("line numbers: " + line_numbers.map { |x| x.inspect }.join("|"));
      end

      parser.debug("Done parsing chunk")
      
      # Figure out the blobs involved
      index_header = @data[:extended_headers].select { |x| x[0] == 'index' }.first

      if index_header.nil? || index_header.length != 2
        parser.except("No index header found for chunk")
      end

      index_info = index_header[1]
      blobs = index_info[:src_blobs].concat([index_info[:dst_blob]])
      parser.debug('blobs: ' + blobs.inspect)


      # Create the cunk
      chunk = Diff::Chunk.new(@data[:src_files], @data[:dst_file], blobs, @lines)

      @data[:chunks] = [] if @data[:chunks].nil?
      @data[:chunks] << chunk


      if ! parser.more_lines?
        # End of diff file

        return ParseCompleteState.new(Diff.new(@data[:chunks]))
      end

      peek = parser.peek_next_line
      
      if peek =~ /^\@\@/
        return ChunkStartState.new(parser, data)
      else
        return DiffLineState.new(parser, data)
      end

    end
  end # ChunkDataState

  class ParseCompleteState < State
    attr_accessor :diff;
    def initialize(diff)
      @diff = diff
    end

    def done?
      return true
    end
  end

end
