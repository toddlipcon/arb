##
# Useful extensions to the Array class for mapping Arrays into Hashes
##
class Array
  ##
  # Invokes block once for each element of this Array. Creates a hash
  # in which the keys are the elements of this array and the values are
  # arrays containing the values returned by the block.
  #
  # For example:
  #
  #   [1, 2, 3, 2].collect_to_hash { |x| x * 10 }
  # returns:
  #   { 1 => [10], 2 => [20, 20], 3 => [30] }
  ##
  def collect_to_hash(&block)
    self.inject(Hash.new) do |hash, key|
      value = yield key

      if hash.include?(key)
        hash[key] << value
      else
        hash[key] = [value]
      end

      hash
    end
  end

  ##
  # The same as collect_to_hash except that keys and values are reversed.
  #
  # For example:
  #
  #   [-1, 1, 2, 3].collect_to_reverse_hash { |x| x * x }
  # returns
  #   {1 => [-1, 1], 4 => [2], 9 => [3]}
  ##
  def collect_to_reverse_hash(&block)
    self.inject(Hash.new) do |hash, value|
      key = yield value
      
      if hash.include?(key)
        hash[key] << value
      else
        hash[key] = [value]
      end

      hash
    end
  end

end
