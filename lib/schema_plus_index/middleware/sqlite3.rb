module SchemaPlusIndex
  module Middleware
    module Sqlite3
      def self.insert
        SchemaMonkey::Middleware::Query::Indexes.append LookupExtensions
      end

      class LookupExtensions < SchemaMonkey::Middleware::Base
        def call(env)
          continue env
          indexes = Hash[env.index_definitions.map{ |d| [d.name, d] }]

          env.connection.exec_query("SELECT name, sql FROM sqlite_master WHERE type = 'index'").map do |row|
            if (desc_columns = row['sql'].scan(/['"`]?(\w+)['"`]? DESC\b/).flatten).any?
              index = indexes[row['name']]
              index.orders = Hash[index.columns.map {|column| [column, desc_columns.include?(column) ? :desc : :asc]}]
            end
          end

          env.index_definitions
        end
      end
    end
  end
end
