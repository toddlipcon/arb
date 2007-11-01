class Review < ActiveRecord::Base

  validates_presence_of :project
  belongs_to :project

  validates_length_of :against_sha1, :is => 40

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
    branch.rev_list_from(self.against_sha1).map do |sha1|
      ArbCommit.new(project, sha1)
    end
  end

  def minimal_owners_to_approve
    solution = commits.inject([]) do |oldSoln, nextTerm|
      oldSoln.minimum_length_cartesian_terms(nextTerm.minimal_owners_to_approve)
    end
  end

  def log
    project.review_repository.git_log(against_sha1, "review-#{id}")
  end

  def count_commits
    if @count_commits.nil?
      @count_commits = branch.rev_list_from(self.against_sha1).length
    end
    @count_commits
  end

end
