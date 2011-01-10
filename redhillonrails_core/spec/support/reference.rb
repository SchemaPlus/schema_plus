module RedhillonrailsCoreMatchers

  class Reference
    def initialize(expected)
      @column_names = nil
      unless expected.empty?
        @references_column_names = Array(expected).collect(&:to_s)
        @references_table_name = @references_column_names.shift 
      end
    end

    def matches?(model)
      @model = model
      if @references_table_name
        @result = @model.foreign_keys.select do |fk|
          fk.references_table_name == @references_table_name && 
            @references_column_names.empty? ? true : fk.references_column_names == @references_column_names
        end
      else
        @result = @model.foreign_keys
      end
      if @column_names 
        @result.any? do |fk| 
          fk.column_names == @column_names &&
            (@on_update ? fk.on_update == @on_update : true) &&
            (@on_delete ? fk.on_delete == @on_delete : true)
        end
      else
        !@result.empty?
      end
    end

    def failure_message_for_should(should_not = false)
      target_column_names = @column_names.present? ? "(#{@column_names.join(', ')})" : "" 
      destinantion_column_names = @references_table_name ? "#{@references_table_name}(#{@references_column_names.join(', ')})" : "anything"
      invert = should_not ? 'not' : ''
      "Expected #{@model.table_name}#{target_column_names} to #{invert} reference #{destinantion_column_names}"
    end

    def failure_message_for_should_not
      failure_message_for_should(true)
    end
  
    def on(*column_names)
      @column_names = column_names.collect(&:to_s)
      self
    end

    def on_update(action)
      @on_update = action
      self
    end

    def on_delete(action)
      @on_delete = action
      self
    end

  end

  def reference(*expect)
    Reference.new(expect)
  end

end

