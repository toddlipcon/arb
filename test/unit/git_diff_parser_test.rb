require File.dirname(__FILE__) + '/../test_helper'

class GitDiffParserTest < Test::Unit::TestCase

  TestDiffs = ['simple.diff', 'multi_file.diff', 'merge.diff', 'long.diff']

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

    lines = chunk.lines
    assert_equal(7, lines.length)

    expected_lines = [
      [1, 1],
      [2, 2],
      [nil, 3],
      [nil, 4],
      [nil, 5],
      [nil, 6],
      [3, 7]];

    assert_equal(expected_lines, lines.map { |l| l.line_numbers })
  end

  def test_multi_file
    diff = do_test_diff('multi_file.diff')
    assert !diff.nil?

    assert_equal(3, diff.chunks.length)

    assert_equal("b/AsqlShard.java", diff.chunks[0].dst_file)
    assert_equal("b/initial", diff.chunks[1].dst_file)
    assert_equal("b/newfile", diff.chunks[2].dst_file)

    # Test chunk 2 (idx 1) -- subtracts lines at end of chunk

    chunk = diff.chunks[1]

    assert_equal(5, chunk.lines.length)

    expected_lines = [
      [1, 1],
      [2, 2],
      [3, 3],
      [4, nil],
      [5, nil]];
    assert_equal(expected_lines, chunk.lines.map { |l| l.line_numbers })

    # Test chunk 3 (idx 2) -- adds lines at end of chunk

    chunk = diff.chunks[2]
    assert_equal(4, chunk.lines.length)
    expected_lines = [
      [1, 1],
      [2, 2],
      [nil, 3],
      [nil, 4]];
    assert_equal(expected_lines, chunk.lines.map { |l| l.line_numbers })
  end

  def test_merge
    diff = do_test_diff('merge.diff')
    assert !diff.nil?

    assert_equal(1, diff.chunks.length)

    chunk = diff.chunks[0]

    assert_equal(9, chunk.lines.length)

    expected_lines = [
      [2, 2, 2],
      [3, 3, 3],
      [4, 4, 4],
      [5, nil, nil],
      [nil, 5, nil],
      [nil, nil, 5],
      [6, 6, 6],
      [7, 7, 7],
      [8, 8, 8]]
    assert_equal(expected_lines, chunk.lines.map { |l| l.line_numbers })
  end
end
