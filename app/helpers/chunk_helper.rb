module ChunkHelper
  @@comments_cache = Hash.new

  def comments_for_hash(index_hash)
    return @@comments_cache[index_hash] if @@comments_cache.include?(index_hash)

    @@comments_cache[index_hash] =
      Comment.find(:all,
                   :conditions => [
                     'index_hash = ?', index_hash
                   ],
                   :order => 'line_number, written_on')

    @@comments_cache[index_hash]
  end

  def comments_for_line(index_hash, line)
    comments_for_hash(index_hash).select do |comment|
      comment.line_number == line
    end
  end

end
