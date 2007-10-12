require 'json/objects'

class ActiveRecord::Base
  include Reloadable

  def to_json
    result = Hash.new

    self.class.columns.each do |column|
      result[column.name.to_sym] = self.send(column.name)
    end

    result.to_json
  end
end

