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
    queries_bind_values, queries_joins_values = [], { includes: [],  joins: [], references: [] }

    queries = queries.map do |query|
      query = where(query) if [String, Hash].any? { |type| query.kind_of?(type) }
      query = where(*query) if query.kind_of?(Array)
      queries_bind_values += query.bind_values if query.bind_values.any?
      queries_joins_values[:includes] += query.includes_values if query.includes_values.any?
      queries_joins_values[:joins] += query.joins_values if query.joins_values.any?
      queries_joins_values[:references] += query.references_values if Rails.version >= '4' and query.references_values.any?
      query.arel.constraints.reduce(:and)
    end


    queries_joins_values.each { |tables| tables.uniq! }

    if ActiveRecord::Base.connection.supports_statement_cache?
      relation = where([queries.reduce(:or).to_sql, *queries_bind_values.map { |v| v[1] }])
      relation = relation.includes(queries_joins_values[:includes])
      relation = relation.joins(queries_joins_values[:joins])
      relation = relation.references(queries_joins_values[:references]) if Rails.version >= '4'
    else
      relation = where(queries.reduce(:or))
      relation.bind_values += queries_bind_values
      relation.includes_values += queries_joins_values[:includes]
      relation.joins_values += queries_joins_values[:joins]
      relation.references_values += queries_joins_values[:references] if Rails.version >= '4'
    end

    relation
  end
end

if Rails.version >= '4'
  module ActiverecordAnyOfDelegation
    delegate :any_of, to: :all
  end
else
  module ActiverecordAnyOfDelegation
    delegate :any_of, to: :scoped
  end
end

ActiveRecord::Relation.send(:include, ActiverecordAnyOf)
ActiveRecord::Base.send(:extend, ActiverecordAnyOfDelegation)
