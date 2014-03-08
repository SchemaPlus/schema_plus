module SchemaPlus::ActiveRecord::ConnectionAdapters
  module SchemaStatements

    def self.included(base) #:nodoc:
      base.class_eval do
        alias_method_chain :create_table, :schema_plus
        alias_method_chain :add_reference, :schema_plus unless ::ActiveRecord::VERSION::MAJOR.to_i < 4
        include AddIndex
      end
    end

    def add_reference_with_schema_plus(table_name, ref_name, options = {}) #:nodoc:
      options[:references] = nil if options[:polymorphic]
      add_reference_without_schema_plus(table_name, ref_name, options)
    end

    ##
    # :method: create_table
    #
    # SchemaPlus extends SchemaStatements::create_table to allow you to specify configuration options per table.  Pass them in as a hash keyed by configuration set (see SchemaPlus::Config),
    # for example:
    #
    #     create_table :widgets, :foreign_keys => {:auto_create => true, :on_delete => :cascade} do |t|
    #        ...
    #     end
    def create_table_with_schema_plus(table, options = {})
      options = options.dup
      config_options = {}
      options.keys.each { |key| config_options[key] = options.delete(key) if SchemaPlus.config.class.attributes.include? key }

      # override rails' :force to cascade
      drop_table(table, if_exists: true, cascade: true) if options.delete(:force)

      if ::ActiveRecord::VERSION::MAJOR.to_i < 4
        indexes = []
      end
      create_table_without_schema_plus(table, options) do |table_definition|
        table_definition.schema_plus_config = SchemaPlus.config.merge(config_options)
        if ::ActiveRecord::VERSION::MAJOR.to_i < 4
          table_definition.name = table
        end
        yield table_definition if block_given?
        if ::ActiveRecord::VERSION::MAJOR.to_i < 4
          indexes = table_definition.indexes
        end
      end
      if ::ActiveRecord::VERSION::MAJOR.to_i < 4
        indexes.each do |index|
          add_index(table, index.columns, index.opts)
        end
      end
    end

    def self.add_index_exception_handler(connection, table, columns, options, e) #:nodoc:
      raise unless e.message.match(/["']([^"']+)["'].*already exists/)
      name = $1
      existing = connection.indexes(table).find{|i| i.name == name}
      attempted = ::ActiveRecord::ConnectionAdapters::IndexDefinition.new(table, columns, options.merge(:name => name)) 
      raise if attempted != existing
      ::ActiveRecord::Base.logger.warn "[schema_plus] Index name #{name.inspect}' on table #{table.inspect} already exists. Skipping."
    end

    module AddIndex
      def self.included(base) #:nodoc:
        base.class_eval do
          alias_method_chain :add_index, :schema_plus
        end
      end

      ##
      # :method: add_index
      #
      # SchemaPlus modifies SchemaStatements::add_index so that it ignores
      # errors raised about add an index that already exists -- i.e. that has
      # the same index name, same columns, and same options -- and writes a
      # warning to the log. Some combinations of rails & DB adapter versions
      # would log such a warning, others would raise an error; with
      # SchemaPlus all versions log the warning and do not raise the error.
      #
      # (This avoids collisions between SchemaPlus's auto index behavior and
      # legacy explicit add_index statements, for platforms that would raise
      # an error.)
      #
      def add_index_with_schema_plus(table, columns, options={})
        options.delete(:if_exists) if options # some callers explcitly pass options=nil
        add_index_without_schema_plus(table, columns, options)
      rescue => e
        SchemaStatements.add_index_exception_handler(self, table, columns, options, e)
      end
    end
  end
end
