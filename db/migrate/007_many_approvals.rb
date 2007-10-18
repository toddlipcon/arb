class ManyApprovals < ActiveRecord::Migration
  def self.up
    remove_column :commits, :approved_by
    remove_column :commits, :approved_on
    
    create_table :approvals do |t|
      t.column :commit_id, :integer, :null => false
      t.column :approved_by, :string, :null => false
      t.column :approved_on, :datetime, :null => false
    end
  end

  def self.down
    drop_table :approvals
  end
end
