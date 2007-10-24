class GitDiffParser
  include DiffParser

  attr_accessor :state
  attr_accessor :current_line_number

  ##
  # Parses a "combined format" textual diff output from a command like
  #
  # % git-diff-tree --cc -C <hash>
  # 
  # Returns a Diff object.
  # Throws an Exception if the Diff cannot be parsed.
  ##
  def parse(diff)
    @lines = diff.split(/\n/)
    @current_line_number = 0

    file_change_sets = []

    while has_more_lines? do
      
      file_change_sets << parse_file_change_set

    end

    return Diff.new(file_change_sets)
  end

  ##
  # Returns the next line of the input, or throw an exception
  # if there are no more lines.
  ##
  def get_next_line
    if ! has_more_lines?
      raise "No more lines"
    end
    @current_line_number += 1
    @lines[@current_line_number - 1]
  end

  ##
  # Moves the input line pointer back one line.
  # Throws an exception if the parser is currently on the first
  # line of the file.
  ##
  def back_line
    self.except "Can't go back a line" if @current_line_number <= 1

    @current_line_number -= 1
  end

  ##
  # Returns true if there are more lines in the file to read.
  ##
  def has_more_lines?
    return @current_line_number < @lines.length
  end

  ##
  # Returns the next line that would be returned if get_next_line
  # were called, but does not advance the line pointer.
  # Returns nil if currently at the end of the file.
  ##
  def peek_next_line
    return @lines[@current_line_number]
  end

  ##
  # Throws an exception including nice information about what
  # line the parser is currently on.
  ##
  def except(msg)
    throw Exception.new("Parse error (#{msg}) at line #{@current_line_number}: " +
                        "#{@lines[@current_line_number - 1]}")
  end

  ##
  # Prints a debug message.
  ##
  def debug(msg)
    # puts "PARSER DEBUG: #{msg}"
  end

########################################

=begin
Reads:

diff --cc AsqlShard.java

=end
  def match_diff_line(line)
    return line.match(/^diff (?:--git||--cc) (.+)$/)
  end

  def parse_diff_line
    line = get_next_line

    unless match = match_diff_line(line)
      except("Diff line had bad format")
    end

    return { :diff_files => match[1].split(/ /) }
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
  def parse_extended_headers
    headers = {}

    while has_more_lines? do
      line = get_next_line

      if match_data = line.match(/^index ([\w,]+)\.\.(\w+)(?:\s+(\d+))?$/)
        headers['index'] =
          {
            :src_blobs => match_data[1].split(','),
            :dst_blob     => match_data[2],
            :index_mode   => match_data[3]
          }
      elsif match_data = line.match(/^mode ([\d,]+)\.\.(\d+)$/)
        headers['mode'] =
          {
            :src_modes => match_data[1].split(','),
            :dst_mode     => match_data[2]
          }
      elsif match_data = line.match(/^(old|new) mode (\d+)$/)
        headers[match_data[1] + " mode"] =
          {
            :mode => match_data[2]
          }
      elsif match_data = line.match(/^new file mode (\d+)$/)
        headers['new file'] =
          {
            :mode => match_data[1]
          }
      elsif match_data = line.match(/^deleted file mode ([\d,]+)$/)
        headers['deleted file'] =
          {
            :modes => match_data[1].split(',')
          }
      elsif match_data = line.match(/^(rename|copy) (from|to) (.+)$/)
        headers[$1 + " " + match_data[2]] =
          {
            :path => match_data[3]
          }
      elsif match_data = line.match(/^(similarity|dissimilarity) index (\d+)%$/)
        headers[match_data[1] + " index"] =
          {
            :percentage => match_data[2]
          }
      else
        back_line
        return headers
      end
    end
    headers
  end


=begin
Reads:

--- a/AsqlShard.java
+++ b/AsqlShard.java

=end
  def parse_file_lines
    if has_more_lines? && match = peek_next_line.match(/^Binary files (.+) and (.+) differ$/)
      get_next_line
      return {
        :src_files => [match[1]],
        :dst_file  => match[2],
        :binary    => 1
      }
    end

    src_files = []
    dst_files = []

    while has_more_lines? do
      line = get_next_line

      if (line.match(/^--- (.+)$/))
        src_files << $1
      elsif (line.match(/^\+\+\+ (.+)$/))
        dst_files << $1
      else
        back_line
        break
      end
    end

    if dst_files.length != 1
      except("Wrong number of destination files -- need exactly 1")
    end

    return {
      :src_files => src_files,
      :dst_file => dst_files[0]
    }
  end

=begin

Match the header at the top of a chunk that looks like:

@@@ -2,7 -2,7 +2,7 @@@ package com.amiestreet.asql

=end
  def match_chunk_header(line)
    return line.match(/^\@{2,} ((?:[\-\+]\d+(?:,\d+)? )+)\@{2,}/);
  end

  def parse_chunk_header
    line = get_next_line
    unless match = match_chunk_header(line)
      except("Bad chunk start state")
    end

    ranges = match[1].split(' ').map do |s|
      (start, len) = s[1,s.length].split(/,/).map { |x| x.to_i }

      len = 1 if (len.nil?)

      [s[0], Range.new(start, start+len - 1)]
    end

    debug("Ranges: " + ranges.map {|a| a.join(":")}.join("|"));
    
    from_file_ranges = ranges.select {|r| r[0] == ?-}.map { |r| r[1] }
    to_file_ranges   = ranges.select {|r| r[0] == ?+}.map { |r| r[1] }

    if to_file_ranges.length != 1
      except("Too many to_file_ranges");
    end

    return {
      :from_ranges => from_file_ranges,
      :to_range => to_file_ranges[0]
    }
  end

=begin

Reads lines of the type:

 -  * Represents a shard. Its okay
 -  * Represents a shard. Its great
 ++ * Represents a shard. Its somewhere between OK to great

=end
  def parse_chunk_lines(chunk_header)
    from_lines = chunk_header[:from_ranges].map {|r| r.first}
    to_line = chunk_header[:to_range].first

    all_ranges = chunk_header[:from_ranges].push(chunk_header[:to_range])

    done_lines = Array.new(all_ranges.length, nil)
    max_lines = all_ranges.map { |r| r.last }

    # If there's an empty range, then we don't expect to see any lines
    # in that source, so set max_lines to nil in that column
    max_lines.each_index do |i|
      max_lines[i] = nil if all_ranges[i].last < all_ranges[i].first
    end

    debug("Looking for max_lines: " + max_lines.join("|"))

    lines = []

    while done_lines != max_lines
      line = get_next_line
      debug("Parsing line: #{line}")

      # We don't really care about parsing this, so skip the line
      next if (line == '\ No newline at end of file')

      # Get the '+', ' ', and '-' flags from the beginning of the line
      # There is one for each "input" file
      diff_status = line[0.. from_lines.length - 1].split("")

      has_plusses = ! diff_status.select { |x| x == '+' }.empty?
      has_minuses = ! diff_status.select { |x| x == '-' }.empty?

      # debug("+: #{has_plusses.inspect}  -: #{has_minuses.inspect}")

      if has_plusses and has_minuses
        except("Shouldn't have both plusses and minuses on a diff body line!")
      end

      # If there's a + in any of the columns, or all the flags are ' ', then
      # it appears in the destination file
      line_appears_in_dst = has_plusses || (! has_minuses)
      # debug("appears in dst: #{line_appears_in_dst.inspect}")

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

      # We don't really care about parsing this, so skip the line
      get_next_line if peek_next_line == '\ No newline at end of file'

      lines << Diff::DiffLine.new(line_numbers, line[from_lines.length .. line.length])
      debug("line numbers: " + line_numbers.map { |x| x.inspect }.join("|"));
    end

    return lines
  end


  def parse_chunk
    chunk_header = parse_chunk_header
    chunk_lines = parse_chunk_lines(chunk_header)
    return Diff::Chunk.new(chunk_lines)
  end


  def parse_chunks
    chunks = []
    while has_more_lines? && match_chunk_header(peek_next_line) do
      chunks << parse_chunk
    end
    return chunks
  end


  def parse_file_change_set
    diff_line = parse_diff_line
    debug "Parsed diff line: #{diff_line.inspect}"

    extended_headers = parse_extended_headers

    # If the file is empty (so the diff is only showing a creation, deletion
    # mode change, etc, then there won't be any file lines, and it will go right
    # on to the next diff. Check for that here.
    if has_more_lines? && !match_diff_line(peek_next_line)
      files = parse_file_lines
    else
      except "bad diff line for chunkless diff" if diff_line[:diff_files].length != 2

      files = {
        :src_files => [diff_line[:diff_files][0]],
        :dst_file  => diff_line[:diff_files][1]
      }
    end

    chunks = parse_chunks

    # Figure out the blobs involved
    debug "Extended headers: #{extended_headers.inspect}"

    if index_info = extended_headers['index']
      blobs = index_info[:src_blobs].concat([index_info[:dst_blob]])
      debug('blobs: ' + blobs.inspect)
    else
      # In the case of just a mode change, there is no index header
      blobs = []
    end

    return Diff::FileChangeSet.new(files,
                                   blobs,
                                   chunks,
                                   extended_headers);
  end
end
