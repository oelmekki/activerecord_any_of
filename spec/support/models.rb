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

class User < ActiveRecord::Base
  has_many :memberships
  has_many :companies, through: :memberships, source: :organization, source_type: "Company"
  has_many :universities, through: :memberships, source: :organization, source_type: "University"
end

class Membership < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization, polymorphic: true
end

class Company < ActiveRecord::Base
  has_many :memberships, as: :organization
  has_many :users, through: :memberships
end

class University < ActiveRecord::Base
  has_many :memberships, as: :organization
  has_many :users, through: :memberships
end
