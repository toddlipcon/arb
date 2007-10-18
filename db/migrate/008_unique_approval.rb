class UniqueApproval < ActiveRecord::Migration
  def self.up
    add_index :approvals, [:commit_id, :approved_by], :unique => true, :name => 'unique_approval'
  end

  def self.down
    remove_index :approvals, :unique_approval
  end
end
