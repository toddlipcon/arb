require File.dirname(__FILE__) + '/../test_helper'

class GitDiffParserTest < Test::Unit::TestCase

  TestDiffs = ['simple.diff', 'multi_file.diff', 'merge.diff',
    'long.diff', 'rename.diff', 'no_newline.diff', 'binary_files.diff',
    'empty_file.diff', 'dodecapus.diff', 'single_line_source.diff',
    'change_mode.diff']

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

    assert_equal(1, diff.file_change_sets.length)
    
    fcs = diff.file_change_sets[0]
    assert_equal(1, fcs.chunks.length)

    assert_equal(["a/AsqlShard.java"], fcs.src_files)
    assert_equal("b/AsqlShard.java", fcs.dst_file)

    assert_equal(['ef696de6b68ac5094295fb7aa19dd6c5411f1886',
                   '8e996ec0ceac0ac1477c7d9d508df8e49e185d24'],
                 fcs.blobs);


    chunk = fcs.chunks[0]
    assert_not_nil(chunk)


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

    # Check to make sure the diffed lines don't include the "+" or "-" or whatever in the
    # "line" property
    assert_equal(" * Represents a shard", lines[4].line)

  end

  def test_multi_file
    diff = do_test_diff('multi_file.diff')
    assert !diff.nil?

    assert_equal(3, diff.file_change_sets.length)

    assert_equal("b/AsqlShard.java", diff.file_change_sets[0].dst_file)
    assert_equal("b/initial", diff.file_change_sets[1].dst_file)
    assert_equal("b/newfile", diff.file_change_sets[2].dst_file)

    # Test fcs 2 (idx 1) -- subtracts lines at end of chunk

    fcs = diff.file_change_sets[1]
    assert_equal(1, fcs.chunks.length)

    chunk = fcs.chunks[0]
    assert_equal(5, chunk.lines.length)

    expected_lines = [
      [1, 1],
      [2, 2],
      [3, 3],
      [4, nil],
      [5, nil]];
    assert_equal(expected_lines, chunk.lines.map { |l| l.line_numbers })

    # Test chunk 3 (idx 2) -- adds lines at end of chunk

    fcs = diff.file_change_sets[2]
    assert_equal(1, fcs.chunks.length)

    chunk = fcs.chunks[0]
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

    assert_equal(1, diff.file_change_sets.length)
    
    fcs = diff.file_change_sets.first


    assert_equal(['2e7199ed8dbbe95d4df8fe0a22ec4035ae5dc6dc',
                   '97c30c3a5364561b123fc159f19329c580fa53e5',
                   'c69a2a5082a7aeb124de612c2f56a183f2bef01d'],
                 fcs.blobs)


    assert_equal(1, fcs.chunks.length)
    chunk = fcs.chunks.first

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

  def test_binary_files
    diff = do_test_diff('binary_files.diff')
    assert_not_nil diff

    assert_equal(4, diff.file_change_sets.length)
    
    # Test that a non-binary change set isn't marked binary
    nonbinary_fcs = diff.file_change_sets[1]
    assert_equal(false, nonbinary_fcs.binary?)


    # Test that a binary change set is correctly parsed
    binary_fcs = diff.file_change_sets[3]    
    assert_equal(true, binary_fcs.binary?)

    assert_equal(['a/test/git_commits/simple.commit'],
                 binary_fcs.src_files)

    assert_equal('b/test/git_commits/simple.commit',
                 binary_fcs.dst_file)

    assert_equal(['9d5d5dc', 'ec8cf1e'],
                 binary_fcs.blobs)

    assert_equal(0,
                 binary_fcs.chunks.length)
    
  end
end
