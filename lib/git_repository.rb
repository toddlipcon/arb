class GitRepository
  attr_reader :repository_dir

  def initialize(repository_dir)
    raise "nil repository passed to GitRepository constructor" if repository_dir.nil?
    @repository_dir = repository_dir
  end

  def in_repository
    Dir.chdir(@repository_dir) { yield }
  end

  def git_diff_tree(sha1)
    in_repository do
      return `git-diff-tree --no-commit-id -C --cc #{sha1}`
    end
  end

  def git_show(sha1)
    in_repository do
      return `git-show --pretty=raw #{sha1}`
    end
  end

  def git_get_full_revision(partial_sha1)
    in_repository do
      rev = `git-rev-list -n 1 #{partial_sha1} || echo -n FAILURE`
      return (rev != 'FAILURE') ? rev.chomp : nil
    end
  end

  def git_diff_status_from_parent(sha1)
    in_repository do
      stat = `git diff #{sha1}^ #{sha1} --name-status`

      return stat.map do |line|
        match = line.chomp.match(/^(.)\s+(.+)$/)
        { :change_type => match[1],
          :file => match[2]
        }
      end
    end
  end

  def git_rev_list(from, to)
    in_repository do
      `git-rev-list #{from}..#{to}`.split("\n")
    end
  end
  
  def git_rev_parse(rev_id)
    rev = in_repository do
      `git-rev-parse --verify #{rev_id} 2>/dev/null`.chomp
    end
    return rev.empty? ? nil : rev
  end

  def git_list_branches
    in_repository do
      `git-branch --no-color`.split("\n").map do |line|
        raise "Bad line from git-branch: #{line}" unless line.match(/^..(.+)$/)
        $1
      end
    end
  end

  def git_add_remote(name, url)
    in_repository do
      `git-remote add #{name} #{url} 2>/dev/null`
    end
  end

  def git_fetch_from(other_repository)
    in_repository do
      output = `git-fetch #{other_repository} 2>&1`
      raise "Error from git-fetch: #{output}" if $? != 0
    end
  end

  def git_log(from, to, flags="")
    in_repository do
      output = `git-log #{flags} #{from}..#{to}`
      raise "Error from git-log: #{output}" if $? != 0
      output
    end
  end
  
  def branch(name)
    GitBranch.new(self, name)
  end

end
