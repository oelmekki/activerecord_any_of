ActiveRecord::Schema.define do
  create_table :authors do |t|
    t.string   :name
    t.datetime :created_at
    t.datetime :updated_at
  end

  create_table :posts do |t|
    t.string   :title
    t.text     :body
    t.integer  :author_id
    t.string   :type
    t.datetime :created_at
    t.datetime :updated_at
  end

  create_table :companies do |t|
    t.string :name
  end

  create_table :universities do |t|
    t.string :name
  end

  create_table :memberships do |t|
    t.references :organization, polymorphic: true
    t.references :user
  end

  create_table :users do |t|
    t.string  :name
  end
end
