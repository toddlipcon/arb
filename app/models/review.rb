class Review < ActiveRecord::Base

  validates_presence_of :project
  belongs_to :project

  def branch
    branch = self.project.review_repository.branch('review-' + self.id.to_s)
    if branch.nil? || !branch.exists_in_repository?
      raise "No such branch in review repository"
    end

    branch
  end

  def commits
    branch = self.branch

    project.review_repository.git_fetch_from('main')
    branch.rev_list_from('remotes/main/master').map do |sha1|
      ArbCommit.new(project, sha1)
    end
  end

end
