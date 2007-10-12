class Commit < ActiveRecord::Base
  validates_format_of :sha1, :with => /^[a-z0-9]+$/
  validates_length_of :sha1, :is => 40

  belongs_to :review

  def self.default_project
    Project.find(:first, :conditions => [ 'name = ?', "test" ])
  end

  def self.by_sha1(args)
    args = {
      :project => self.default_project
    }.merge(args)

    db_commit = find(:first,
                     :conditions => [
                       'project_id = ? AND ' +
                       'sha1 LIKE ?',
                       args[:project],
                       args[:sha1] + "%"])

    return db_commit unless db_commit.nil?

    commit = self.new(args)
    puts commit.to_yaml
    commit.sha1 = commit.git_get_full_revision if commit.exists_in_review_repository?
    commit
  end

  def check_valid
    if ! self.valid?
      throw Exception.new("Cannot operate on invalid commit: #{self.inspect}")
    end
  end

  def project
    review.project
  end

  def review_repository_dir
    self.project.review_repository
  end

  def in_review_repository
    Dir.chdir(self.review_repository_dir) { yield }
  end

  def diff_tree
    check_valid

    in_review_repository do
      return `git-diff-tree --no-commit-id -C --cc #{self.sha1}`
    end
  end

  def git_show_commit
    check_valid

    in_review_repository do
      return `git-show --pretty=raw #{self.sha1}`
    end
  end

  def git_get_full_revision
    in_review_repository do
      rev = `git-rev-list -n 1 #{self.sha1} || echo -n FAILURE`
      return (rev != 'FAILURE') ? rev.chomp : nil
    end
  end

  def parse_info
    return @parsed_info unless @parsed_info.nil?

    if exists_in_review_repository?
      @parsed_info = GitCommitParser.new.parse(git_show_commit)
    else
      @parsed_info = nil
    end
    return @parsed_info
  end

  def log_message
    return nil unless exists_in_review_repository?
    self.parse_info[:log]
  end

  def author
    return nil unless exists_in_review_repository?
    self.parse_info[:info][:author]
  end

  def committer
    return nil unless exists_in_review_repository?
    self.parse_info[:info][:committer]
  end

  def exists_in_review_repository?
    return @exists_in_review_repository unless @exists_in_review_repository.nil?

    rev = git_get_full_revision
    @exists_in_review_repository = !rev.nil?
    @exists_in_review_repository
  end

  def approved?
    return !new_record? && ! approved_by.nil?
  end

  def diff
    GitDiffParser.new.parse(self.diff_tree)
  end

  def to_json
    data = {}
    [:sha1, :author, :committer, :exists_in_review_repository?, :log_message, :approved?].map do |sym|
      data[sym] = self.send(sym)
    end
    data.to_json
  end
end
