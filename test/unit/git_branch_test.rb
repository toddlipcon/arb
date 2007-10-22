require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../git_test_helper'

class GitBranchTest < Test::Unit::TestCase

  include GitTestHelper

  def test_branch
    branch = @repository.branch('branch2')
    assert_equal('d4e421c5c15bce5233e4030edfc69dbd5fe2ab31',
                 branch.sha1)

    assert(branch.exists_in_repository?)
  end

  def test_revlist_from
    branch = @repository.branch('branch1')

    assert_equal([ 'f3474b1b2af7f5dc0d849042ad1c10535152ee0c',
                   '5a46b5ebdd6a0ec8eda4c7a72c2158075e874a26' ],
                 branch.rev_list_from('initial'))
  end

  def test_nonexistent
    assert_equal(false,
                 @repository.branch('asdfas').exists_in_repository?)
  end
end
