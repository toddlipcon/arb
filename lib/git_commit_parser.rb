class GitCommitParser
  include Reloadable

  def parse(info)
    (info_section, log_and_diff) = info.split("\n\n", 2)
    (log, diff) = log_and_diff.split("\0")

    # The log ends up indented 4 spaces

    log.sub!(/^\s{4}?/, '')


    # Take a series of lines of the format:
    # <key> <value with multiple words>
    # and put it into a hash.
    #
    # This is complicated because the "parent"
    # key shows up multiple times for merge commits.
    parsed_info = { :parent => [] }

    info_section.split("\n").map {
      |line| 
      line.split(' ', 2)
    }.each do |key, val|
      key = key.to_sym
      if parsed_info[key].kind_of?(Array)
        parsed_info[key] << val
      else
        parsed_info[key] = val
      end
    end

    parsed = {
      :info => parsed_info,
      :log => log,
      :diff => diff
    }
  end

end
