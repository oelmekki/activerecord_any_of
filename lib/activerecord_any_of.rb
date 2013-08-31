require 'activerecord_any_of/alternative_builder'

module ActiverecordAnyOf
  module Chained
    # Returns a new relation, which includes results matching any of the conditions
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
    #    inactive_users = User.any_of(banned_users, unconfirmed_users)
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
    #    active_users = User.none_of(banned_users, unconfirmed_users)
    def none_of(*queries)
      raise ArgumentError, 'Called none_of() with no arguments.' if queries.none?
      AlternativeBuilder.new(:negative, @scope, *queries).build
    end
  end

  module Deprecated
    def any_of(*queries)
      if Rails.version >= '4'
        ActiveSupport::Deprecation.warn( "Calling #any_of directly is deprecated and will be removed in activerecord_any_of-1.2.\nPlease call it with #where : User.where.any_of(cond1, cond2)." )
      end

      raise ArgumentError, 'Called any_of() with no arguments.' if queries.none?
      AlternativeBuilder.new(:positive, self, *queries).build
    end

    def none_of(*queries)
      if Rails.version >= '4'
        ActiveSupport::Deprecation.warn( "Calling #none_of directly is deprecated and will be removed in activerecord_any_of-1.2.\nPlease call it with #where : User.where.none_of(cond1, cond2)." )
      end

      raise ArgumentError, 'Called none_of() with no arguments.' if queries.none?
      AlternativeBuilder.new(:negative, self, *queries).build
    end
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

ActiveRecord::Relation.send(:include, ActiverecordAnyOf::Deprecated)
ActiveRecord::Relation::WhereChain.send(:include, ActiverecordAnyOf::Chained) if Rails.version >= '4'
ActiveRecord::Base.send(:extend, ActiverecordAnyOfDelegation)
