class Commit < ActiveRecord::Base

  validates_format_of :sha1, :with => /^[a-z0-9]+$/
  validates_length_of :sha1, :is => 40

  def repository_dir
    "/files/git/repos/review/web"
  end

  def diff_tree
    if ! self.valid?
      throw Exception.new("Cannot diff invalid commit")
    end

    Dir.chdir(self.repository_dir) do
      return `git-diff-tree --cc #{self.sha1}`
    end
  end

end
