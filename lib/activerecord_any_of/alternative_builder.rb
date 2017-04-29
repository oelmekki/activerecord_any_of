module ActiverecordAnyOf
  class AlternativeBuilder
    def initialize(match_type, context, *queries)
      if Hash === queries.first and queries.count == 1
        queries = queries.first.each_pair.map { |attr, predicate| Hash[attr, predicate] }
      end

      @builder = match_type == :negative ? NegativeBuilder.new(context, *queries) : PositiveBuilder.new(context, *queries)
    end

    def build
      @builder.build
    end

    class Builder
      attr_accessor :queries_bind_values, :queries_joins_values

      def initialize(context, *source_queries)
        @context, @source_queries = context, source_queries
        @queries_bind_values, @queries_joins_values = [], { includes: [],  joins: [], references: [] }
      end

      def build
        ActiveRecord::Base.connection.supports_statement_cache? ? with_statement_cache : without_statement_cache
      end

      private

        def queries
          @queries ||= @source_queries.map do |query|
            if String === query || Hash === query
              query = where(query)
            elsif Array === query
              query = where(*query)
            end

            if ( bound = bind_values_for( query ) ).any?
              self.queries_bind_values += bound
            end

            queries_joins_values[:includes].concat(query.includes_values) if query.includes_values.any?
            queries_joins_values[:joins].concat(query.joins_values) if query.joins_values.any?
            queries_joins_values[:references].concat(query.references_values) if ActiveRecord::VERSION::MAJOR >= 4 && query.references_values.any?
            query.arel.constraints.reduce(:and)
          end
        end

        def bind_values_for( query )
          if ActiveRecord::VERSION::MAJOR >= 5
            query.bound_attributes.map { |attr| [ attr.name, attr.value ] }
          else
            query.bind_values
          end
        end

        def uniq_queries_joins_values
          @uniq_queries_joins_values ||= begin
            { includes: [], joins: [], references: [] }.tap do |values|
              queries_joins_values.each do |join_type, statements|
                if statements.first.respond_to?(:to_sql)
                  values[ join_type ] = statements.uniq( &:to_sql )
                else
                  values[ join_type ] = statements.uniq
                end
              end
            end
          end
        end

        def method_missing(method_name, *args, &block)
          @context.send(method_name, *args, &block)
        end

        def add_joins_to(relation)
          relation = relation.references(uniq_queries_joins_values[:references]) if ActiveRecord::VERSION::MAJOR >= 4
          relation = relation.includes(uniq_queries_joins_values[:includes])
          relation.joins(uniq_queries_joins_values[:joins])
        end

        def add_related_values_to(relation)
          relation.bind_values += queries_bind_values
          relation.includes_values += uniq_queries_joins_values[:includes]
          relation.joins_values += uniq_queries_joins_values[:joins]
          relation.references_values += uniq_queries_joins_values[:references] if ActiveRecord::VERSION::MAJOR >= 4

          relation
        end

        def unprepare_query(query)
          query.gsub(/((?<!\\)'.*?(?<!\\)'|(?<!\\)".*?(?<!\\)")|(\=\ \$\d+)/) do |match|
            $2 and $2.gsub(/\=\ \$\d+/, "= ?") or match
          end
        end
    end

    class PositiveBuilder < Builder
      private

        def with_statement_cache
          if queries && queries_bind_values.any?
            relation = where([unprepare_query(queries.reduce(:or).to_sql), *queries_bind_values.map { |v| v[1] }])
          else
            relation = where(queries.reduce(:or).to_sql)
          end

          add_joins_to relation
        end

        def without_statement_cache
          relation = where(queries.reduce(:or))
          add_related_values_to relation
        end
    end

    class NegativeBuilder < Builder
      private

        def with_statement_cache
          if ActiveRecord::VERSION::MAJOR >= 4
            if queries && queries_bind_values.any?
              relation = where.not([unprepare_query(queries.reduce(:or).to_sql), *queries_bind_values.map { |v| v[1] }])
            else
              relation = where.not(queries.reduce(:or).to_sql)
            end
          else
            if queries && queries_bind_values.any?
              relation = where([unprepare_query(Arel::Nodes::Not.new(queries.reduce(:or)).to_sql), *queries_bind_values.map { |v| v[1] }])
            else
              relation = where(Arel::Nodes::Not.new(queries.reduce(:or)).to_sql)
            end
          end

          add_joins_to relation
        end

        def without_statement_cache
          if ActiveRecord::VERSION::MAJOR >= 4
            relation = where.not(queries.reduce(:or))
          else
            relation = where(Arel::Nodes::Not.new(queries.reduce(:or)))
          end

          add_related_values_to relation
        end
    end
  end
end
