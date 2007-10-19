class Commit < ActiveRecord::Base
  validates_format_of :sha1, :with => /^[a-z0-9]+$/
  validates_length_of :sha1, :is => 40

  belongs_to :review
  has_many :approvals


  def self.default_project
    Project.by_name("test")
  end

  def self.by_sha1(args)
    unless args.include?(:project)
      if args.include?(:project_id)
        args[:project] = Project.find(args[:project_id])
        raise "bad project id" if args[:project].nil?
      else
        args[:project] = default_project
      end
    end

    db_commits = find_by_sql(["SELECT commits.* FROM commits " +
      "JOIN reviews ON commits.review_id = reviews.id " +
      "WHERE commits.sha1 LIKE ? AND reviews.project_id = ?",
      args[:sha1] + '%', args[:project].id])

    raise "ambiguous commit" if db_commits.length > 1

    db_commit = db_commits.first

    return db_commit unless db_commit.nil?

    puts args.inspect
    commit = self.new(:sha1 => args[:sha1])

    commit.project = args[:project]
    commit.sha1 = commit.git_get_full_revision if commit.exists_in_review_repository?

    puts "commit constructed: #{commit.to_json}"
    commit
  end

  def check_valid
    if ! self.valid?
      throw Exception.new("Cannot operate on invalid commit: #{self.inspect}")
    end
  end

  def project
    unless review.nil?
      review.project
    else
      @project
    end
  end

  def project=(project)
      unless review.nil?
        raise "Cannot set project of the commit's owning review by commit mutator"
      else
        @project = project
      end
  end

  def review_repository_dir
    self.project.review_repository
  end

  def main_repository_dir
    self.project.main_repository
  end

  def in_review_repository
    Dir.chdir(self.review_repository_dir) { yield }
  end

  def in_main_repository
    Dir.chdir(self.main_repository_dir) { yield }
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

  def changed_files
    return nil unless exists_in_review_repository?
    in_review_repository do
      stat = `git diff #{self.sha1}^ #{self.sha1} --name-status`
      return stat.map do |line|
        match = line.chomp.match(/^(.)\s+(.+)$/)
        change_type, file = match[1], match[2]

        file
      end
    end
  end

  ##
  # Looks in dir for a file called .OWNERS, scanning upward
  # in the repository until it finds one. Returns the blob hash
  # when it finds one. Returns nil if none is found.
  #
  # The directory passed to this should be relative to the
  # repository root.
  ##
  def possible_owners_files(dir)
    return ['OWNERS'] if dir == '.' || dir == '';

    [File.join([dir, 'OWNERS'])] +
      possible_owners_files(File.dirname(dir))
  end


  ##
  # Finds the blob of the applicable OWNERS file for the given file path
  # in the main repository.
  #
  # Returns nil if there is no applicable OWNERS file
  ##
  def find_owners_file(dir)
    in_main_repository do
      possible = possible_owners_files(dir)
      safer_args = possible.map { |f| "'" + f + "'" }

      existing_owners = `git-ls-tree HEAD #{safer_args.join(" ")}`.split("\n")

      owners_hash = existing_owners.inject(Hash.new) do |h, line|
        blob = line.split()[2]
        filename = line.split("\t")[1]

        h[filename] = blob
        h
      end

      tightest_owners = possible.find { |p| owners_hash.include?(p) }

      if tightest_owners.nil?
        puts "WARNING: no owners file for dir #{dir}" and return nil
      end

      blob = owners_hash[tightest_owners]

      raise "bad blob" unless blob.length == 40

      return blob
    end
  end

  ##
  # Returns the blobs of the applicable OWNERS files for all of the files
  # involved in this commit
  ##
  def applicable_owners_files
    raise "not in review repository" unless exists_in_review_repository?

    affected_dirs = changed_files.map { |f| File.dirname(f) }.uniq
    
    owners_files = affected_dirs.map { |d| find_owners_file(d) }.uniq
  end

  ##
  # Returns the contents of the OWNERS files that apply to this commit
  # as an array of arrays.
  #
  # For example, if a/OWNERS contains "todd\njason" and b/OWNERS contains
  # "dzs" then a commit that touches a/foo/somefile and b/someotherfile
  # will return [['todd', 'jason'], ['dzs']]
  ##
  def owners_contents
    files = applicable_owners_files
    raise "No owners found" unless files

    in_main_repository do
      files.map do |f|
        `git-show "#{f}"`.
          gsub(/\#.*$/m, ''). # get rid of comments
          strip. # trim
          split("\n").
          reject {|s| s == ''} # get rid of blank lines
      end
    end
  end

  ##
  # Suggests sets of reviewers who could approve this review and satisfy
  # all OWNERS constraints
  ##
  def minimal_owners_to_approve
    owners = owners_contents
    
    # If there's only one OWNERS file that applies, just return it
    # since the magic cartesian product screws it up
    if owners.length == 1
      return owners.first.map { |o| [o] }
    end

    # Essentially computes the cartesian product of the arrays, but with
    # uniqueness after each step
    solutions = owners.inject do |memo, nextArray|
      memo.inject([]) do |insideMemo, a|
        insideMemo + nextArray.map do |b|
          (a.to_a + b.to_a).uniq
        end
      end
    end

    # Find the minimum length possible
    minlength = solutions.min { |a,b| a.length <=> b.length }.length

    # Return all solutions of that length
    solutions.select { |a| a.length == minlength }
  end

  def exists_in_review_repository?
    return @exists_in_review_repository unless @exists_in_review_repository.nil?

    rev = git_get_full_revision
    @exists_in_review_repository = !rev.nil?
    @exists_in_review_repository
  end

  def approved?
    return self.approvals.count != 0
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
