class CreateReviews < ActiveRecord::Migration
  def self.up
    create_table :reviews do |t|
      t.column	:repository,	:string
      t.column	:developer,	:string
      t.column	:created_on,	:timestamp
    end
  end

  def self.down
    drop_table :reviews
  end
end
