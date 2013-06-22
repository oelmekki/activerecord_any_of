require 'activerecord_any_of/alternative_builder'

module ActiverecordAnyOf
  # Returns a new relation, which includes results matching any of conditions
  # passed as parameters. You can think of it as a sql <tt>OR</tt> implementation.
  #
  # Each #any_of parameter is the same set you would have passed to #where :
  #
  #    Client.any_of("orders_count = '2'", ["name = ?", 'Joe'], {email: 'joe@example.com'})
  #
  # You can as well pass #any_of to other relations :
  #
  #    Client.where("orders_count = '2'").any_of({ email: 'joe@example.com' }, { email: 'john@example.com' })
  #
  # And with associations :
  #
  #    User.find(1).posts.any_of({published: false}, "user_id IS NULL")
  #
  # The best part is that #any_of accepts other relations as parameter, to help compute
  # dynamic <tt>OR</tt> queries :
  #
  #    banned_users = User.where(banned: true)
  #    unconfirmed_users = User.where("confirmed_at IS NULL")
  #    unactive_users = User.any_of(banned_users, unconfirmed_users)
  def any_of(*queries)
    AlternativeBuilder.new(:positive, self, *queries).build
  end

  # Returns a new relation, which includes results not matching any of conditions
  # passed as parameters. It's the negative version of <tt>#any_of</tt>.
  #
  # This will return all active users :
  #
  #    banned_users = User.where(banned: true)
  #    unconfirmed_users = User.where("confirmed_at IS NULL")
  #    active_users = User.none_of(banned_users, unconfirmed_users)
  def none_of(*queries)
    AlternativeBuilder.new(:negative, self, *queries).build
  end
end

if Rails.version >= '4'
  module ActiverecordAnyOfDelegation
    delegate :any_of, to: :all
    delegate :none_of, to: :all
  end
else
  module ActiverecordAnyOfDelegation
    delegate :any_of, to: :scoped
    delegate :none_of, to: :scoped
  end
end

ActiveRecord::Relation.send(:include, ActiverecordAnyOf)
ActiveRecord::Base.send(:extend, ActiverecordAnyOfDelegation)
