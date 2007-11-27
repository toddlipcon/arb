class MemCache

  def cache_block(key, expires, &block)

    if result = self[key]
      return result.first
    end

    result = yield

    self.set(key, [result], expires)

    return result
  end

end
