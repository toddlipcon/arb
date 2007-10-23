class KeyCommitsBySha1 < ActiveRecord::Migration
  def self.up
    remove_index :approvals, :name => 'unique_approval'
    remove_column :approvals, :commit_id
    add_column :approvals, :commit_sha1, :string, :limit => 40
    add_index :approvals, [:commit_sha1, :approved_by], :unique => true, :name => 'unique_approval'
  end

  def self.down
    raise "Cannot revert this migration"
  end
end
