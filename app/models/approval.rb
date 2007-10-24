class Approval < ActiveRecord::Base
  validates_presence_of :approved_by
  validates_presence_of :approved_on

  validates_length_of :commit_sha1, :is => 40
end
