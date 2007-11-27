class GitRepository
  attr_reader :repository_dir

  def initialize(repository_dir)
    raise "nil repository passed to GitRepository constructor" if repository_dir.nil?
    @repository_dir = repository_dir
  end

  # Use a hash to only have a single instance per physical repository dir
  @@instances = {}
  def self.get(repository_dir)
    if ! @@instances.has_key?(repository_dir)
      @@instances[repository_dir] = GitRepository.new(repository_dir)
    end

    return @@instances[repository_dir]
  end

  def in_repository
    Dir.chdir(@repository_dir) { yield }
  end

  def git_diff_tree(from, to=nil)
    in_repository do
      if to.nil?
        return `git-diff-tree --no-commit-id -C --cc #{from}`
      else
        return `git-diff-tree --no-commit-id -C --cc #{from}..#{to}`
      end
    end
  end

  def git_show(sha1)
    if @blob_cache.nil?
      @blob_cache = {}
    end

    return @blob_cache[sha1] if @blob_cache.has_key?(sha1)

    @blob_cache[sha1] = CACHE.cache_block('git_show/' + @repository_dir + '/' + sha1, 0) do
      in_repository do
        `git-show --pretty=raw #{sha1}`
      end
    end
  end

  def git_get_full_revision(partial_sha1)
    cache_key = 'partial_revision/' + @repository_dir + '/' + partial_sha1

    CACHE.cache_block(cache_key, 0) do
      in_repository do
        rev = `git-rev-list -n 1 #{partial_sha1} || echo -n FAILURE`
        (rev != 'FAILURE') ? rev.chomp : nil
      end
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
    cache_key = 'rev_parse/' + @repository_dir + '/' + rev_id

    if !CACHE.nil?
      if result = CACHE[cache_key]
        return result
      end
    end

    rev = in_repository do
      `git-rev-list --max-count=1 #{rev_id} 2>/dev/null`.chomp
    end

    if !CACHE.nil?
      CACHE[cache_key] = rev
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

    # Only do this once
    if !@has_fetched_from.nil? &&
        @has_fetched_from.has_key?(other_repository)
      return
    end

    in_repository do
      output = `git-fetch #{other_repository} 2>&1`
      raise "Error from git-fetch: #{output}" if $? != 0
    end

    if @has_fetched_from.nil?
      @has_fetched_from = {}
    end
    @has_fetched_from[other_repository] = 1
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
