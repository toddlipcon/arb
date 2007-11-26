class Review < ActiveRecord::Base

  validates_presence_of :project
  belongs_to :project

  validates_length_of :against_sha1, :is => 40

  def exists_in_review_repository?
    branch.exists_in_repository?
  end

  def branch
    self.project.review_repository.branch('review-' + self.id.to_s)
  end

  def commits
    branch = self.branch
    if !branch.exists_in_repository?
      raise "Cant get commit list for branch that does not exist in review repo"
    end

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

  def diff
    diff = project.review_repository.git_diff_tree(against_sha1, "review-#{id}")
    GitDiffParser.new.parse(diff)
  end

  def count_commits
    if @count_commits.nil?
      @count_commits = branch.rev_list_from(self.against_sha1).length
    end
    @count_commits
  end

  def approved?
    commits.all? { |c| c.approved? }
  end

  def pushed?
    commits.all? { |c| c.exists_in_main_repository? }
  end

  def to_json
    h = 
    {
      'developer' => developer,
      'against_sha1' => against_sha1,
      'created_on' => created_on,
      'project' => project.name,
      'id' => id
    }

    if exists_in_review_repository?
      h.merge!({
                 'is_approved' => approved?,
                 'is_pushed'   => pushed?
               })
    end
    h.to_json
  end

end
