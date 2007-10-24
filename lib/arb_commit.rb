class ArbCommit
  attr_reader :project
  attr_reader :sha1

  def initialize(project, sha1)
    @project = project
    @sha1 = sha1
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
        puts "WARNING: no owners file for dir #{dir}"
        return nil
      end

      blob = owners_hash[tightest_owners]

      raise "bad blob" unless !blob.nil? && blob.length == 40

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

    affected_dirs_hash = changed_files.collect_to_reverse_hash do |file|
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

  def approvals
    return Approval.find(:all,
                         :conditions => [ "commit_sha1 = ?", self.sha1 ])
  end


  ############################################################
  # Adapter to the git commit
  ############################################################

  def review_commit
    if @review_commit.nil?
      @review_commit = GitCommit.new(project.review_repository,
                                     @sha1)
    end
    @review_commit
  end

  def author
    return review_commit.author
  end
  
  def committer
    return review_commit.committer
  end

  def log_message
    return review_commit.log_message
  end

  def changed_files
    return review_commit.changed_files
  end

  def diff
    return review_commit.diff
  end
end
