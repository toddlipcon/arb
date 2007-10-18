require File.dirname(__FILE__) + '/../test_helper'

class GitCommitParserTest < Test::Unit::TestCase

  def read_test(filename)
    t = File.read(File.dirname(__FILE__) + '/../git_commits/' + filename)
    assert_not_nil t
    t
  end

  def test_parse_info
    info = GitCommitParser.new.parse(read_test('simple.commit'))
    assert_not_nil info

    assert_equal({
                   :commit => '378d1ec955b6b56c99a91707fd1283cd1476de18',
                   :tree   => '2176ed8f46b31b6b4a7a037e790c8ef9e5f764a7',
                   :parent => ['860527c5b43b0987ccc3a9d3d42e5f3dbae14dd4',
                               'e336bcf6507066cfc887be6f7c94c1cbdb718936'],
                   :author => 'Todd Lipcon <todd@turbo.corp.amiestreet.com> 1191951070 -0400',
                   :committer => 'Todd Lipcon <todd@turbo.corp.amiestreet.com> 1191951070 -0400'
                 },
                 info[:info])
                 

    assert_equal("Merge branch 'master' into b\n\nConflicts:\n\n\tAsqlShard.java",
                 info[:log])
  end

  def test_parse_another
    info = GitCommitParser.new.parse(read_test('second.commit'))
    assert_not_nil info
  end


end
