class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :title
      t.text :body
      t.integer :author_id
      t.string :type

      t.timestamps
    end
  end
end
