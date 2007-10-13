class Project < ActiveRecord::Base
  def self.by_name(name)
    Project.find(:first, :conditions => [ 'name = ?', name ])
  end
end
