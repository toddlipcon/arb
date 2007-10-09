require File.dirname(__FILE__) + '/../test_helper'

class GitDiffParserTest < Test::Unit::TestCase

  TestDiffs = ['simple.diff']

  def setup
    @done_diffs = Hash.new
  end

  def read_diff(filename)
    File.read(File.dirname(__FILE__) + '/../git_diffs/' + filename)
  end

  def do_test_diff(filename)
    if ! @done_diffs.has_key?(filename)
      @done_diffs[filename] = GitDiffParser.new.parse(read_diff(filename))
    end

    @done_diffs[filename]
  end

  def test_diffs_successful
    TestDiffs.each do |filename|
      diff = do_test_diff(filename)
      assert !diff.nil?
    end
  end

  def test_simple
    diff = do_test_diff('simple.diff')
    assert !diff.nil?

    assert_equal(1, diff.chunks.length)

    chunk = diff.chunks[0]
    assert_not_nil(chunk)

    assert_equal(["a/AsqlShard.java"], chunk.src_files)
    assert_equal("b/AsqlShard.java", chunk.dst_file)
  end
end
