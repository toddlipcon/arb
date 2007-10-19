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


  def git_show_commit
    check_valid

    return project.review_repository.git_show(self.sha1)
  end

  def git_get_full_revision
    return project.review_repository.git_get_full_revision(self.sha1)
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

    stat = project.review_repository.git_diff_status_from_parent(self.sha1)
    return stat.map { |change| change[:file] }
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
  # Finds applicable OWNERS file for the given file path in the main repository.
  # Returns a hash of the type:
  # {
  #    :path   => <the path to the OWNERS file>
  #    :blob   => <the blob hash of the most recent version of this in the
  #                  main repository>
  #    :owners => <array of the owners listed in this file>
  # }
  #
  # Returns nil if there is no applicable OWNERS file.
  ##
  def find_owners_file(dir)
    project.main_repository.in_repository do
      possible = possible_owners_files(dir)
      safer_args = possible.map { |f| "'" + f + "'" }

      existing_owners = `git-ls-tree HEAD #{safer_args.join(" ")}`.split("\n")

      owners_hash = existing_owners.inject(Hash.new) do |h, line|
        blob = line.split()[2]
        path = line.split("\t")[1]

        h[path] = blob
        h
      end

      tightest_owners = possible.find { |p| owners_hash.include?(p) }

      if tightest_owners.nil?
        puts "WARNING: no owners file for dir #{dir}" and return nil
      end

      blob = owners_hash[tightest_owners]

      raise "bad blob" unless blob.length == 40

      return {
        :path   => tightest_owners,
        :blob   => blob,
        :owners => read_owners_file(blob)
      }
    end
  end

  ##
  # Returns the applicable OWNERS files for all of the files
  # involved in this commit. The output is an array of hashes, where
  # each hash has the form as returned by find_owners_file() above
  ##
  def applicable_owners_files
    raise "not in review repository" unless exists_in_review_repository?

    affected_dirs = changed_files.map { |f| File.dirname(f) }.uniq
    
    owners_files = affected_dirs.map { |d| find_owners_file(d) }.uniq
  end

  ##
  # Returns a hash where the keys are hashes of the form returned by
  # find_owners_file and the values are the file names in this commit
  # that are governed by that OWNERS file
  ##
  def applicable_owners_files_hash

    # Make hash of (directory => [files in that directory in this commit]) pairs

    puts "changed files: #{changed_files.inspect}"

    affected_dirs_hash = changed_files.collect_to_hash do |file|
      File.dirname(file)
    end

    puts "affected_dirs_hash: #{affected_dirs_hash.inspect}"

    affected_dirs = affected_dirs_hash.keys

    # Make hash of owners file => [file1, file2, file3]
    affected_dirs.inject(Hash.new) do |hash, dir|
      owner = find_owners_file(dir)
      raise "No owner for dir #{dir}" if owner.nil?

      if (hash.include?(owner))
        hash[owner] = hash[owner] + affected_dirs_hash[dir]
      else
        hash[owner] = affected_dirs_hash[dir]
      end
      hash
    end    
  end

  def read_owners_file(blob)
    project.main_repository.git_show(blob).
      gsub(/\#.*$/m, ''). # get rid of comments
      strip. # trim
      split("\n").
      reject {|s| s == ''} # get rid of blank lines
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

    files.map { |f| f[:owners] }
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

    puts "project: #{project.inspect}"
    rev = project.review_repository.git_get_full_revision(self.sha1)
    @exists_in_review_repository = !rev.nil?
    @exists_in_review_repository
  end


  ##
  # Makes sure that the commit has been approved by someone from every
  # applicable OWNERS file
  ##
  def approved?
    approving_users = self.approvals.map { |a| a.approved_by }

    unsatisfied = owners_contents.select do |owners|
      (owners & approving_users).empty?
    end

    unsatisfied.empty?
  end

  def diff
    check_valid

    GitDiffParser.new.parse(project.review_repository.git_diff_tree(self.sha1))
  end

  def to_json
    data = {}
    [:sha1, :author, :committer, :exists_in_review_repository?, :log_message, :approved?].map do |sym|
      data[sym] = self.send(sym)
    end
    data.to_json
  end
end
