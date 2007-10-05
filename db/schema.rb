# This file is autogenerated. Instead of editing this file, please use the
# migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.

ActiveRecord::Schema.define(:version => 2) do

  create_table "commits", :force => true do |t|
    t.column "sha1", :string, :limit => 40
    t.column "approved_by", :string
    t.column "approved_on", :datetime
  end

  create_table "reviews", :force => true do |t|
    t.column "repository", :string
    t.column "developer", :string
    t.column "created_on", :datetime
  end

end
