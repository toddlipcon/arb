class Commit < ActiveRecord::Base
  validates_format_of :sha1, :with => /^[a-z0-9]+$/
  validates_length_of :sha1, :is => 40

  def check_valid
    if ! self.valid?
      throw Exception.new("Cannot operate on invalid commit")
    end
  end

  def repository_dir
    "/home/todd/arb/arb"
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

  def diff
    GitDiffParser.new.parse(self.diff_tree)
  end

end
