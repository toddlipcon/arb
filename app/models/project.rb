class Project < ActiveRecord::Base
  def self.by_name(name)
    Project.find(:first, :conditions => [ 'name = ?', name ])
  end

  def in_review_repository
    Dir.chdir(self.review_repository) { yield }
  end

  def in_main_repository
    Dir.chdir(self.main_repository) { yield }
  end


end
