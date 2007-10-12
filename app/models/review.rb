class Review < ActiveRecord::Base

  validates_presence_of :project
  belongs_to :project
end
