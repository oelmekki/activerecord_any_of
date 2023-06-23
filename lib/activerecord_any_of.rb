# frozen_string_literal: true

require 'activerecord_any_of/alternative_builder'

module ActiverecordAnyOf
  # Injected into WhereChain.
  module Chained
    # Returns a new relation, which includes results matching any of the conditions
    # passed as parameters. You can think of it as a sql <tt>OR</tt> implementation :
    #
    #    User.where.any_of(first_name: 'Joe', last_name: 'Joe')
    #    # => SELECT * FROM users WHERE first_name = 'Joe' OR last_name = 'Joe'
    #
    #
    # You can separate sets of hash condition by explicitly group them as hashes :
    #
    #    User.where.any_of({first_name: 'John', last_name: 'Joe'}, {first_name: 'Simon', last_name: 'Joe'})
    #    # => SELECT * FROM users WHERE ( first_name = 'John' AND last_name = 'Joe' ) OR
    #    ( first_name = 'Simon' AND last_name = 'Joe' )
    #
    #
    # Each #any_of set is the same kind you would have passed to #where :
    #
    #    Client.where.any_of("orders_count = '2'", ["name = ?", 'Joe'], {email: 'joe@example.com'})
    #
    #
    # You can as well pass #any_of to other relations :
    #
    #    Client.where("orders_count = '2'").where.any_of({ email: 'joe@example.com' }, { email: 'john@example.com' })
    #
    #
    # And with associations :
    #
    #    User.find(1).posts.where.any_of({published: false}, "user_id IS NULL")
    #
    #
    # The best part is that #any_of accepts other relations as parameter, to help compute
    # dynamic <tt>OR</tt> queries :
    #
    #    banned_users = User.where(banned: true)
    #    unconfirmed_users = User.where("confirmed_at IS NULL")
    #    inactive_users = User.where.any_of(banned_users, unconfirmed_users)
    def any_of(*queries)
      raise ArgumentError, 'Called any_of() with no arguments.' if queries.none?

      AlternativeBuilder.new(:positive, @scope, *queries).build
    end

    # Returns a new relation, which includes results not matching any of the conditions
    # passed as parameters. It's the negative version of <tt>#any_of</tt>.
    #
    # This will return all active users :
    #
    #    banned_users = User.where(banned: true)
    #    unconfirmed_users = User.where("confirmed_at IS NULL")
    #    active_users = User.where.none_of(banned_users, unconfirmed_users)
    def none_of(*queries)
      raise ArgumentError, 'Called none_of() with no arguments.' if queries.none?

      AlternativeBuilder.new(:negative, @scope, *queries).build
    end
  end
end

ActiveRecord::Relation::WhereChain.include ActiverecordAnyOf::Chained
