module SchemaMonkey
  module ActiveRecord

    module Base
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def self.extended(base)
          class << base
            alias_method_chain :columns, :schema_monkey
            alias_method_chain :reset_column_information, :schema_monkey
          end
        end

        def columns_with_schema_monkey
          Middleware::Model::Columns.start model: self, columns: [] do |env|
            env.columns += columns_without_schema_monkey 
          end
        end

        def reset_column_information_with_schema_monkey
          Middleware::Model::ResetColumnInformation.start model: self do |env|
            reset_column_information_without_schema_monkey 
          end
        end
      end
    end
  end
end
