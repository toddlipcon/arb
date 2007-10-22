require File.dirname(__FILE__) + '/../test_helper'

class GitCommitTest < Test::Unit::TestCase

  include GitTestHelper

  def test_new
    commit = GitCommit.new(@repository, 'd4e421')
    assert_not_nil(commit)
  end

  def test_show
    commit = GitCommit.new(@repository, 'd4e421')

    assert_equal(29,
                 commit.git_show.split("\n").length)
  end

  def test_full_revision
    commit = GitCommit.new(@repository, 'd4e421')

    assert_equal('d4e421c5c15bce5233e4030edfc69dbd5fe2ab31',
                 commit.full_revision)
  end

  def test_log_message
    commit = GitCommit.new(@repository, 'd4e421')

    assert_equal('Three changes',
                 commit.log_message)
  end

  def test_author
    commit = GitCommit.new(@repository, 'd4e421')

    assert_equal('Todd Lipcon <todd@janus.corp.amiestreet.com> 1193093840 -0400',
                 commit.author)
  end

  def test_committer
    commit = GitCommit.new(@repository, 'd4e421')

    assert_equal('Todd Lipcon <todd@janus.corp.amiestreet.com> 1193093840 -0400',
                 commit.committer)
    
  end

end
