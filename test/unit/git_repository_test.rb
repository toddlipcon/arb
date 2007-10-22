require 'pathname'

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../git_test_helper'

class GitRepositoryTest < Test::Unit::TestCase

  include GitTestHelper

  def with_temporary_repository(&block)
    # Make a temporary repository
    tmp_dir = File.join(Dir.tmpdir, "test_git_" +  $$.to_s)
    Dir.mkdir tmp_dir
    begin
      Dir.chdir(tmp_dir) do
        system('git-init 2>/dev/null > /dev/null')
        raise "Couldnt init tmp git repo" if $? != 0
      end
      yield GitRepository.new(tmp_dir)
    rescue => e
#      system("rm -Rf #{tmp_dir}")
      raise e
    end
  end

  def test_full_revision
    assert_equal(@repository.git_get_full_revision('d4e4'),
                 'd4e421c5c15bce5233e4030edfc69dbd5fe2ab31')
  end

  def test_diff_status
    assert_equal(@repository.git_diff_status_from_parent('d4e421c5c15bce5233e4030edfc69dbd5fe2ab31'),
                 [ { :change_type => 'A', :file => 'file' },
                   { :change_type => 'D', :file => 'filea' },
                   { :change_type => 'M', :file => 'fileb' } ])
  end

  def test_list_branches
    assert_equal(['branch1', 'branch2', 'initial', 'master'],
                 @repository.git_list_branches.sort)
  end

  def test_rev_list
    assert_equal([ 'f3474b1b2af7f5dc0d849042ad1c10535152ee0c',
                   '5a46b5ebdd6a0ec8eda4c7a72c2158075e874a26'],
                 @repository.git_rev_list('initial', 'branch1'))
  end

  def test_rev_parse
    assert_equal('0663cc55f4ea8f86b83b999e1ebf5a5c944527b8',
                 @repository.git_rev_parse('initial'))

    assert_nil(@repository.git_rev_parse('sdadfasfd'))
  end

  def test_fetch
    with_temporary_repository do |repo|
      repo.git_add_remote('test', @repository.repository_dir)
      repo.git_fetch_from('test')
      assert_equal('0663cc55f4ea8f86b83b999e1ebf5a5c944527b8',
                   repo.git_rev_parse('remotes/test/master'))
    end
  end

end
