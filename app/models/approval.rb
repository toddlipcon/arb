class Approval < ActiveRecord::Base

  belongs_to :commit

  validates_presence_of :approved_by
  validates_presence_of :approved_on
end
