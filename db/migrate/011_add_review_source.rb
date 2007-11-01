class AddReviewSource < ActiveRecord::Migration
  def self.up
    add_column :reviews, :against_sha1, :string, :limit => 40, :null => false
  end

  def self.down
    remove_column :reviews, :against_sha1
  end
end
