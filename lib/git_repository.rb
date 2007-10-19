class GitRepository
  include Reloadable

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

end
