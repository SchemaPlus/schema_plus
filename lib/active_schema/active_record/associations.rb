require 'ostruct'

module ActiveSchema
  module ActiveRecord
    module Associations

      protected

      def load_active_schema_associations

        reverse_foreign_keys.each do | foreign_key |
          if foreign_key.table_name =~ /^#{table_name}_(.*)$/ || foreign_key.table_name =~ /^(.*)_#{table_name}$/
            other_table = $1
            if other_table == other_table.pluralize and connection.columns(foreign_key.table_name).any?{|col| col.name == "#{other_table.singularize}_id"}
              _define_association(:has_and_belongs_to_many, foreign_key, other_table)
            else
              _define_association(:has_one_or_many, foreign_key)
            end
          else
            _define_association(:has_one_or_many, foreign_key)
          end
        end

        foreign_keys.each do | foreign_key |
          _define_association(:belongs_to, foreign_key)
        end
      end

      private

      def _define_association(macro, fk, referencing_table_name = nil)
        return unless fk.column_names.size == 1

        referencing_table_name ||= fk.table_name

        column_name = fk.column_names.first
        association_name = column_name.sub(/_id$/, '')
        references_name = fk.references_table_name.singularize
        referencing_name = referencing_table_name.singularize

        references_class_name = references_name.classify
        referencing_class_name = referencing_name.classify

        references_concise = _concise_name(references_name, referencing_name)
        referencing_concise = _concise_name(referencing_name, references_name)

        case association_name
        when references_name
          belongs_to         = references_name
          belongs_to_concise = references_concise

          has_one            = referencing_name
          has_one_concise    = referencing_concise

          has_many           = referencing_name.pluralize
          has_many_concise   = referencing_concise.pluralize

        when /(.*)_#{references_name}$/, /(.*)_#{references_concise}$/
          label = $1
          belongs_to         = "#{label}_#{references_name}"
          belongs_to_concise = "#{label}_#{references_concise}"

          has_one            = "#{referencing_name}_as_#{label}"
          has_one_concise    = "#{referencing_concise}_as_#{label}"

          has_many           = "#{referencing_name.pluralize}_as_#{label}"
          has_many_concise   = "#{referencing_concise.pluralize}_as_#{label}"

        when /^#{references_name}_(.*)$/, /^#{references_concise}_(.*)$/
          label = $1
          belongs_to            = "#{references_name}_#{label}"
          belongs_to_concise    = "#{references_concise}_#{label}"

          has_one               = "#{referencing_name}_as_#{label}"
          has_one_concise       = "#{referencing_concise}_as_#{label}"

          has_many              = "#{referencing_name.pluralize}_as_#{label}"
          has_many_concise      = "#{referencing_concise.pluralize}_as_#{label}"

        else
          belongs_to            = association_name
          belongs_to_concise    = association_name

          has_one               = "#{referencing_name}_as_#{association_name}"
          has_one_concise       = "#{referencing_concise}_as_#{association_name}"

          has_many              = "#{referencing_name.pluralize}_as_#{association_name}"
          has_many_concise      = "#{referencing_concise.pluralize}_as_#{association_name}"
        end

        case macro
        when :has_and_belongs_to_many
          name = has_many
          name_concise = has_many_concise
          opts = {:class_name => referencing_class_name, :join_table => fk.table_name}
        when :belongs_to
          name = belongs_to
          name_concise = belongs_to_concise
          opts = {:class_name => references_class_name, :foreign_key => column_name}
        when :has_one_or_many
          opts = {:class_name => referencing_class_name, :foreign_key => column_name}
          # use connection.indexes and connection.colums rather than class
          # methods of the referencing class because using the class
          # methods would require getting the class -- which might trigger
          # an autoload which could start some recursion making things much
          # harder to debug.
          if connection.indexes(referencing_table_name, "#{referencing_table_name} Indexes").any?{|index| index.unique && index.columns == [column_name]}
            macro = :has_one
            name = has_one
            name_concise = has_one_concise
          else
            macro = :has_many
            name = has_many
            name_concise = has_many_concise
            if connection.columns(referencing_table_name, "#{referencing_table_name} Columns").any?{ |col| col.name == 'position' }
              opts[:order] = :position
            end
          end
        end
        names = []
        names << name if _use_full_name?
        names << name_concise if _use_concise_name?
        names.uniq.collect(&:to_sym).each do |name|
          if (!method_defined?(name) && !private_method_defined?(name)) or (name == :type && [Object, Kernel].include?(instance_method(:type).owner))
            send macro, name, opts
          end
        end
      end

      def _concise_name(string, other)
        case
        when string =~ /^#{other}_(.*)$/           then $1
        when string =~ /(.*)_#{other}$/            then $1
        when leader = _common_leader(string,other) then string[leader.length, string.length-leader.length]
        else                                            string
        end
      end

      def _common_leader(string, other)
        leader = nil
        other.split('_').each do |part|
          test = "#{leader}#{part}_"
          break unless string.start_with? test
          leader = test
        end
        return leader
      end

      def _use_concise_name?
        active_schema_config.associations.concise_names?
      end

      def _use_full_name?
        active_schema_config.associations.full_names_always? or not _use_concise_name?
      end
    end
  end
end
