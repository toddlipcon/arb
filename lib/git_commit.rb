class GitCommit
  attr_reader :repository
  attr_reader :sha1

  def initialize(repository, sha1)
    @repository = repository
    @sha1 = sha1
  end

  def git_show
    @git_show = repository.git_show(self.sha1) if @git_show.nil?
    @git_show
  end

  def full_revision
    return repository.git_get_full_revision(self.sha1)
  end

  def exists_in_repository?
    ! repository.git_rev_parse(@sha1).nil?
  end

  def parse_info
    return @parsed_info unless @parsed_info.nil?

    @parsed_info = GitCommitParser.new.parse(git_show)
  end

  def log_message
    self.parse_info[:log]
  end

  def author
    self.parse_info[:info][:author]
  end

  def committer
    self.parse_info[:info][:committer]
  end

  def changed_files
    return @changed_files if !@changed_files.nil?
    @changed_files = CACHE.cache_block('git_commit/' + self.sha1 + "/changed_files", 0) do
      stat = repository.git_diff_status_from_parent(self.sha1)
      stat.map { |change| change[:file] }
    end
  end

  def diff
    GitDiffParser.new.parse(repository.git_diff_tree(self.sha1))
  end

end
