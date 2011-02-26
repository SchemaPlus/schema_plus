module ActiveSchemaHelpers
  extend self

  def mysql?
    ActiveRecord::Base.connection.adapter_name =~ /^mysql/i
  end

  def postgresql?
    ActiveRecord::Base.connection.adapter_name =~ /^postgresql/i
  end

  def sqlite3?
    ActiveRecord::Base.connection.adapter_name =~ /^sqlite/i
  end

  def new_model(parent = ::ActiveRecord::Base, &block)
    @autocreated_models ||= []
    model = Class.new(parent, &block)
    @autocreated_models << model
    model
  end

  def auto_remove
    # assign to local var otherwise ruby will
    # get @autocreated_models in Object scope
    autocreated_models = @autocreated_models
    Object.class_eval do
      autocreated_models.try(:each) do |model|
        remove_const model.name.to_sym
      end
    end
    @autocreated_models = []
  end


end
