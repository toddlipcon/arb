class AddComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.column  :review_id, :integer

      t.column  :written_on,   :timestamp, :null => false

      t.column  :index_hash,   :string, :limit => 32, :null => false
      t.column  :line_number,  :integer

      t.column  :commenter,    :string, :null => false

      t.column  :parent_comment_id, :integer

      t.column  :content,      :text
    end
  end

  def self.down
    drop_table :comments
  end
end
