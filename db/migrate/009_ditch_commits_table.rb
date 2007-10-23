class DitchCommitsTable < ActiveRecord::Migration
  def self.up
    drop_table :commits
  end

  def self.down
    raise "cannot revert this migration"
  end
end
