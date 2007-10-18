class CommitBelongsToReview < ActiveRecord::Migration
  def self.up
    add_column :commits, :review_id, :integer
    remove_column :commits, :project_id
  end

  def self.down
    add_column :commits, :project_id, :integer
    remove_column :commits, :review_id
  end
end
