class Array
  def cartesian_product(b)
    raise "bad args" unless b.kind_of?(Array)

    return self if b.empty?
    return b if self.empty?

    prod = self.map do |aElem|
      b.map do |bElem|
        [aElem, bElem]
      end
    end

    prod.inject do |left, right|
      left + right
    end
  end

  def minimum_length_cartesian_terms(b)
    carts = self.cartesian_product(b).map { |a| a.flatten.uniq }.uniq
    return [] if carts.empty?

    minLength = carts.min { |a, b| a.length <=> b.length }.length
    carts.select { |a| a.length == minLength }    
  end
end
