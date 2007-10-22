module GitTestHelper

  TestRepositoryTarball = Pathname.new(File.dirname(__FILE__) + '/test_git_repo.tar').realpath

  def setup
    @tmp_dir = File.join(Dir.tmpdir, "arb_unittest_" +  $$.to_s)    
    
    Dir.mkdir(@tmp_dir)
    Dir.chdir(@tmp_dir) do 
      system("tar xf #{TestRepositoryTarball}")
    end

    @repository = GitRepository.new(File.join(@tmp_dir, 'test_git_repo'))
  end

  def teardown
    system("rm -Rf #{@tmp_dir}")
  end

end
