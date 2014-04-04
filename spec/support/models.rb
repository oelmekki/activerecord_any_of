class Author < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :author
end

class SpecialPost < Post
end

class StiPost < Post
end

