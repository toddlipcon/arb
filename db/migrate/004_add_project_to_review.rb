class AddProjectToReview < ActiveRecord::Migration
  def self.up
    add_column :reviews, :project_id, :integer
    add_index :reviews, :project_id
  end

  def self.down
    remove_column :reviews, :project_id
  end
end
