module SchemaPlusDbDefault
  module ActiveRecord
    module Attribute

      def original_value
        # prevent attempts to cast DB_DEFAULT to the attributes type.
        # We want to keep it as DB_DEFAULT so that we can handle it when
        # generating the sql.
        return DB_DEFAULT if value_before_type_cast.equal? DB_DEFAULT
        super
      end

    end
  end
end

