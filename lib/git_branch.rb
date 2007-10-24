class GitBranch
  attr_reader :repository
  attr_reader :name


  def initialize(repository, name)
    @repository = repository
    @name = name
  end

  def sha1
    return @sha1 unless @sha1.nil?

    @sha1 = repository.git_rev_parse(@name)
    @sha1
  end

  def rev_list_from(ref)
    repository.git_rev_list(ref, name)
  end

  def exists_in_repository?
    !repository.git_rev_parse(@name).nil?
  end

end
