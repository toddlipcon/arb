require File.dirname(__FILE__) + '/../test_helper'

class ArrayCollectToHashTest < Test::Unit::TestCase

  def test_collect_to_hash
    # test the documented example

    assert_equal(
                 { 1 => [10],
                   2 => [20, 20],
                   3 => [30]
                 },
                 [1, 2, 3, 2].collect_to_hash { |x| x * 10 }
                 )
    

    # Test reverse

    assert_equal(
                 { 10 => [1],
                   20 => [2, 2],
                   30  => [3]
                 },
                 [1, 2, 3, 2].collect_to_reverse_hash { |x| x * 10 }
                 )

    # Test documented reverse

    assert_equal(
                 { 1 => [-1, 1],
                   4 => [2],
                   9 => [3]
                 },
                 [-1, 1, 2, 3].collect_to_reverse_hash { |x| x * x }
                 )
  end

end
