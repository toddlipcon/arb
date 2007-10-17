class Comment < ActiveRecord::Base
  belongs_to :review

  validates_associated :review
  validates_presence_of :review

  validates_presence_of :content
  validates_length_of :content, :minimum => 5

  validates_presence_of :line_number

  def validate
    errors.add('line_number', 'must be positive') unless line_number > 0
  end  
end
