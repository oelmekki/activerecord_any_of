# frozen_string_literal: true

module ActiverecordAnyOf
  IS_RAILS_6 = ActiveRecord.version.to_s.between?('6', '7')

  # Main class allowing to build alternative conditions for the query.
  class AlternativeBuilder
    def initialize(match_type, context, *queries)
      if queries.first.is_a?(Hash) && (queries.count == 1)
        queries = queries.first.each_pair.map { |attr, predicate| { attr => predicate } }
      end

      @builder = if match_type == :negative
                   NegativeBuilder.new(context,
                                       *queries)
                 else
                   PositiveBuilder.new(context, *queries)
                 end
    end

    def build
      @builder.build
    end

    # Common methods for both the positive builder and the negative one.
    class Builder
      attr_accessor :queries_joins_values

      def initialize(context, *source_queries)
        @context = context
        @source_queries = source_queries
        @queries_joins_values = { includes: [], joins: [], references: [] }
      end

      private

      def query_to_relation(query)
        if query.is_a?(String) || query.is_a?(Hash)
          query = where(query)
        elsif query.is_a?(Array)
          query = where(*query)
        end

        query
      end

      def append_join_values(query)
        { includes_values: :includes, joins_values: :joins, references_values: :references }.each do |q, joins|
          values = query.send(q)
          queries_joins_values[joins].concat(values) if values.any?
        end
      end

      def queries
        @queries ||= @source_queries.map do |query|
          query = query_to_relation(query)
          append_join_values(query)
          query.arel.constraints.reduce(:and)
        end
      end

      def uniq_queries_joins_values
        @uniq_queries_joins_values ||= { includes: [], joins: [], references: [] }.tap do |values|
          queries_joins_values.each do |join_type, statements|
            values[join_type] = if statements.first.respond_to?(:to_sql)
                                  statements.uniq(&:to_sql)
                                else
                                  statements.uniq
                                end
          end
        end
      end

      def map_multiple_bind_values(query)
        query.children.map do |child|
          next unless child.respond_to?(:right)
          next unless child.right.respond_to?(:value)

          child.right.value
        end
      end

      def queries_bind_values
        queries.map do |query|
          if query.respond_to?(:children)
            map_multiple_bind_values(query)
          else
            next unless query.respond_to?(:right)
            next unless query.right.respond_to?(:value)

            query.right.value
          end
        end.flatten.compact
      end

      def method_missing(method_name, *args, &block)
        @context.send(method_name, *args, &block)
      end

      def respond_to_missing?(method, *)
        @context.respond_to? method
      end

      def add_joins_to(relation)
        relation = relation.references(uniq_queries_joins_values[:references])
        relation = relation.includes(uniq_queries_joins_values[:includes])
        relation.joins(uniq_queries_joins_values[:joins])
      end

      def unprepare_query(query)
        query.gsub(/((?<!\\)'.*?(?<!\\)'|(?<!\\)".*?(?<!\\)")|(=\ \$\d+)/) do |match|
          ::Regexp.last_match(2)&.gsub(/=\ \$\d+/, '= ?') or match
        end
      end

      def bind_values
        queries_bind_values.tap do |values|
          values.map!(&:value) if IS_RAILS_6
        end
      end
    end

    # Returns records that match any of the conditions, ie `#any_of`.
    class PositiveBuilder < Builder
      def build
        relation = if queries && queries_bind_values.any?
                     where([unprepare_query(queries.reduce(:or).to_sql), *bind_values])
                   else
                     where(queries.reduce(:or).to_sql)
                   end

        add_joins_to relation
      end
    end

    # Returns records that match none of the conditions, ie `#none_of`.
    class NegativeBuilder < Builder
      def build
        relation = if queries && queries_bind_values.any?
                     where.not([unprepare_query(queries.reduce(:or).to_sql), *bind_values])
                   else
                     where.not(queries.reduce(:or).to_sql)
                   end

        add_joins_to relation
      end
    end
  end
end
