class Post < ActiveRecord::Base
  attr_accessible :body, :title, :type, :user_id
  belongs_to :author
end
