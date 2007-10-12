class AddProjects < ActiveRecord::Migration
  def self.up
    add_column :commits, :project_id, :integer
    add_index :commits, :project_id

    create_table :projects do |t|
      t.column :name, :string, :limit => 40
      t.column :main_repository, :string
      t.column :review_repository, :string
    end

    add_index :projects, :name

    # Create some basic projects
    Project.create(
                   :name => 'test',
                   :main_repository => '/files/git/repos/main/test',
                   :review_repository => '/files/git/repos/review/test');

    Project.create(
                   :name => 'arb',
                   :main_repository => '/files/git/repos/main/arb',
                   :review_repository => '/files/git/repos/review/arb');

  end

  def self.down
    remove_column :commits, :project_id
    drop_table :projects
  end
end
