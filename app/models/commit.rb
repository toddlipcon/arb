class Commit < ActiveRecord::Base
  validates_format_of :sha1, :with => /^[a-z0-9]+$/
  validates_length_of :sha1, :is => 40

  def check_valid
    if ! self.valid?
      throw Exception.new("Cannot operate on invalid commit")
    end
  end

  def repository_dir
    "/files/git/repos/review/arb"
  end

  def in_repo
    Dir.chdir(self.repository_dir) { yield }
  end

  def diff_tree
    check_valid

    in_repo do
      return `git-diff-tree --no-commit-id -C --cc #{self.sha1}`
    end
  end

  def git_show_commit
    check_valid

    in_repo do
      return `git-show --pretty=raw #{self.sha1}`
    end
  end

  def parse_info
    return @parsed_info unless @parsed_info.nil?

    @parsed_info = GitCommitParser.new.parse(git_show_commit)
    return @parsed_info
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

  def diff
    GitDiffParser.new.parse(self.diff_tree)
  end

end
