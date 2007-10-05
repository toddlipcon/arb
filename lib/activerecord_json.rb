require 'json/objects'

class ActiveRecord::Base
  # Converts the ActiveRecord object to a JSON string. Only columns with simple
  # types are included in this object so no recursion problems can occur.
  def to_json
    result = Hash.new

    self.class.content_columns.each do |column|
      result[column.name.to_sym] = self.send(column.name)
    end

    result.to_json
  end
end

