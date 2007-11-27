class Project < ActiveRecord::Base
  def self.by_name(name)
    Project.find(:first, :conditions => [ 'name = ?', name ])
  end

  def review_repository
    GitRepository.get(self[:review_repository])
  end

  def main_repository
    GitRepository.get(self[:main_repository])
  end

end
