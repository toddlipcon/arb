require File.dirname(__FILE__) + '/../test_helper'

class GitDiffParserTest < Test::Unit::TestCase

  TestDiffs = ['simple.diff']

  def read_diff(filename)
    File.read(File.dirname(__FILE__) + '/../git_diffs/' + filename)
  end

  def test_diffs_successful
    TestDiffs.each do |filename|
      diffText = read_diff(filename)

      diff = GitDiffParser.new.parse(diffText)
    end
  end
end
