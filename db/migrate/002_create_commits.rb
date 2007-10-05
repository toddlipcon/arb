class CreateCommits < ActiveRecord::Migration
  def self.up
    create_table :commits do |t|
      # t.column :name, :string
        t.column :sha1, :string, :limit => 40
	t.column :approved_by, :string
	t.column :approved_on, :timestamp
    end
  end

  def self.down
    drop_table :commits
  end
end
